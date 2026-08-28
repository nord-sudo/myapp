<?php

namespace App\Http\Controllers;

use App\Services\CreditCheckService;
use Illuminate\Http\Request;

class CreditCheckController extends Controller
{
    public function check(Request $request, CreditCheckService $creditService)
    {
        $request->validate([
            'identity_document' => 'required|string',
            'requested_amount' => 'nullable|numeric|min:0',
        ]);

        $result = $creditService->evaluateCredit(
            $request->identity_document,
            (float) ($request->requested_amount ?? 0)
        );

        return response()->json($result);
    }
}
