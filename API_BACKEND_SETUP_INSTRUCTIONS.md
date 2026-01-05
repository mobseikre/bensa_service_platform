# إرشادات إعداد Backend API - بنسا

## 1. التحقق من إعداد الخادم

### URLs المستخدمة حالياً:
- **Manual Override**: `http://192.168.2.161:8000/api` (مُفعل حالياً)
- **Alternative**: `http://172.20.10.2:8000/api`
- **Local Development**: `http://localhost:8000/api`

### تشغيل الخادم:
```bash
cd ~/Bensa
php artisan serve --host=0.0.0.0 --port=8000
```

## 2. Endpoints المطلوبة في Backend

### Authentication Endpoints:
- `POST /api/auth/register` - تسجيل مستخدم جديد
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/logout` - تسجيل الخروج
- `GET /api/auth/me` - بيانات المستخدم الحالي
- `POST /api/auth/refresh` - تحديث الـ token

### Notifications Endpoints:
- `GET /api/notifications` - جلب الإشعارات (مع pagination)
- `POST /api/notifications/mark-read/{id}` - تحديد إشعار كمقروء
- `POST /api/notifications/read-all` - تحديد جميع الإشعارات كمقروءة

### Service Categories Endpoints:
- `GET /api/service-categories` - جلب أصناف الخدمات

### Requests/Jobs Endpoints:
- `GET /api/requests` - جلب طلبات العميل
- `POST /api/requests` - إنشاء طلب جديد
- `GET /api/requests/{id}` - تفاصيل طلب محدد
- `POST /api/requests/{id}/cancel` - إلغاء طلب

### Technician Endpoints:
- `GET /api/technician/stats` - إحصائيات الفني
- `GET /api/technician/assigned-orders` - الطلبات المعينة للفني
- `GET /api/technician/current-job` - الطلب النشط الحالي

### User Profile Endpoints:
- `GET /api/user/profile` - بيانات الملف الشخصي
- `PUT /api/user/profile` - تحديث الملف الشخصي
- `GET /api/addresses` - جلب العناوين المحفوظة
- `POST /api/addresses` - إضافة عنوان جديد
- `PUT /api/addresses/{id}` - تحديث عنوان
- `DELETE /api/addresses/{id}` - حذف عنوان

### Health Check Endpoint:
- `GET /api/health-check` - فحص حالة الخادم

## 3. التحقق من إعداد Headers

### Headers المطلوبة:
```php
// في backend - إضافة CORS headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');
```

### Laravel CORS Configuration:
```php
// config/cors.php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'], // في التطوير فقط
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

## 4. هيكل الاستجابات المتوقعة

### Successful Response:
```json
{
    "success": true,
    "data": [...],
    "message": "تم بنجاح",
    "meta": {
        "current_page": 1,
        "total": 10
    }
}
```

### Error Response:
```json
{
    "success": false,
    "message": "خطأ في الطلب",
    "errors": {
        "field": ["رسالة الخطأ"]
    }
}
```

## 5. Authentication Token

### Laravel Sanctum Setup:
```php
// في User model
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    // ...
}
```

### Token Generation:
```php
// في AuthController
$token = $user->createToken('auth_token')->plainTextToken;

return response()->json([
    'success' => true,
    'token' => $token,
    'user' => $user,
]);
```

## 6. Database Tables المطلوبة

### Users Table:
```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->string('phone');
    $table->string('password');
    $table->enum('role', ['customer', 'technician'])->default('customer');
    $table->string('city')->nullable();
    $table->string('nationality')->nullable();
    $table->json('service_categories')->nullable();
    $table->timestamps();
});
```

### Service Categories Table:
```php
Schema::create('service_categories', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('name_ar');
    $table->string('description')->nullable();
    $table->decimal('base_price', 8, 2);
    $table->boolean('is_popular')->default(false);
    $table->timestamps();
});
```

### Notifications Table:
```php
Schema::create('notifications', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('user_id');
    $table->string('title');
    $table->text('message');
    $table->timestamp('read_at')->nullable();
    $table->timestamps();

    $table->foreign('user_id')->references('id')->on('users');
});
```

## 7. اختبار الاتصال من Flutter

### في app:
1. افتح صفحة الإشعارات
2. اضغط على أيقونة "اختبار الاتصال" (🌐)
3. سيظهر تقرير مفصل عن حالة كل endpoint

### من Terminal:
```bash
# اختبار health check
curl -X GET "http://192.168.2.161:8000/api/health-check"

# اختبار service categories
curl -X GET "http://192.168.2.161:8000/api/service-categories"

# اختبار notifications (يحتاج token)
curl -X GET "http://192.168.2.161:8000/api/notifications" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 8. مشكلة الإشعارات الحالية

المشكلة الأساسية أن صفحة الإشعارات تُظهر "لا توجد إشعارات حالياً" مما يعني:

1. **إما** الـ endpoint `/api/notifications` غير موجود في backend
2. **أو** لا توجد بيانات إشعارات في قاعدة البيانات
3. **أو** هناك مشكلة في authentication

### الحل:
```php
// إنشاء NotificationController
php artisan make:controller Api/NotificationController

// في NotificationController:
public function index(Request $request)
{
    $notifications = auth()->user()->notifications()
                    ->orderBy('created_at', 'desc')
                    ->paginate(20);

    return response()->json([
        'success' => true,
        'data' => $notifications->items(),
        'meta' => [
            'current_page' => $notifications->currentPage(),
            'total' => $notifications->total(),
        ]
    ]);
}
```

## 9. إضافة بيانات تجريبية

```php
// في DatabaseSeeder أو tinker:
Notification::create([
    'user_id' => 1,
    'title' => 'مرحباً بك في بنسا',
    'message' => 'تم تسجيل حسابك بنجاح. يمكنك الآن طلب الخدمات.',
    'created_at' => now(),
]);

Notification::create([
    'user_id' => 1,
    'title' => 'طلب جديد',
    'message' => 'لديك طلب خدمة جديد في انتظار الموافقة.',
    'created_at' => now()->subMinutes(30),
]);
```

---

## 🔧 خطوات الإصلاح السريع:

1. **تشغيل الخادم**: `php artisan serve --host=0.0.0.0 --port=8000`
2. **إنشاء NotificationController** مع الـ endpoints المطلوبة
3. **إضافة بيانات إشعارات تجريبية**
4. **اختبار من التطبيق** باستخدام أيقونة "اختبار الاتصال"

بهذه الطريقة ستعمل صفحة الإشعارات بشكل طبيعي وستظهر البيانات المطلوبة.
