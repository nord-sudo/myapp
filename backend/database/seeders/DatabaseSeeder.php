<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed default users for the Prestamistas Pro system.
     * Adapts to the exact 'forge' database schema (no uuid on customers/users).
     */
    public function run()
    {
        // 1. Admin user
        $admin = User::firstOrCreate(
            ['email' => 'admin@prestamistas.com'],
            [
                'name'     => 'Administrador General',
                'password' => Hash::make('admin123'),
                'status'   => 'active',
            ]
        );

        // 2. Cobrador user
        User::firstOrCreate(
            ['email' => 'carlos@prestamistas.com'],
            [
                'name'     => 'Carlos Morel (Cobrador)',
                'password' => Hash::make('123456'),
                'status'   => 'active',
            ]
        );

        // 3. Sample Dominican clients (only if table is empty)
        $count = DB::table('customers')->count();
        if ($count === 0) {
            $adminId = $admin->id;

            DB::table('customers')->insert([
                [
                    'creator_id'        => $adminId,
                    'first_name'        => 'Juan',
                    'last_name'         => 'Pérez',
                    'identity_document' => '0011234567',
                    'phone'             => '8095550192',
                    'address'           => 'Av. 27 de Febrero #45',
                    'city'              => 'Santo Domingo',
                    'salary'            => 35000.00,
                    'status'            => 'active',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ],
                [
                    'creator_id'        => $adminId,
                    'first_name'        => 'María',
                    'last_name'         => 'Rodríguez',
                    'identity_document' => '0029876543',
                    'phone'             => '8295550841',
                    'address'           => 'Calle El Sol #12',
                    'city'              => 'Santiago',
                    'salary'            => 48000.00,
                    'status'            => 'active',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ],
                [
                    'creator_id'        => $adminId,
                    'first_name'        => 'Carlos',
                    'last_name'         => 'Marte',
                    'identity_document' => '0031122334',
                    'phone'             => '8495550310',
                    'address'           => 'Calle Duarte #88, Los Alcarrizos',
                    'city'              => 'Santo Domingo Oeste',
                    'salary'            => 28000.00,
                    'status'            => 'active',
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ],
            ]);
        }
    }
}
