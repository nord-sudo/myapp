<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\FinancialLoan;
use App\Models\LoanInstallment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CreditCheckService
{
    /**
     * Perform Credit Risk Evaluation via External Bureau API (DataCrédito / TransUnion RD)
     * with automatic fallback to internal portfolio credit history.
     *
     * @param string $identityDocument
     * @param float $requestedAmount
     * @return array
     */
    public function evaluateCredit(string $identityDocument, float $requestedAmount = 0.0): array
    {
        $cleanCedula = preg_replace('/\D/', '', $identityDocument);

        // 1. If external DataCrédito / TransUnion API credentials are set in .env
        $apiKey = config('services.datacredito.api_key', env('DATACREDITO_API_KEY'));
        $apiUrl = config('services.datacredito.url', env('DATACREDITO_API_URL'));

        if (!empty($apiKey) && !empty($apiUrl)) {
            try {
                $response = Http::withHeaders([
                    'Authorization' => 'Bearer ' . $apiKey,
                    'Accept' => 'application/json',
                ])->timeout(5)->post($apiUrl, [
                    'cedula' => $cleanCedula,
                    'country' => 'DO',
                ]);

                if ($response->successful()) {
                    $bureauData = $response->json();
                    return $this->formatBureauResponse($bureauData, $identityDocument, $requestedAmount);
                }
            } catch (\Exception $e) {
                Log::warning("DataCrédito API timeout or unreachable: " . $e->getMessage());
            }
        }

        // 2. Default Internal Credit Engine Evaluation (Internal Portfolio History)
        return $this->evaluateInternalHistory($cleanCedula, $identityDocument, $requestedAmount);
    }

    /**
     * Format response from real DataCrédito / TransUnion API response
     */
    private function formatBureauResponse(array $data, string $cedula, float $requestedAmount): array
    {
        $score = $data['score'] ?? 650;
        $riskLevel = ($score >= 700) ? 'low' : (($score >= 580) ? 'medium' : 'high');
        $riskLabel = ($riskLevel === 'low') ? 'Bajo Riesgo (DataCrédito Aprobado)' : (($riskLevel === 'medium') ? 'Riesgo Medio (Garante Requerido)' : 'Alto Riesgo (Rechazado)');
        $maxApproved = round(($data['monthly_income'] ?? 35000) * 2.5, 2);

        return [
            'provider' => 'DataCrédito / TransUnion RD',
            'cedula' => $cedula,
            'customer_name' => $data['name'] ?? 'Consulta Buró R.D.',
            'credit_score' => $score,
            'risk_level' => $riskLevel,
            'risk_label' => $riskLabel,
            'risk_color' => ($riskLevel === 'low') ? '#10B981' : (($riskLevel === 'medium') ? '#F59E0B' : '#EF4444'),
            'max_approved_amount' => $maxApproved,
            'requested_amount' => $requestedAmount,
            'is_approved' => ($requestedAmount <= $maxApproved && $score >= 580),
            'recommendation' => "Puntuación oficial del buró: $score. Capacidad máxima estimada: RD$ " . number_format($maxApproved, 2),
        ];
    }

    /**
     * Internal Portfolio Credit Evaluation
     */
    private function evaluateInternalHistory(string $cleanCedula, string $identityDocument, float $requestedAmount): array
    {
        $customer = Customer::where('identity_document', 'like', "%{$cleanCedula}%")
                            ->orWhere('identity_document', $identityDocument)
                            ->first();

        $score = 710;
        $activeLoansCount = 0;
        $overdueCount = 0;
        $paidLoansCount = 0;
        $monthlyIncome = $customer->monthly_income ?? 35000.00;

        if ($customer) {
            $loans = FinancialLoan::where('customer_id', $customer->id)->get();
            foreach ($loans as $loan) {
                if ($loan->status === 'paid') {
                    $paidLoansCount++;
                    $score += 25;
                } elseif ($loan->status === 'overdue') {
                    $overdueCount++;
                    $score -= 85;
                } elseif ($loan->status === 'active') {
                    $activeLoansCount++;
                }
            }

            $overdueInstallments = LoanInstallment::whereIn('loan_id', $loans->pluck('id'))
                ->where('status', 'overdue')
                ->count();
            $score -= ($overdueInstallments * 15);
        }

        $score = max(300, min(850, $score));
        $riskLevel = ($score >= 680 && $overdueCount == 0) ? 'low' : (($score >= 550) ? 'medium' : 'high');
        $maxApprovedAmount = round($monthlyIncome * 2.2, 2);
        $isApproved = ($requestedAmount <= 0) ? ($score >= 600) : ($requestedAmount <= $maxApprovedAmount && $score >= 580);

        return [
            'provider' => 'Historial Interno de Cartera',
            'cedula' => $identityDocument,
            'customer_name' => $customer ? "{$customer->first_name} {$customer->last_name}" : 'Cliente Nuevo',
            'credit_score' => $score,
            'risk_level' => $riskLevel,
            'risk_label' => ($riskLevel === 'low') ? 'Bajo Riesgo - APROBADO' : (($riskLevel === 'medium') ? 'Riesgo Medio - REQUIERE GARANTE' : 'Alto Riesgo - RECHAZADO'),
            'risk_color' => ($riskLevel === 'low') ? '#10B981' : (($riskLevel === 'medium') ? '#F59E0B' : '#EF4444'),
            'max_approved_amount' => $maxApprovedAmount,
            'requested_amount' => $requestedAmount,
            'is_approved' => $isApproved,
            'active_loans' => $activeLoansCount,
            'overdue_loans' => $overdueCount,
            'paid_loans' => $paidLoansCount,
            'monthly_income' => $monthlyIncome,
            'recommendation' => $isApproved
                ? 'Historial de pago favorable. Préstamo aprobado.'
                : 'Monto solicitado excede la capacidad estimada o presenta atrasos activos.',
        ];
    }
}
