@extends('layouts.admin')

@section('title', 'Cobradores y Prestamistas')

@section('content')
<div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 12px;">
    <div>
        <h1 style="font-size: 22px; font-weight: 800; color: var(--text-main);">👔 Cobradores y Prestamistas Registrados</h1>
        <p style="font-size: 13px; color: var(--text-secondary);">Supervisión de usuarios, equipo de cobranza, rutas asignadas e historial de cobros</p>
    </div>
    <button onclick="document.getElementById('modal-new-lender').style.display='flex'" class="btn-primary">
        + Registrar Nuevo Cobrador
    </button>
</div>

<!-- Collector KPI Stats -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px;">
    <div class="card-metric" style="border-left: 4px solid var(--primary);">
        <div class="metric-title">Total Cobradores</div>
        <div class="metric-value primary">{{ count($lenders) }}</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">Personal con acceso a app móvil</div>
    </div>
    <div class="card-metric" style="border-left: 4px solid var(--success);">
        <div class="metric-title">Cobradores Activos</div>
        <div class="metric-value success">{{ count($lenders) }}</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">🟢 Sesiones activas hoy</div>
    </div>
    <div class="card-metric" style="border-left: 4px solid var(--warning);">
        <div class="metric-title">Rutas de Cobro</div>
        <div class="metric-value" style="color: var(--warning);">Santo Domingo</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">Zona de operación principal</div>
    </div>
</div>

<div class="panel-box">
    <div class="panel-header">
        <h2 class="panel-title">👥 Lista Completa de Usuarios y Cobradores</h2>
        <span style="font-size: 12px; color: var(--text-secondary);">Datos visibles de acceso y estado</span>
    </div>

    <table class="table-custom">
        <thead>
            <tr>
                <th>Nombre del Cobrador</th>
                <th>Correo de Acceso</th>
                <th>Teléfono</th>
                <th>Rol / Permisos</th>
                <th>Cartera Asignada</th>
                <th>Estado</th>
                <th>Acciones</th>
            </tr>
        </thead>
        <tbody>
            @forelse($lenders as $l)
            <tr>
                <td>
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <div class="avatar" style="width: 36px; height: 36px; font-size: 13px;">
                            {{ strtoupper(substr($l->name, 0, 2)) }}
                        </div>
                        <div>
                            <div style="font-weight: 700; color: var(--primary); font-size: 14px;">{{ $l->name }}</div>
                            <div style="font-size: 11px; color: var(--text-secondary);">ID Usuario: #USR-100{{ $l->id }}</div>
                        </div>
                    </div>
                </td>
                <td style="font-weight: 600;">{{ $l->email }}</td>
                <td>{{ $l->phone ?? '809-555-0000' }}</td>
                <td>
                    <span style="background: #EEF3F0; color: var(--primary); padding: 4px 8px; border-radius: 6px; font-size: 11.5px; font-weight: 700;">
                        👔 Cobrador / Prestamista
                    </span>
                </td>
                <td>
                    <div style="font-size: 12.5px; font-weight: 700; color: var(--text-main);">12 Clientes</div>
                    <div style="font-size: 11px; color: var(--text-secondary);">Ruta Santo Domingo</div>
                </td>
                <td><span class="pill-status success">● Activo</span></td>
                <td>
                    <div style="display: flex; gap: 6px;">
                        <button class="btn-secondary" style="font-size: 11px; padding: 5px 10px;">✏️ Editar</button>
                        <button class="btn-secondary" style="font-size: 11px; padding: 5px 10px;">📍 Ver Ruta</button>
                        <button class="btn-secondary" style="font-size: 11px; padding: 5px 10px;">📱 Dispositivo</button>
                    </div>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="7" style="text-align: center; color: var(--text-secondary); padding: 30px;">
                    No se encontraron cobradores registrados.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Modal Crear Prestamista / Cobrador -->
<div id="modal-new-lender" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999; align-items: center; justify-content: center;">
    <div style="background: white; padding: 28px; border-radius: 14px; width: 100%; max-width: 500px;">
        <h2 style="font-size: 18px; font-weight: 800; margin-bottom: 16px; color: var(--primary);">Registrar Nuevo Cobrador / Prestamista</h2>
        
        <form method="POST" action="{{ route('admin.lenders.store') }}">
            @csrf
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Nombre Completo</label>
                <input type="text" name="name" required placeholder="Ej. Carlos Mendoza" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Correo Electrónico (Usuario de App)</label>
                <input type="email" name="email" required placeholder="cobrador@empresa.com" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Contraseña de Acceso</label>
                <input type="password" name="password" required placeholder="******" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 16px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Teléfono Móvil</label>
                <input type="text" name="phone" placeholder="809-555-0000" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>

            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button type="button" onclick="document.getElementById('modal-new-lender').style.display='none'" class="btn-secondary">Cancelar</button>
                <button type="submit" class="btn-primary">Guardar Cobrador</button>
            </div>
        </form>
    </div>
</div>
@endsection
