# Backend Fix Instructions

## Problem
The `service_categories` array is being passed directly to the database, causing "Array to string conversion" error. The model cast should handle this, but it's not working, so we need to manually convert it.

## File to Edit
`app/Http/Controllers/AuthController.php`

## Change Required

### Find this code (around line 42-55):

```php
$data = $request->validate($rules);

// Create user
$user = User::create([
    'phone'             => $data['phone'],
    'name'              => $data['name'],
    'email'             => $data['email'],
    'password'          => Hash::make($data['password']),
    'city'              => $data['city'] ?? null,
    'nationality'       => $data['nationality'] ?? null,
    'role'              => $role,
    'service_categories' => $data['service_categories'] ?? null,
    'is_approved'       => $role === 'customer' ? true : false,
]);
```

### Replace with this:

```php
$data = $request->validate($rules);

// Convert service_categories array to JSON string for database storage
// The model cast should handle this, but we do it explicitly to ensure it works
$serviceCategoriesJson = null;
if (isset($data['service_categories']) && is_array($data['service_categories'])) {
    $serviceCategoriesJson = json_encode($data['service_categories']);
}

// Create user
$user = User::create([
    'phone'             => $data['phone'],
    'name'              => $data['name'],
    'email'             => $data['email'],
    'password'          => Hash::make($data['password']),
    'city'              => $data['city'] ?? null,
    'nationality'       => $data['nationality'] ?? null,
    'role'              => $role,
    'service_categories' => $serviceCategoriesJson, // Store as JSON string
    'is_approved'       => $role === 'customer' ? true : false,
]);
```

## What This Does

1. **Validates** the array (as before)
2. **Converts** the array to JSON string using `json_encode()`
3. **Saves** the JSON string to the database

This ensures the array is properly converted to a JSON string before being saved, regardless of whether the model cast is working or the database column type.

## Testing

After making this change:
1. Try registering a new technician
2. The "Array to string conversion" error should be gone
3. The `service_categories` should be saved as JSON in the database
4. The `role` should be saved as `technician` (not `customer`)
