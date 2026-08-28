@extends('layouts.admin')

@section('title', 'Clientes')

@section('content')
<div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px;">
    <div>
        <h1 style="font-size: 22px; font-weight: 800; color: var(--text-main);">Gestión de Clientes</h1>
        <p style="font-size: 13px; color: var(--text-secondary);">Expedientes completos de clientes y documentos de identidad</p>
    </div>
    <button onclick="document.getElementById('modal-new-customer').style.display='flex'" class="btn-primary">
        + Nuevo cliente
    </button>
</div>

<div class="panel-box">
    <div style="display: flex; gap: 12px; margin-bottom: 20px;">
        <form method="GET" action="{{ route('admin.customers') }}" style="display: flex; gap: 10px; width: 100%;">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="Buscar por nombre, cédula o teléfono..." style="flex: 1; padding: 10px 14px; border: 1px solid var(--border-color); border-radius: 8px; font-size: 13.5px;">
            <button type="submit" class="btn-secondary">Buscar</button>
        </form>
    </div>

    <table class="table-custom">
        <thead>
            <tr>
                <th>Cliente</th>
                <th>Cédula</th>
                <th>Teléfono</th>
                <th>Ciudad</th>
                <th>Préstamos Activos</th>
                <th>Estado</th>
                <th>Acción</th>
            </tr>
        </thead>
        <tbody>
            @forelse($customers as $c)
            <tr>
                <td style="font-weight: 700; color: var(--primary);">
                    {{ $c->first_name }} {{ $c->last_name }}
                </td>
                <td>{{ $c->identity_document }}</td>
                <td>{{ $c->phone }}</td>
                <td>{{ $c->city ?? 'Santo Domingo' }}</td>
                <td>
                    <span class="pill-status active">{{ $c->loans_count ?? 1 }} Activo</span>
                </td>
                <td>
                    <span class="pill-status success">Activo</span>
                </td>
                <td>
                    <a href="{{ route('admin.customers.show', $c->id) }}" class="btn-secondary" style="font-size: 11.5px; padding: 5px 10px;">
                        📂 Ver Expediente
                    </a>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="7" style="text-align: center; color: var(--text-secondary); padding: 30px;">
                    No se encontraron clientes registrados.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Modal Nuevo Cliente -->
<div id="modal-new-customer" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999; align-items: center; justify-content: center;">
    <div style="background: white; padding: 28px; border-radius: 14px; width: 100%; max-width: 500px;">
        <h2 style="font-size: 18px; font-weight: 800; margin-bottom: 16px; color: var(--primary);">Registrar Nuevo Cliente</h2>
        
        <form method="POST" action="{{ route('admin.customers.store') }}">
            @csrf
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Nombre</label>
                <input type="text" name="first_name" required style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Apellido</label>
                <input type="text" name="last_name" required style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Cédula</label>
                <input type="text" name="identity_document" required placeholder="001-0000000-0" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 12px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Teléfono</label>
                <input type="text" name="phone" required placeholder="809-000-0000" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>
            <div style="margin-bottom: 16px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Dirección</label>
                <input type="text" name="address" required style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>

            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button type="button" onclick="document.getElementById('modal-new-customer').style.display='none'" class="btn-secondary">Cancelar</button>
                <button type="submit" class="btn-primary">Guardar Cliente</button>
            </div>
        </form>
    </div>
</div>
@endsection
