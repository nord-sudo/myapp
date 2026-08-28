<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Panel Administrativo') - Prestamistas Pro RD</title>
    <!-- Google Fonts Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Chart.js for Financial Graphs -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        :root {
            --bg-main: #F7F7F5;
            --sidebar-bg: #FFFFFF;
            --text-main: #1F1F1D;
            --text-secondary: #777773;
            --border-color: #E7E7E3;
            --primary: #19352C;
            --primary-hover: #EEF3F0;
            --white: #FFFFFF;
            --success: #10B981;
            --warning: #F59E0B;
            --danger: #EF4444;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        }

        body {
            background-color: var(--bg-main);
            color: var(--text-main);
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar Styles */
        .sidebar {
            width: 250px;
            background-color: var(--sidebar-bg);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            padding: 20px 14px;
            position: fixed;
            height: 100vh;
            overflow-y: auto;
            z-index: 100;
        }

        .sidebar-brand {
            font-size: 18px;
            font-weight: 800;
            color: var(--primary);
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 8px 20px 8px;
            border-bottom: 1px solid var(--border-color);
            margin-bottom: 20px;
            letter-spacing: -0.3px;
        }

        .sidebar-group {
            margin-bottom: 20px;
        }

        .sidebar-group-title {
            font-size: 10px;
            font-weight: 700;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.8px;
            padding: 0 10px 8px 10px;
        }

        .sidebar-menu {
            list-style: none;
            display: flex;
            flex-direction: column;
            gap: 3px;
        }

        .sidebar-link {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 12px;
            color: var(--text-main);
            text-decoration: none;
            border-radius: 8px;
            font-weight: 500;
            font-size: 13.5px;
            transition: all 0.15s ease;
        }

        .sidebar-link:hover {
            background-color: var(--primary-hover);
            color: var(--primary);
        }

        .sidebar-link.active {
            background-color: var(--primary);
            color: var(--white);
        }

        /* Main Area */
        .main-wrapper {
            margin-left: 250px;
            flex: 1;
            display: flex;
            flex-direction: column;
        }

        .top-navbar {
            background-color: var(--white);
            border-bottom: 1px solid var(--border-color);
            padding: 14px 28px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 90;
        }

        .navbar-left {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .search-box {
            position: relative;
            width: 280px;
        }

        .search-box input {
            width: 100%;
            padding: 8px 12px 8px 36px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            background-color: var(--bg-main);
            font-size: 13px;
        }

        .search-box icon {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-secondary);
        }

        .navbar-right {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .user-profile {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            font-weight: 600;
            color: var(--text-main);
            cursor: pointer;
        }

        .avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: var(--primary);
            color: var(--white);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 12px;
        }

        .content-body {
            padding: 28px;
            flex: 1;
        }

        /* Utility Components */
        .grid-3 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 18px;
            margin-bottom: 24px;
        }

        .card-metric {
            background-color: var(--white);
            padding: 20px;
            border-radius: 12px;
            border: 1px solid var(--border-color);
        }

        .metric-title {
            font-size: 11px;
            color: var(--text-secondary);
            font-weight: 700;
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .metric-value {
            font-size: 22px;
            font-weight: 800;
            color: var(--text-main);
        }

        .metric-value.primary { color: var(--primary); }
        .metric-value.success { color: var(--success); }
        .metric-value.danger { color: var(--danger); }

        .panel-box {
            background-color: var(--white);
            border-radius: 12px;
            border: 1px solid var(--border-color);
            padding: 20px;
            margin-bottom: 20px;
        }

        .panel-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
        }

        .panel-title {
            font-size: 15px;
            font-weight: 700;
            color: var(--text-main);
        }

        .table-custom {
            width: 100%;
            border-collapse: collapse;
        }

        .table-custom th {
            text-align: left;
            padding: 10px 14px;
            font-size: 11px;
            color: var(--text-secondary);
            font-weight: 700;
            border-bottom: 1px solid var(--border-color);
            background-color: var(--bg-main);
            text-transform: uppercase;
        }

        .table-custom td {
            padding: 14px;
            font-size: 13px;
            border-bottom: 1px solid var(--border-color);
        }

        .btn-primary {
            background-color: var(--primary);
            color: var(--white);
            padding: 9px 16px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 13px;
            border: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .btn-primary:hover { background-color: #122821; }

        .btn-secondary {
            background-color: var(--white);
            border: 1px solid var(--border-color);
            color: var(--text-main);
            padding: 8px 14px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 13px;
        }

        .pill-status {
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            display: inline-block;
        }

        .pill-status.success { background-color: #EEF7F2; color: var(--success); }
        .pill-status.danger { background-color: #FDF2F2; color: var(--danger); }
        .pill-status.active { background-color: var(--primary-hover); color: var(--primary); }

        .alert-success {
            background-color: #EEF7F2;
            color: var(--primary);
            border: 1px solid var(--primary);
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 13px;
            font-weight: 600;
        }
    </style>
    @yield('styles')
</head>
<body>

    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-brand">
            🏛️ Financiera <span>PRO</span>
        </div>

        <div class="sidebar-group">
            <div class="sidebar-group-title">Operación</div>
            <ul class="sidebar-menu">
                <li>
                    <a href="{{ route('admin.dashboard') }}" class="sidebar-link {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                        📊 Inicio
                    </a>
                </li>
                <li>
                    <a href="{{ route('admin.customers') }}" class="sidebar-link {{ request()->routeIs('admin.customers*') ? 'active' : '' }}">
                        👥 Clientes
                    </a>
                </li>
                <li>
                    <a href="{{ route('admin.lenders') }}" class="sidebar-link {{ request()->routeIs('admin.lenders*') ? 'active' : '' }}">
                        👔 Prestamistas
                    </a>
                </li>
                <li>
                    <a href="{{ route('admin.loans') }}" class="sidebar-link {{ request()->routeIs('admin.loans*') ? 'active' : '' }}">
                        💳 Préstamos
                    </a>
                </li>
                <li>
                    <a href="{{ route('admin.payments') }}" class="sidebar-link {{ request()->routeIs('admin.payments*') ? 'active' : '' }}">
                        💵 Pagos & Recibos
                    </a>
                </li>
            </ul>
        </div>

        <div class="sidebar-group">
            <div class="sidebar-group-title">Información</div>
            <ul class="sidebar-menu">
                <li>
                    <a href="{{ route('admin.audit') }}" class="sidebar-link {{ request()->routeIs('admin.audit*') ? 'active' : '' }}">
                        📈 Reportes
                    </a>
                </li>
            </ul>
        </div>

        <div class="sidebar-group">
            <div class="sidebar-group-title">Administración</div>
            <ul class="sidebar-menu">
                <li>
                    <a href="{{ route('admin.audit') }}" class="sidebar-link">
                        🛡️ Auditoría
                    </a>
                </li>
                <li>
                    <a href="{{ route('admin.settings') }}" class="sidebar-link {{ request()->routeIs('admin.settings*') ? 'active' : '' }}">
                        ⚙️ Configuración
                    </a>
                </li>
            </ul>
        </div>
    </aside>

    <!-- Main Wrapper -->
    <div class="main-wrapper">
        <header class="top-navbar">
            <div class="navbar-left">
                <div class="search-box">
                    <input type="text" placeholder="Buscar clientes, cédulas o préstamos...">
                </div>
            </div>
            <div class="navbar-right">
                <div class="user-profile">
                    <div class="avatar">AD</div>
                    <span>Carlos (Admin)</span>
                </div>
            </div>
        </header>

        <main class="content-body">
            @if(session('success'))
                <div class="alert-success">
                    ✅ {{ session('success') }}
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    @yield('scripts')
</body>
</html>
