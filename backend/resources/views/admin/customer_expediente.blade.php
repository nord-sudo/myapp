@extends('layouts.admin')

@section('title', 'Expediente del Cliente')

@section('content')
@php
    $frontImg = $customer->identity_document_front;
    $backImg = $customer->identity_document_back;

    function formatDocUrl($path) {
        if (!$path || empty($path)) return null;
        if (str_starts_with($path, 'data:image') || str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return asset('storage/' . ltrim($path, '/'));
    }

    $frontUrl = formatDocUrl($frontImg);
    $backUrl = formatDocUrl($backImg);
@endphp

<div style="margin-bottom: 24px;">
    <a href="{{ route('admin.customers') }}" style="text-decoration: none; font-size: 12.5px; color: var(--text-secondary); font-weight: 600;">← Volver a Clientes</a>
    <h1 style="font-size: 24px; font-weight: 800; color: var(--primary); margin-top: 6px;">
        Expediente: {{ $customer->first_name }} {{ $customer->last_name }}
    </h1>
    <p style="font-size: 13px; color: var(--text-secondary);">Cédula: {{ $customer->identity_document }} • {{ $customer->phone }} • {{ $customer->city ?? 'Santo Domingo' }}</p>
</div>

<!-- Expediente Header Navigation Tabs -->
<div style="display: flex; gap: 8px; border-bottom: 1px solid var(--border-color); margin-bottom: 24px; overflow-x: auto;">
    <button class="btn-primary" style="border-radius: 8px 8px 0 0; padding: 10px 16px;">📂 Información & Documentos</button>
    <button class="btn-secondary" style="border-radius: 8px 8px 0 0; border-bottom: none; padding: 10px 16px;">💳 Préstamos ({{ count($customer->loans) }})</button>
    <button class="btn-secondary" style="border-radius: 8px 8px 0 0; border-bottom: none; padding: 10px 16px;">💵 Pagos ({{ count($customer->payments) }})</button>
    <button class="btn-secondary" style="border-radius: 8px 8px 0 0; border-bottom: none; padding: 10px 16px;">⚠️ Historial de Mora</button>
</div>

<div style="display: grid; grid-template-columns: 1fr 2fr; gap: 24px;">
    <!-- Personal Information Card -->
    <div class="panel-box">
        <h2 class="panel-title" style="margin-bottom: 16px;">👤 Datos Personales</h2>
        <div style="display: flex; flex-direction: column; gap: 14px; font-size: 13px;">
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">NOMBRE COMPLETO</span>
                <strong style="font-size: 15px; color: var(--primary);">{{ $customer->first_name }} {{ $customer->last_name }}</strong>
            </div>
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">CÉDULA DE IDENTIDAD</span>
                <strong style="font-size: 14px;">{{ $customer->identity_document }}</strong>
            </div>
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">TELÉFONO / WHATSAPP</span>
                <strong>{{ $customer->phone }}</strong>
            </div>
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">DIRECCIÓN</span>
                <strong>{{ $customer->address }}</strong>
            </div>
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">CIUDAD</span>
                <strong>{{ $customer->city ?? 'Santo Domingo' }}</strong>
            </div>
            <div>
                <span style="color: var(--text-secondary); display: block; font-size: 11px; font-weight: 700;">ESTADO</span>
                <span class="pill-status success">● Cliente Activo</span>
            </div>
        </div>
    </div>

    <!-- Expediente Identity Documents Section -->
    <div class="panel-box">
        <div class="panel-header">
            <div>
                <h2 class="panel-title">🪪 Fotos de Cédula de Identidad</h2>
                <div style="font-size: 12px; color: var(--text-secondary);">Verifique los documentos escaneados o capturados desde la app</div>
            </div>
            <button onclick="document.getElementById('modal-upload-docs').style.display='flex'" class="btn-primary" style="font-size: 12px; padding: 6px 12px;">
                📤 Subir / Cambiar Fotos
            </button>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-bottom: 24px;">
            <!-- Cédula Frente Card -->
            <div style="border: 1px solid var(--border-color); border-radius: 12px; padding: 16px; background: var(--bg-main);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <div style="font-size: 13px; font-weight: 700; color: var(--primary);">🪪 Cédula — Frente</div>
                    @if($frontUrl)
                        <span class="pill-status success" style="font-size: 10px;">✓ Adjuntada</span>
                    @else
                        <span class="pill-status danger" style="font-size: 10px;">⚠️ Pendiente</span>
                    @endif
                </div>
                
                <div style="height: 160px; border-radius: 10px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; overflow: hidden; border: 1px dashed var(--border-color); position: relative;">
                    @if($frontUrl)
                        <img src="{{ $frontUrl }}" alt="Cédula Frente" style="width: 100%; height: 100%; object-fit: contain; cursor: pointer; transition: transform 0.2s;" onclick="openImageModal('{{ $frontUrl }}', 'Cédula Frente')">
                    @else
                        <div style="text-align: center; color: var(--text-secondary); padding: 12px;">
                            <div style="font-size: 28px; margin-bottom: 4px;">📷</div>
                            <div style="font-size: 12px; font-weight: 600;">Sin foto de Frente</div>
                            <div style="font-size: 11px; color: var(--text-secondary);">Haz clic en 'Subir Fotos'</div>
                        </div>
                    @endif
                </div>

                <div style="display: flex; gap: 8px; margin-top: 12px;">
                    @if($frontUrl)
                        <button onclick="openImageModal('{{ $frontUrl }}', 'Cédula Frente - {{ $customer->first_name }}')" class="btn-secondary" style="font-size: 11px; padding: 6px 10px; flex: 1;">🔍 Ver Completa</button>
                    @endif
                    <button onclick="document.getElementById('modal-upload-docs').style.display='flex'" class="btn-secondary" style="font-size: 11px; padding: 6px 10px; flex: 1;">✏️ Cambiar</button>
                </div>
            </div>

            <!-- Cédula Reverso Card -->
            <div style="border: 1px solid var(--border-color); border-radius: 12px; padding: 16px; background: var(--bg-main);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                    <div style="font-size: 13px; font-weight: 700; color: var(--primary);">🪪 Cédula — Reverso</div>
                    @if($backUrl)
                        <span class="pill-status success" style="font-size: 10px;">✓ Adjuntada</span>
                    @else
                        <span class="pill-status danger" style="font-size: 10px;">⚠️ Pendiente</span>
                    @endif
                </div>

                <div style="height: 160px; border-radius: 10px; background: #FFFFFF; display: flex; align-items: center; justify-content: center; overflow: hidden; border: 1px dashed var(--border-color); position: relative;">
                    @if($backUrl)
                        <img src="{{ $backUrl }}" alt="Cédula Reverso" style="width: 100%; height: 100%; object-fit: contain; cursor: pointer; transition: transform 0.2s;" onclick="openImageModal('{{ $backUrl }}', 'Cédula Reverso')">
                    @else
                        <div style="text-align: center; color: var(--text-secondary); padding: 12px;">
                            <div style="font-size: 28px; margin-bottom: 4px;">📷</div>
                            <div style="font-size: 12px; font-weight: 600;">Sin foto de Reverso</div>
                            <div style="font-size: 11px; color: var(--text-secondary);">Haz clic en 'Subir Fotos'</div>
                        </div>
                    @endif
                </div>

                <div style="display: flex; gap: 8px; margin-top: 12px;">
                    @if($backUrl)
                        <button onclick="openImageModal('{{ $backUrl }}', 'Cédula Reverso - {{ $customer->first_name }}')" class="btn-secondary" style="font-size: 11px; padding: 6px 10px; flex: 1;">🔍 Ver Completa</button>
                    @endif
                    <button onclick="document.getElementById('modal-upload-docs').style.display='flex'" class="btn-secondary" style="font-size: 11px; padding: 6px 10px; flex: 1;">✏️ Cambiar</button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Modal Upload Documents -->
<div id="modal-upload-docs" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 999; align-items: center; justify-content: center;">
    <div style="background: white; padding: 28px; border-radius: 14px; width: 100%; max-width: 520px;">
        <h2 style="font-size: 18px; font-weight: 800; margin-bottom: 6px; color: var(--primary);">Subir Fotos de Cédula</h2>
        <p style="font-size: 12.5px; color: var(--text-secondary); margin-bottom: 18px;">Seleccione archivos de imagen JPG o PNG para la Cédula de {{ $customer->first_name }}</p>

        <form method="POST" action="{{ route('admin.customers.documents', $customer->id) }}" enctype="multipart/form-data">
            @csrf
            <div style="margin-bottom: 16px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary); display: block; margin-bottom: 6px;">🪪 Foto Cédula — FRENTE</label>
                <input type="file" name="identity_document_front" accept="image/*" style="width: 100%; padding: 8px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>

            <div style="margin-bottom: 20px;">
                <label style="font-size: 12px; font-weight: 700; color: var(--text-secondary); display: block; margin-bottom: 6px;">🪪 Foto Cédula — REVERSO</label>
                <input type="file" name="identity_document_back" accept="image/*" style="width: 100%; padding: 8px; border: 1px solid var(--border-color); border-radius: 8px;">
            </div>

            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button type="button" onclick="document.getElementById('modal-upload-docs').style.display='none'" class="btn-secondary">Cancelar</button>
                <button type="submit" class="btn-primary">Guardar Documentos</button>
            </div>
        </form>
    </div>
</div>

<!-- Full Image View Modal -->
<div id="modal-image-view" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); z-index: 1000; align-items: center; justify-content: center; padding: 20px;">
    <div style="position: relative; max-width: 90%; max-height: 90%; text-align: center;">
        <button onclick="document.getElementById('modal-image-view').style.display='none'" style="position: absolute; top: -40px; right: 0; background: white; border: none; padding: 6px 14px; border-radius: 20px; font-weight: 800; cursor: pointer;">✕ Cerrar</button>
        <div id="modal-img-title" style="color: white; font-weight: 700; margin-bottom: 10px; font-size: 16px;"></div>
        <img id="modal-img-tag" src="" style="max-width: 100%; max-height: 80vh; border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
    </div>
</div>

@endsection

@section('scripts')
<script>
    function openImageModal(url, title) {
        document.getElementById('modal-img-tag').src = url;
        document.getElementById('modal-img-title').innerText = title;
        document.getElementById('modal-image-view').style.display = 'flex';
    }
</script>
@endsection
