# إصلاح Health Check Endpoint

## إضافة Health Check في Laravel Backend

### 1. إنشاء Route:
```php
// في routes/api.php
Route::get('/health-check', function () {
    return response()->json([
        'success' => true,
        'message' => 'API is working properly',
        'timestamp' => now(),
        'status' => 'healthy',
        'database' => 'connected', // يمكن إضافة فحص قاعدة البيانات
        'version' => '1.0.0',
    ]);
});
```

### 2. أو إنشاء Controller منفصل:
```bash
php artisan make:controller Api/HealthController
```

```php
// في App/Http/Controllers/Api/HealthController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function check()
    {
        $status = [
            'success' => true,
            'message' => 'API is working properly',
            'timestamp' => now(),
            'status' => 'healthy',
        ];

        // فحص قاعدة البيانات
        try {
            DB::connection()->getPdo();
            $status['database'] = 'connected';
        } catch (\Exception $e) {
            $status['database'] = 'disconnected';
            $status['status'] = 'unhealthy';
        }

        return response()->json($status);
    }
}
```

### 3. إضافة Route للـ Controller:
```php
// في routes/api.php
use App\Http\Controllers\Api\HealthController;

Route::get('/health-check', [HealthController::class, 'check']);
```
