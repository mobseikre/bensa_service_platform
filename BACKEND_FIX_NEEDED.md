# Backend Fix Required for Service Categories

## Problem
The registration API is receiving `service_categories` as an array but the database column expects a string, causing "Array to string conversion" error.

**Current Situation:**
- Frontend sends: `service_categories` as an **array** (e.g., `["plumbing", "satellite"]`)
- Backend validation: Requires **array** format
- Database column: Expects **string** format (VARCHAR/TEXT)
- **Result:** Backend tries to insert array directly → "Array to string conversion" error

## Current Frontend Behavior
The Flutter app is sending `service_categories` as an **array** (e.g., `["plumbing", "satellite"]`) because backend validation requires it.

## Backend Fix Options

### Option 1: Convert Array to JSON String (REQUIRED FIX)
**This is the fix you need right now!** The backend validation accepts an array, but you must convert it to a JSON string before saving to the database.

**Laravel Controller Example:**
```php
// In your RegistrationController or AuthController
public function register(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string',
        'email' => 'required|email|unique:users',
        'phone' => 'required|string',
        'password' => 'required|confirmed',
        'role' => 'required|in:customer,technician',
        'city' => 'required_if:role,technician',
        'nationality' => 'required_if:role,technician',
        'service_categories' => 'nullable|array', // Accept as array
        'service_categories.*' => 'string', // Each item must be string
    ]);

    // Convert array to JSON string for database storage
    $serviceCategoriesJson = null;
    if (isset($validated['service_categories']) && is_array($validated['service_categories'])) {
        $serviceCategoriesJson = json_encode($validated['service_categories']);
    }

    // Create user
    $user = User::create([
        'name' => $validated['name'],
        'email' => $validated['email'],
        'phone' => $validated['phone'],
        'password' => Hash::make($validated['password']),
        'role' => $validated['role'],
        'active_role' => $validated['role'],
        'city' => $validated['city'] ?? null,
        'nationality' => $validated['nationality'] ?? null,
        'service_categories' => $serviceCategoriesJson, // ✅ Store as JSON string
        'is_approved' => $validated['role'] === 'technician' ? 0 : 1,
    ]);

    return response()->json([
        'message' => 'Registration successful',
        'user' => $user,
    ]);
}
```

**Or use a mutator in the User model:**
```php
// In User.php model
public function setServiceCategoriesAttribute($value)
{
    // If it's an array, convert to JSON string
    if (is_array($value)) {
        $this->attributes['service_categories'] = json_encode($value);
    } else {
        $this->attributes['service_categories'] = $value;
    }
}
```

### Option 2: Use JSON Column Type (Better for querying)
If you want to query service categories easily, use a JSON column type.

**Migration:**
```php
Schema::table('users', function (Blueprint $table) {
    $table->json('service_categories')->nullable()->change();
});
```

**Laravel Model:**
```php
// In User model
protected $casts = [
    'service_categories' => 'array', // Auto-convert JSON to array
];
```

**Controller:**
```php
$validated = $request->validate([
    'service_categories' => 'nullable|array', // Accept as array
    'service_categories.*' => 'string',
]);

$user = User::create([
    // ... other fields
    'service_categories' => $validated['service_categories'], // Laravel will auto-encode to JSON
]);
```

### Option 3: Accept Both Formats (Most Flexible)
Handle both array and comma-separated string:

```php
$serviceCategories = $request->input('service_categories');

// If it's an array, convert to comma-separated string
if (is_array($serviceCategories)) {
    $serviceCategories = implode(',', $serviceCategories);
}

// Or if you want JSON:
if (is_array($serviceCategories)) {
    $serviceCategories = json_encode($serviceCategories);
}

$user = User::create([
    // ... other fields
    'service_categories' => $serviceCategories,
]);
```

## Current Frontend Format
The Flutter app sends:
```json
{
  "service_categories": ["plumbing", "satellite"]
}
```

## REQUIRED BACKEND FIX
**You MUST implement Option 1** - Convert the array to JSON string before database insert.

The backend code should look like this:
```php
// Convert array to JSON string
$serviceCategoriesJson = json_encode($validated['service_categories']);

// Then save to database
'service_categories' => $serviceCategoriesJson
```

**Without this fix, the registration will always fail with "Array to string conversion" error.**

## Testing
After fixing the backend:
1. Try registering a new technician
2. Check the database - `service_categories` should be stored correctly
3. Check the `role` field - should be `technician`, not `customer`
