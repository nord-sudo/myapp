<?php

namespace App\Services;

use Carbon\Carbon;

class FinancialEngineService
{
    /**
     * Calculate loan amortization schedule accurately.
     *
     * @param float $amount
     * @param float $interestRate (percentage e.g. 20 for 20%)
     * @param int $termUnits
     * @param string $frequency (daily, weekly, biweekly, monthly)
     * @param string $startDate (YYYY-MM-DD)
     * @param string $interestType (fixed, declining_balance)
     * @return array
     */
    public function generateAmortizationSchedule(
        float $amount,
        float $interestRate,
        int $termUnits,
        string $frequency,
        string $startDate,
        string $interestType = 'fixed'
    ): array {
        $schedule = [];

        if ($interestType === 'declining_balance') {
            // French Amortization System (Saldo Insoluto)
            $ratePerPeriod = ($interestRate / 100);
            if ($frequency === 'monthly') {
                $ratePerPeriod = $ratePerPeriod / 12;
            } elseif ($frequency === 'weekly') {
                $ratePerPeriod = $ratePerPeriod / 52;
            } elseif ($frequency === 'biweekly') {
                $ratePerPeriod = $ratePerPeriod / 26;
            } else { // daily
                $ratePerPeriod = $ratePerPeriod / 365;
            }

            if ($ratePerPeriod > 0) {
                $installmentAmount = round($amount * ($ratePerPeriod * pow(1 + $ratePerPeriod, $termUnits)) / (pow(1 + $ratePerPeriod, $termUnits) - 1), 2);
            } else {
                $installmentAmount = round($amount / $termUnits, 2);
            }

            $remainingPrincipal = $amount;
            $currentDate = Carbon::parse($startDate);
            $totalInterest = 0;

            for ($i = 1; $i <= $termUnits; $i++) {
                $this->advanceDate($currentDate, $frequency);

                $iAmount = round($remainingPrincipal * $ratePerPeriod, 2);
                $pAmount = round($installmentAmount - $iAmount, 2);

                if ($i === $termUnits || $pAmount > $remainingPrincipal) {
                    $pAmount = round($remainingPrincipal, 2);
                    $tAmount = $pAmount + $iAmount;
                } else {
                    $tAmount = $installmentAmount;
                }

                $remainingPrincipal = round(max(0, $remainingPrincipal - $pAmount), 2);
                $totalInterest += $iAmount;

                $schedule[] = [
                    'installment_number' => $i,
                    'due_date'           => $currentDate->format('Y-m-d'),
                    'principal_amount'   => $pAmount,
                    'interest_amount'    => $iAmount,
                    'penalty_amount'     => 0.00,
                    'total_amount'       => $tAmount,
                    'status'             => 'pending',
                ];
            }

            $totalAmount = $amount + $totalInterest;
        } else {
            // Fixed Simple Interest
            $totalInterest = ($amount * ($interestRate / 100));
            $totalAmount = $amount + $totalInterest;
            $installmentAmount = round($totalAmount / $termUnits, 2);
            $principalPerInstallment = round($amount / $termUnits, 2);
            $interestPerInstallment = round($totalInterest / $termUnits, 2);

            $currentDate = Carbon::parse($startDate);
            $accumulatedPrincipal = 0;
            $accumulatedInterest = 0;

            for ($i = 1; $i <= $termUnits; $i++) {
                $this->advanceDate($currentDate, $frequency);

                if ($i === $termUnits) {
                    $pAmount = round($amount - $accumulatedPrincipal, 2);
                    $iAmount = round($totalInterest - $accumulatedInterest, 2);
                    $tAmount = $pAmount + $iAmount;
                } else {
                    $pAmount = $principalPerInstallment;
                    $iAmount = $interestPerInstallment;
                    $tAmount = $installmentAmount;
                }

                $accumulatedPrincipal += $pAmount;
                $accumulatedInterest += $iAmount;

                $schedule[] = [
                    'installment_number' => $i,
                    'due_date'           => $currentDate->format('Y-m-d'),
                    'principal_amount'   => $pAmount,
                    'interest_amount'    => $iAmount,
                    'penalty_amount'     => 0.00,
                    'total_amount'       => $tAmount,
                    'status'             => 'pending',
                ];
            }
        }

        return [
            'amount'         => round($amount, 2),
            'interest_rate'  => $interestRate,
            'interest_type'  => $interestType,
            'term_units'     => $termUnits,
            'frequency'      => $frequency,
            'total_interest' => round($totalInterest, 2),
            'total_amount'   => round($totalAmount, 2),
            'schedule'       => $schedule,
        ];
    }

    private function advanceDate(Carbon $currentDate, string $frequency): void
    {
        switch ($frequency) {
            case 'daily':
                $currentDate->addDay();
                if ($currentDate->isWeekend()) {
                    $currentDate->addDays($currentDate->isSaturday() ? 2 : 1);
                }
                break;
            case 'weekly':
                $currentDate->addWeek();
                break;
            case 'biweekly':
                $currentDate->addWeeks(2);
                break;
            case 'monthly':
                $currentDate->addMonth();
                break;
            default:
                $currentDate->addDay();
                break;
        }
    }

    /**
     * Calculate late payment fee/penalty for an overdue installment.
     * Rule: Daily penalty rate (e.g. 0.5% per day past due date).
     */
    public function calculateLatePenalty(array $installment, float $dailyPenaltyRate = 0.5): array
    {
        if (empty($installment['due_date']) || $installment['status'] === 'paid') {
            return ['days_overdue' => 0, 'penalty_amount' => 0.00];
        }

        $dueDate = Carbon::parse($installment['due_date']);
        $today = Carbon::today();

        if ($today->lte($dueDate)) {
            return ['days_overdue' => 0, 'penalty_amount' => 0.00];
        }

        $daysOverdue = $today->diffInDays($dueDate);
        $pendingAmount = ($installment['total_amount'] ?? 0) - ($installment['paid_amount'] ?? 0);
        $penalty = round($pendingAmount * ($dailyPenaltyRate / 100) * $daysOverdue, 2);

        return [
            'days_overdue'   => $daysOverdue,
            'penalty_amount' => max(0.00, $penalty),
        ];
    }

    /**
     * Calculate early payoff / settlement amount with interest discount rebate.
     */
    public function calculateEarlyPayoff(float $balanceRemaining, float $originalAmount, float $totalAmount, float $discountRate = 5.0): array
    {
        $interestPortion = max(0, $totalAmount - $originalAmount);
        $discountAmount = round($interestPortion * ($discountRate / 100), 2);
        $settlementAmount = max(0, round($balanceRemaining - $discountAmount, 2));

        return [
            'balance_remaining' => round($balanceRemaining, 2),
            'discount_rate'     => $discountRate,
            'discount_amount'   => $discountAmount,
            'settlement_amount' => $settlementAmount,
        ];
    }
}
