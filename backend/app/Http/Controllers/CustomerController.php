<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Services\AuditService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $query = Customer::withCount(['loans as active_loans_count' => function ($q) {
            $q->whereIn('status', ['active', 'overdue']);
        }]);

        $user = auth()->user();
        $isAdmin = $user && ($user->role_id == 1 || str_contains(strtolower($user->email ?? ''), 'admin'));
        if (!$isAdmin && auth()->id()) {
            $query->where('creator_id', auth()->id());
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%{$search}%")
                  ->orWhere('last_name', 'like', "%{$search}%")
                  ->orWhere('identity_document', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $customers = $query->latest()->get();

        return response()->json($customers);
    }


    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'identity_document' => 'required|string',
            'phone' => 'required|string|max:20',
            'whatsapp' => 'nullable|string|max:20',
            'email' => 'nullable|email',
            'address' => 'nullable|string',
            'city' => 'nullable|string',
            'salary' => 'nullable|numeric',
            'identity_document_front' => 'nullable|string',
            'identity_document_back' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();
        $user = auth('sanctum')->user() ?? auth()->user();
        $data['creator_id'] = $user ? $user->id : (auth()->id() ?? 1);
        $data['address'] = $data['address'] ?? 'No especificada';

        $customer = Customer::updateOrCreate(
            ['identity_document' => $data['identity_document']],
            $data
        );

        return response()->json($customer, 201);
    }



    public function show($id)
    {
        $customer = Customer::with(['loans.installments', 'payments', 'documents', 'references'])->find($id);
        if (!$customer) {
            return response()->json(['message' => 'Customer not found'], 404);
        }
        return response()->json($customer);
    }

    public function update(Request $request, $id)
    {
        $customer = Customer::find($id);
        if (!$customer) {
            return response()->json(['message' => 'Customer not found'], 404);
        }

        $oldData = $customer->toArray();

        $customer->update($request->only([
            'first_name', 'last_name', 'phone', 'whatsapp', 'email', 'address', 'city', 'salary', 'notes', 'status',
            'identity_document_front', 'identity_document_back'
        ]));

        return response()->json($customer);
    }
}
