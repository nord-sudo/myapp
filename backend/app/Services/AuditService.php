<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Support\Facades\Request;

class AuditService
{
    public static function log(string $action, $model = null, ?array $oldValues = null, ?array $newValues = null): void
    {
        try {
            AuditLog::create([
                'user_id' => auth()->id(),
                'action' => $action,
                'model' => $model ? get_class($model) : null,
                'model_id' => $model ? $model->id : null,
                'old_values' => $oldValues ? json_encode($oldValues) : null,
                'new_values' => $newValues ? json_encode($newValues) : null,
                'ip_address' => Request::ip(),
                'device_uuid' => Request::header('X-Device-UUID'),
            ]);
        } catch (\Throwable $e) {
            // Log silently or handle error without breaking financial transaction
            logger()->error('Audit logging failed: ' . $e->getMessage());
        }
    }
}
