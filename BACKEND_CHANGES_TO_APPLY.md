# 🔄 التعديلات المهمة التي يجب تطبيقها في مشروع Backend المنفصل

> **⚠️ مهم جداً:** هذه التعديلات تمت في مجلد `backend_api` داخل مشروع Flutter. يجب تطبيقها في مشروع Backend المنفصل.

---

## 📋 ملخص التعديلات

### 1. ✅ تعديل خدمة التوزيع التلقائي (TechnicianAssignmentService)

**الملف:** `app/Services/TechnicianAssignmentService.php`

**التغيير:** تعديل منطق التوزيع لضمان أن كل فني يأخذ **طلبية واحدة فقط** في كل مرة.

**الكود الكامل:**

```php
<?php

namespace App\Services;

use App\Models\Request as JobRequest;
use App\Models\User;
use App\Models\AppSetting;
use Illuminate\Support\Facades\Log;

class TechnicianAssignmentService
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Auto-assign a technician to a service request based on:
     * 1. Service category match (technician must have the service in their service_categories)
     * 2. Availability (is_available = true, is_active = true, is_approved = true)
     * 3. NO active orders - technician must have ZERO active orders (one order at a time)
     * 4. EXCLUDE technicians with ANY pending custody (must settle before working)
     *
     * NO location/distance logic - just find ANY available technician with matching service.
     */
    public function autoAssignTechnician($request)
    {
        // Find available technicians who match the service category
        // EXCLUDE technicians with ANY pending custody (must settle before working)
        // EXCLUDE technicians with ANY active orders (one order at a time only)
        $technician = User::where('role', 'technician')
            ->where('is_active', true)
            ->where('is_available', true)
            ->where('is_approved', true)
            ->whereJsonContains('service_categories', $request->category)
            ->whereDoesntHave('earnings', function ($query) {
                // Exclude if has ANY pending custody
                $query->where('is_custody', true)
                      ->where('status', 'pending');
            })
            ->whereDoesntHave('assignedRequests', function ($query) {
                // Exclude if has ANY active orders (one order at a time)
                $query->whereIn('status', ['assigned', 'on_the_way', 'arrived', 'started', 'work_done']);
            })
            ->first();

        if ($technician) {
            $request->update([
                'technician_id' => $technician->id,
                'status' => 'assigned',
            ]);

            Log::info("Auto-assigned request #{$request->id} to technician #{$technician->id} ({$technician->name}) - Service: {$request->category}");

            return $technician;
        }

        Log::info("No available technician found for request #{$request->id} - Service: {$request->category}");
        return null;
    }
}
```

**التغييرات الرئيسية:**
- ❌ تم إزالة منطق `max_orders_per_technician`
- ✅ إضافة شرط `whereDoesntHave('assignedRequests')` لضمان عدم وجود طلبات نشطة
- ✅ الطلبات النشطة: `assigned`, `on_the_way`, `arrived`, `started`, `work_done`

---

### 2. ✅ إنشاء أمر Artisan لحذف جميع الطلبات

**الملف:** `app/Console/Commands/DeleteAllRequests.php`

**الكود الكامل:**

```php
<?php

namespace App\Console\Commands;

use App\Models\Request;
use Illuminate\Console\Command;

class DeleteAllRequests extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'requests:delete-all {--force : Force deletion without confirmation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'حذف جميع الطلبات من قاعدة البيانات';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $count = Request::count();

        if ($count === 0) {
            $this->info('لا توجد طلبات في قاعدة البيانات.');
            return 0;
        }

        if (!$this->option('force')) {
            if (!$this->confirm("هل أنت متأكد من حذف جميع الطلبات ({$count} طلب)؟", false)) {
                $this->info('تم إلغاء العملية.');
                return 0;
            }
        }

        $this->info("جاري حذف {$count} طلب...");

        try {
            // Delete all requests (cascade will handle related records)
            Request::query()->delete();

            $this->info("✓ تم حذف جميع الطلبات بنجاح ({$count} طلب).");
            return 0;
        } catch (\Exception $e) {
            $this->error("حدث خطأ أثناء حذف الطلبات: " . $e->getMessage());
            return 1;
        }
    }
}
```

**الاستخدام:**
```bash
php artisan requests:delete-all
php artisan requests:delete-all --force  # بدون تأكيد
```

---

### 3. ✅ سكريبت PHP مباشر لحذف الطلبات (اختياري)

**الملف:** `delete_all_requests.php` (في جذر المشروع)

**الكود:**

```php
<?php

/**
 * Script to delete all requests from the database
 * Run: php delete_all_requests.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Request;

try {
    $count = Request::count();

    if ($count === 0) {
        echo "لا توجد طلبات في قاعدة البيانات.\n";
        exit(0);
    }

    echo "جاري حذف {$count} طلب...\n";

    // Delete all requests
    Request::query()->delete();

    echo "✓ تم حذف جميع الطلبات بنجاح ({$count} طلب).\n";
    exit(0);
} catch (\Exception $e) {
    echo "حدث خطأ أثناء حذف الطلبات: " . $e->getMessage() . "\n";
    exit(1);
}
```

---

## 📝 ملاحظات مهمة

### التغييرات في منطق التوزيع:

**قبل التعديل:**
- كان النظام يسمح للفني بأخذ عدة طلبات (حسب `max_orders_per_technician`)
- كان يستخدم `withCount` و `having` للتحقق من عدد الطلبات

**بعد التعديل:**
- الفني يأخذ **طلبية واحدة فقط** في كل مرة
- لا يمكن للفني الحصول على طلب جديد إلا بعد إكمال الطلب الحالي (`completed`)
- يستخدم `whereDoesntHave` للتحقق من عدم وجود طلبات نشطة

### الطلبات النشطة:
الطلبات التي تعتبر "نشطة" (يمنع الفني من أخذ طلب جديد):
- `assigned` - تم التعيين
- `on_the_way` - في الطريق
- `arrived` - وصل الفني
- `started` - قيد التنفيذ
- `work_done` - انتهى العمل

**ملاحظة:** الطلبات بحالة `completed` أو `canceled` لا تعتبر نشطة، لذلك يمكن للفني أخذ طلب جديد بعد إكمال الطلب.

---

## ✅ خطوات التطبيق في مشروع Backend المنفصل

1. **تعديل TechnicianAssignmentService:**
   - افتح `app/Services/TechnicianAssignmentService.php`
   - استبدل دالة `autoAssignTechnician` بالكود الجديد أعلاه

2. **إضافة أمر DeleteAllRequests:**
   - أنشئ ملف `app/Console/Commands/DeleteAllRequests.php`
   - انسخ الكود أعلاه

3. **اختبار التعديلات:**
   ```bash
   # اختبار الأمر
   php artisan requests:delete-all

   # اختبار التوزيع التلقائي
   # أنشئ طلب جديد وتحقق من أنه يتم تعيينه لفني واحد فقط
   ```

---

## 🔍 التحقق من التطبيق

بعد تطبيق التعديلات، تأكد من:

1. ✅ الفني لا يمكنه الحصول على طلب جديد إذا كان لديه طلب نشط
2. ✅ بعد إكمال الطلب (`completed`)، يمكن للفني الحصول على طلب جديد
3. ✅ أمر حذف الطلبات يعمل بشكل صحيح

---

**تاريخ التعديل:** $(date)
**الملفات المعدلة:**
- `app/Services/TechnicianAssignmentService.php`
- `app/Console/Commands/DeleteAllRequests.php` (جديد)
- `delete_all_requests.php` (جديد - اختياري)
