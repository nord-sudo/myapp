@extends('layouts.admin')

@section('title', 'Auditoría')
@section('page_title', 'Registro de Auditoría de Operaciones')

@section('content')
<div class="panel-box">
    <div class="panel-header">
        <h2 class="panel-title">Logs de Auditoría Financiera e Inmutable</h2>
    </div>

    <table class="table-custom">
        <thead>
            <tr>
                <th>ID</th>
                <th>Acción</th>
                <th>Modelo</th>
                <th>ID Modelo</th>
                <th>Dirección IP</th>
                <th>Dispositivo (UUID)</th>
                <th>Fecha y Hora</th>
            </tr>
        </thead>
        <tbody>
            @forelse($logs as $log)
                <tr>
                    <td>#{{ $log->id }}</td>
                    <td><strong style="color: var(--accent);">{{ $log->action }}</strong></td>
                    <td>{{ class_basename($log->model) }}</td>
                    <td>#{{ $log->model_id }}</td>
                    <td><code>{{ $log->ip_address ?? '127.0.0.1' }}</code></td>
                    <td><code style="font-size: 11px; color: var(--text-muted);">{{ substr($log->device_uuid ?? 'N/A', 0, 16) }}...</code></td>
                    <td>{{ $log->created_at ? $log->created_at->format('d/m/Y H:i:s') : '' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align: center; color: var(--text-muted);">No hay registros de auditoría aún.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 20px;">
        {{ $logs->links() }}
    </div>
</div>
@endsection
