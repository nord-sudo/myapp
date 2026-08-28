@extends('layouts.admin')

@section('title', 'Préstamos')
@section('page_title', 'Préstamos & Calendario de Cuotas')

@section('content')
<div class="panel-box">
    <div class="panel-header">
        <h2 class="panel-title">Lista de Préstamos Registrados</h2>
        <button onclick="document.getElementById('modalLoan').style.display='flex'" class="btn-success">➕ Entregar Nuevo Préstamo</button>
    </div>

    <table class="table-custom">
        <thead>
            <tr>
                <th>ID / Número</th>
                <th>Cliente</th>
                <th>Monto Prestado</th>
                <th>Interés</th>
                <th>Total a Pagar</th>
                <th>Falta por Pagar</th>
                <th>Frecuencia</th>
                <th>Cuotas</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            @forelse($loans as $loan)
                <tr>
                    <td><strong>#{{ $loan->id }}</strong><br><small style="color: var(--text-muted);">{{ $loan->loan_number }}</small></td>
                    <td><strong>{{ $loan->customer->first_name ?? 'Cliente' }} {{ $loan->customer->last_name ?? '' }}</strong></td>
                    <td>RD$ {{ number_format($loan->amount, 2) }}</td>
                    <td>{{ $loan->interest_rate }}%</td>
                    <td>RD$ {{ number_format($loan->total_amount, 2) }}</td>
                    <td><strong style="color: var(--accent); font-size: 15px;">RD$ {{ number_format($loan->balance_remaining, 2) }}</strong></td>
                    <td>{{ strtoupper($loan->frequency) }}</td>
                    <td>{{ $loan->term_units }} Cuotas</td>
                    <td>
                        @if($loan->status == 'overdue')
                            <span class="status-pill overdue">EN MORA</span>
                        @elseif($loan->status == 'paid')
                            <span class="status-pill paid">PAGADO</span>
                        @else
                            <span class="status-pill active">ACTIVO</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="9" style="text-align: center; color: var(--text-muted);">No hay préstamos registrados aún.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 20px;">
        {{ $loans->links() }}
    </div>
</div>

<!-- Modal Entregar Préstamo -->
<div id="modalLoan" class="modal-overlay">
    <div class="modal-content">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <h3 style="font-size: 18px; font-weight: 800;">💳 Entregar Nuevo Préstamo</h3>
            <button onclick="document.getElementById('modalLoan').style.display='none'" style="background: none; border: none; font-size: 20px; cursor: pointer;">✕</button>
        </div>
        <form action="{{ route('admin.loans.store') }}" method="POST">
            @csrf
            <div class="form-group">
                <label>Cliente Beneficiario *</label>
                <select name="customer_id" required class="form-control">
                    <option value="">-- Seleccionar Cliente --</option>
                    @foreach($customersList as $cust)
                        <option value="{{ $cust->id }}">{{ $cust->first_name }} {{ $cust->last_name }} ({{ $cust->identity_document }})</option>
                    @endforeach
                </select>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Monto a Prestar (RD$) *</label>
                    <input type="number" step="100" name="amount" required class="form-control" placeholder="Ej: 20000">
                </div>
                <div class="form-group">
                    <label>Tasa de Interés (%) *</label>
                    <input type="number" step="0.5" name="interest_rate" required class="form-control" placeholder="Ej: 20">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                <div class="form-group">
                    <label>Cantidad de Cuotas *</label>
                    <input type="number" name="term_units" required class="form-control" placeholder="Ej: 10">
                </div>
                <div class="form-group">
                    <label>Frecuencia de Pago *</label>
                    <select name="frequency" required class="form-control">
                        <option value="weekly">Semanal</option>
                        <option value="biweekly">Quincenal</option>
                        <option value="monthly">Mensual</option>
                        <option value="daily">Diario</option>
                    </select>
                </div>
            </div>

            <div class="form-group">
                <label>Fecha del Primer Pago *</label>
                <input type="date" name="start_date" value="{{ date('Y-m-d') }}" required class="form-control">
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 24px;">
                <button type="button" onclick="document.getElementById('modalLoan').style.display='none'" class="btn-primary" style="background-color: #64748B;">Cancelar</button>
                <button type="submit" class="btn-success">Crear Préstamo & Cuotas</button>
            </div>
        </form>
    </div>
</div>
@endsection
