@extends('layouts.admin')

@section('title', 'Configuración')

@section('content')
<div style="margin-bottom: 24px;">
    <h1 style="font-size: 22px; font-weight: 800; color: var(--text-main);">Configuración del Sistema Financiero</h1>
    <p style="font-size: 13px; color: var(--text-secondary);">Ajustes de empresa, mora automática, monedas e integración API</p>
</div>

<div class="panel-box">
    <h2 class="panel-title" style="margin-bottom: 16px;">🏢 Información de la Empresa</h2>
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">
        <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Nombre Comercial</label>
            <input type="text" value="Financiera Prestamistas Pro RD" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px; font-size: 13px;">
        </div>
        <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">RNC / Identificación Fiscal</label>
            <input type="text" value="1-30-12345-6" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px; font-size: 13px;">
        </div>
        <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Moneda Principal</label>
            <input type="text" value="Peso Dominicano (RD$ / DOP)" readonly style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px; font-size: 13px; background: var(--bg-main);">
        </div>
        <div>
            <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary);">Tasa de Mora Predeterminada</label>
            <input type="text" value="5% mensual" style="width: 100%; padding: 8px 12px; border: 1px solid var(--border-color); border-radius: 8px; font-size: 13px;">
        </div>
    </div>
    <button class="btn-primary">Guardar Cambios</button>
</div>
@endsection
