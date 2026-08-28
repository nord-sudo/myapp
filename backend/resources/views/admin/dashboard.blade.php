@extends('layouts.admin')

@section('title', 'Dashboard Operativo')

@section('content')
<div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; flex-wrap: wrap; gap: 12px;">
    <div>
        <h1 style="font-size: 24px; font-weight: 800; color: var(--primary); letter-spacing: -0.5px;">📊 Control Operativo y Financiero</h1>
        <p style="font-size: 13.5px; color: var(--text-secondary);">Supervisión general de cartera, cobradores y préstamos • República Dominicana (RD$)</p>
    </div>
    <div style="display: flex; gap: 10px;">
        <a href="{{ route('admin.loans') }}" class="btn-primary">💳 + Desembolsar Préstamo</a>
        <a href="{{ route('admin.payments') }}" class="btn-secondary">💵 + Registrar Cobro</a>
    </div>
</div>

<!-- Financial Metrics Grid -->
<div class="grid-3" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px;">
    <div class="card-metric" style="border-left: 4px solid var(--primary);">
        <div class="metric-title">Dinero Prestado (Cartera Total)</div>
        <div class="metric-value primary">RD$ {{ number_format($totalPortfolio, 2) }}</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">Capital acumulado desembolsado: RD$ {{ number_format($totalDisbursed, 2) }}</div>
    </div>

    <div class="card-metric" style="border-left: 4px solid var(--success);">
        <div class="metric-title">Dinero Cobrado Hoy</div>
        <div class="metric-value success">RD$ {{ number_format($collectedToday, 2) }}</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">Acumulado del mes: RD$ {{ number_format($collectedThisMonth, 2) }}</div>
    </div>

    <div class="card-metric" style="border-left: 4px solid var(--warning);">
        <div class="metric-title">Cobros Pendientes Hoy</div>
        <div class="metric-value" style="color: var(--warning);">RD$ {{ number_format($pendingToday, 2) }}</div>
        <div style="font-size: 11px; color: var(--text-secondary); margin-top: 4px;">Cuotas programadas para cobradores hoy</div>
    </div>

    <div class="card-metric" style="border-left: 4px solid var(--danger);">
        <div class="metric-title">Total en Mora / Vencido</div>
        <div class="metric-value danger">RD$ {{ number_format($overdueAmount, 2) }}</div>
        <div style="font-size: 11px; color: var(--danger); margin-top: 4px; font-weight: 600;">⚠️ {{ $overdueLoansCount }} préstamos en mora activa</div>
    </div>
</div>

<!-- Operations & Collector Performance Bar -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 14px; margin-bottom: 24px;">
    <div style="background: white; padding: 14px 18px; border-radius: 10px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between;">
        <div>
            <div style="font-size: 11px; color: var(--text-secondary); font-weight: 700; text-transform: uppercase;">Préstamos Activos</div>
            <div style="font-size: 20px; font-weight: 800; color: var(--primary);">{{ $activeLoansCount }}</div>
        </div>
        <span style="font-size: 24px;">💳</span>
    </div>

    <div style="background: white; padding: 14px 18px; border-radius: 10px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between;">
        <div>
            <div style="font-size: 11px; color: var(--text-secondary); font-weight: 700; text-transform: uppercase;">Clientes Registrados</div>
            <div style="font-size: 20px; font-weight: 800; color: var(--primary);">{{ $totalCustomers }}</div>
        </div>
        <span style="font-size: 24px;">👥</span>
    </div>

    <div style="background: white; padding: 14px 18px; border-radius: 10px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between;">
        <div>
            <div style="font-size: 11px; color: var(--text-secondary); font-weight: 700; text-transform: uppercase;">Prestamistas / Cobradores</div>
            <div style="font-size: 20px; font-weight: 800; color: var(--primary);">{{ $totalLenders }}</div>
        </div>
        <span style="font-size: 24px;">👔</span>
    </div>

    <div style="background: white; padding: 14px 18px; border-radius: 10px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between;">
        <div>
            <div style="font-size: 11px; color: var(--text-secondary); font-weight: 700; text-transform: uppercase;">Transacciones Realizadas</div>
            <div style="font-size: 20px; font-weight: 800; color: var(--success);">{{ $totalPayments }}</div>
        </div>
        <span style="font-size: 24px;">🧾</span>
    </div>
</div>

<!-- Interactive Financial Charts Section -->
<div style="display: grid; grid-template-columns: 2fr 1fr; gap: 20px; margin-bottom: 24px;">
    <!-- Chart 1: Cobros vs Desembolsos -->
    <div class="panel-box" style="margin-bottom: 0;">
        <div class="panel-header">
            <div>
                <h2 class="panel-title">📈 Evolución de Cobros vs Desembolsos</h2>
                <div style="font-size: 12px; color: var(--text-secondary);">Comparativa mensual de dinero recabado vs prestado</div>
            </div>
        </div>
        <div style="height: 280px; position: relative;">
            <canvas id="financialChart"></canvas>
        </div>
    </div>

    <!-- Chart 2: Estado de Cartera -->
    <div class="panel-box" style="margin-bottom: 0;">
        <div class="panel-header">
            <div>
                <h2 class="panel-title">🎯 Distribución de Cartera</h2>
                <div style="font-size: 12px; color: var(--text-secondary);">Estado de préstamos en sistema</div>
            </div>
        </div>
        <div style="height: 240px; display: flex; align-items: center; justify-content: center; position: relative;">
            <canvas id="portfolioDoughnutChart"></canvas>
        </div>
        <div style="display: flex; justify-content: space-around; margin-top: 10px; font-size: 11.5px; font-weight: 600;">
            <span style="color: var(--primary);">🟢 Al Día ({{ $activeLoansCount }})</span>
            <span style="color: var(--danger);">🔴 En Mora ({{ $overdueLoansCount }})</span>
            <span style="color: var(--success);">🔵 Pagados ({{ $paidLoansCount }})</span>
        </div>
    </div>
</div>

<!-- Collector Activity & Direct Control -->
<div style="display: grid; grid-template-columns: 1.5fr 1fr; gap: 20px;">
    <!-- Feed de Actividad Reciente de Cobradores -->
    <div class="panel-box">
        <div class="panel-header">
            <h2 class="panel-title">⚡ Actividad Reciente de Cobradores y Clientes</h2>
            <span style="font-size: 11px; background: #EEF3F0; color: var(--primary); padding: 4px 10px; border-radius: 12px; font-weight: 700;">● Monitoreo en Vivo</span>
        </div>
        
        <div style="display: flex; flex-direction: column; gap: 14px;">
            @foreach($recentActivities as $act)
            <div style="display: flex; align-items: center; justify-content: space-between; padding-bottom: 12px; border-bottom: 1px solid var(--border-color);">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 38px; height: 38px; border-radius: 10px; background-color: var(--primary-hover); display: flex; align-items: center; justify-content: center; font-size: 18px;">
                        @if($act['type'] == 'payment') 💵
                        @elseif($act['type'] == 'loan') 💳
                        @elseif($act['type'] == 'mora') ⚠️
                        @elseif($act['type'] == 'customer') 👤
                        @else ✅
                        @endif
                    </div>
                    <div>
                        <div style="font-size: 13.5px; font-weight: 600; color: var(--text-main);">{{ $act['action'] }}</div>
                        <div style="font-size: 11.5px; color: var(--text-secondary);">Usuario / Cobrador: <strong>{{ $act['user'] }}</strong></div>
                    </div>
                </div>
                <span style="font-size: 11px; color: var(--text-secondary); background: var(--bg-main); padding: 4px 8px; border-radius: 6px;">{{ $act['time'] }}</span>
            </div>
            @endforeach
        </div>
    </div>

    <!-- Quick Operations & User Control -->
    <div class="panel-box">
        <div class="panel-header">
            <h2 class="panel-title">⚡ Control Directo de Operación</h2>
        </div>
        <div style="display: flex; flex-direction: column; gap: 12px;">
            <a href="{{ route('admin.customers') }}" class="btn-primary" style="justify-content: center; padding: 12px;">
                👤 Ver y Registrar Clientes
            </a>
            <a href="{{ route('admin.lenders') }}" class="btn-secondary" style="text-align: center; padding: 12px;">
                👔 Control de Cobradores / Prestamistas
            </a>
            <a href="{{ route('admin.loans') }}" class="btn-secondary" style="text-align: center; padding: 12px;">
                💳 Ver y Desembolsar Préstamos
            </a>
            <a href="{{ route('admin.payments') }}" class="btn-secondary" style="text-align: center; padding: 12px;">
                💵 Control de Cobros y Recibos
            </a>
        </div>
    </div>
</div>

@endsection

@section('scripts')
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Line Chart: Cobros vs Desembolsos
        const ctxFinancial = document.getElementById('financialChart').getContext('2d');
        new Chart(ctxFinancial, {
            type: 'line',
            data: {
                labels: {!! json_encode($chartLabels) !!},
                datasets: [
                    {
                        label: 'Dinero Cobrado (RD$)',
                        data: {!! json_encode($chartCollected) !!},
                        borderColor: '#10B981',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 3,
                        pointRadius: 4,
                        pointHoverRadius: 6
                    },
                    {
                        label: 'Dinero Desembolsado (RD$)',
                        data: {!! json_encode($chartDisbursed) !!},
                        borderColor: '#19352C',
                        backgroundColor: 'rgba(25, 53, 44, 0.05)',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 2,
                        borderDash: [5, 5],
                        pointRadius: 3
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'top' },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return context.dataset.label + ': RD$ ' + context.raw.toLocaleString('es-DO', {minimumFractionDigits: 2});
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            callback: function(value) {
                                return 'RD$ ' + value.toLocaleString();
                            }
                        }
                    }
                }
            }
        });

        // Doughnut Chart: Estado de Cartera
        const ctxDoughnut = document.getElementById('portfolioDoughnutChart').getContext('2d');
        new Chart(ctxDoughnut, {
            type: 'doughnut',
            data: {
                labels: ['Al Día', 'En Mora', 'Pagados'],
                datasets: [{
                    data: [{{ $activeLoansCount }}, {{ $overdueLoansCount }}, {{ $paidLoansCount }}],
                    backgroundColor: ['#19352C', '#EF4444', '#10B981'],
                    borderWidth: 2,
                    borderColor: '#FFFFFF'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                cutout: '70%'
            }
        });
    });
</script>
@endsection
