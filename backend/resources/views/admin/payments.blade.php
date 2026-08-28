@extends('layouts.admin')

@section('title', 'Cobros & Recibos')
@section('page_title', 'Histórico de Cobros & Comprobantes')

@section('content')
<div class="panel-box">
    <div class="panel-header">
        <h2 class="panel-title">Cobros Registrados</h2>
        <button onclick="document.getElementById('modalPayment').style.display='flex'" class="btn-success">➕ Registrar Nuevo Cobro</button>
    </div>

    <table class="table-custom">
        <thead>
            <tr>
                <th>Recibo #</th>
                <th>Cliente</th>
                <th>Monto Cobrado</th>
                <th>Método de Pago</th>
                <th>Comprobante</th>
                <th>Fecha de Pago</th>
                <th>Idempotencia / UUID</th>
            </tr>
        </thead>
        <tbody>
            @forelse($payments as $payment)
                <tr>
                    <td><strong>{{ $payment->receipt_number }}</strong></td>
                    <td>{{ $payment->customer->first_name ?? 'Cliente' }} {{ $payment->customer->last_name ?? '' }}</td>
                    <td><strong style="color: var(--success); font-size: 16px;">RD$ {{ number_format($payment->amount, 2) }}</strong></td>
                    <td>
                        @if($payment->payment_method == 'transfer')
                            <span class="status-pill active">🏦 Transferencia</span>
                        @else
                            <span class="status-pill paid">💵 Efectivo</span>
                        @endif
                    </td>
                    <td>
                        @if($payment->proof_image_path)
                            <a href="{{ asset('storage/' . $payment->proof_image_path) }}" target="_blank" class="status-pill paid" style="text-decoration: none;">📷 Ver Foto</a>
                        @elseif($payment->payment_method == 'transfer')
                            <span class="status-pill overdue">⚠️ Sin Foto</span>
                        @else
                            <span style="color: var(--text-muted); font-size: 12px;">N/A (Efectivo)</span>
                        @endif
                    </td>
                    <td>{{ $payment->payment_date ? $payment->payment_date->format('d/m/Y') : '' }}</td>
                    <td><code style="font-size: 11px; color: var(--text-muted);">{{ substr($payment->idempotency_key, 0, 16) }}...</code></td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align: center; color: var(--text-muted);">No hay cobros registrados aún.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 20px;">
        {{ $payments->links() }}
    </div>
</div>

<!-- Modal Registrar Cobro -->
<div id="modalPayment" class="modal-overlay">
    <div class="modal-content">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <h3 style="font-size: 18px; font-weight: 800;">💵 Registrar Nuevo Cobro</h3>
            <button onclick="document.getElementById('modalPayment').style.display='none'" style="background: none; border: none; font-size: 20px; cursor: pointer;">✕</button>
        </div>
        <form action="{{ route('admin.payments.store') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <div class="form-group">
                <label>Préstamo del Cliente *</label>
                <select name="loan_id" required class="form-control">
                    <option value="">-- Seleccionar Préstamo --</option>
                    @foreach($activeLoansList as $ln)
                        <option value="{{ $ln->id }}">Préstamo #{{ $ln->id }} - {{ $ln->customer->first_name ?? '' }} {{ $ln->customer->last_name ?? '' }} (Pendiente: RD$ {{ number_format($ln->balance_remaining, 2) }})</option>
                    @endforeach
                </select>
            </div>

            <div class="form-group">
                <label>Monto del Cobro (RD$) *</label>
                <input type="number" step="0.01" name="amount" required class="form-control" placeholder="Ej: 1500">
            </div>

            <div class="form-group">
                <label>Método de Pago *</label>
                <select name="payment_method" id="webPaymentMethod" required class="form-control" onchange="toggleWebProof(this.value)">
                    <option value="cash">💵 Efectivo</option>
                    <option value="transfer">🏦 Transferencia Bancaria</option>
                </select>
            </div>

            <div class="form-group" id="webProofGroup" style="display: none;">
                <label style="color: var(--danger);">Comprobante de Transferencia (OBLIGATORIO) *</label>
                <input type="file" name="proof_image" accept="image/*" class="form-control">
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 24px;">
                <button type="button" onclick="document.getElementById('modalPayment').style.display='none'" class="btn-primary" style="background-color: #64748B;">Cancelar</button>
                <button type="submit" class="btn-success">Confirmar & Guardar Cobro</button>
            </div>
        </form>
    </div>
</div>

<script>
function toggleWebProof(method) {
    document.getElementById('webProofGroup').style.display = (method === 'transfer') ? 'block' : 'none';
}
</script>
@endsection
