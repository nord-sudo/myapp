# PrestaRD — Design System (v1)

Patrón visual de la app de gestión de préstamos (Flutter + Laravel). Este documento es la **fuente de verdad** para cualquier cambio de UI.

> ⚠️ **Regla AGENTS.md:** No rediseñar pantallas durante bug fixes. Aplicar el sistema solo cuando el usuario lo pida explícitamente, o cuando se esté creando una pantalla nueva.

---

## 🎨 1. Paleta de Colores (`lib/core/themes/app_colors.dart`)

| Token            | Hex       | Uso                                            |
| ---------------- | --------- | ---------------------------------------------- |
| `primary`        | `#19352C` | Forest Green. AppBar, CTAs primarios, texto.   |
| `accent`         | `#19352C` | Mismo valor que primary (alineado semánticamente). |
| `background`     | `#F7F7F5` | Scaffold background. Warm off-white.           |
| `cardBackground` | `#FFFFFF` | Cards, sheets, inputs.                         |
| `success`        | `#10B981` | Cobrado / Al día / pagado.                     |
| `warning`        | `#F59E0B` | Pendiente, parcial, atención.                  |
| `danger`         | `#EF4444` | En mora, error, eliminar.                      |
| `textPrimary`    | `#1F1F1D` | Títulos, números importantes.                  |
| `textSecondary`  | `#777773` | Subtítulos, labels.                            |
| `textMuted`      | `#A3A39E` | Metadata, hints, placeholders.                 |

**Reglas:**
- **Nunca** usar `Colors.green.shade*` / `Colors.red` / `Colors.blue.shade*` directamente en pantallas. Importar desde `AppColors`.
- Fondos de "estado" usan `color.withOpacity(0.08-0.15)` sobre `cardBackground`.
- Textos en estado: `color` puro (no blanco).

---

## ✍️ 2. Tipografía

Patrón **sans-serif** (Material default), sin fuentes custom.

| Estilo          | Tamaño | Peso        | Uso                                  |
| --------------- | ------ | ----------- | ------------------------------------ |
| Display         | 28     | bold        | Saldo total, totales de cartera      |
| H1              | 20-22  | bold        | Nombres de cliente, balance hero     |
| H2              | 17-18  | bold        | Títulos de pantalla / sheet          |
| H3              | 15-16  | bold        | Subtítulos de sección                |
| Body emphasis   | 14     | w600 / bold | Texto destacado, botones             |
| Body            | 13     | w500 / w600 | Texto general, valores en filas       |
| Caption         | 11-12  | w500 / w600 | Metadata, etiquetas de estado        |
| Tiny            | 9-10   | bold        | Chips de badge (`PAGADO`, `MORA`)    |

---

## 📐 3. Espaciado & Radios

```
Espaciado estándar:    4, 8, 12, 16, 20, 24, 28 px
Card radius:           16-18 px  (cards en lista / stat cards)
Card radius input:     12 px     (text fields, dropdowns)
Button radius:         14 px     (botones principales)
Sheet radius (top):    28 px     (modal bottom sheets)
Badge radius:          4-12 px   (chips según jerarquía)
Padding de página:     16 px
Padding de card:       14-18 px
```

**Grid / layouts:** Usar `Row` + `Expanded` para 2 columnas. `GridView.count` con `crossAxisCount: 2` + `childAspectRatio: 1.5` para stats.

---

## 🌫️ 4. Sombras (`AppColors.softShadow`)

```dart
static List<BoxShadow> softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];
```

Aplicar a: cards, hero cards de balance, bottom sheets (no a inputs ni chips).

---

## 🧱 5. Componentes Base (`lib/core/widgets/`)

| Widget           | Path                                  | Propósito                                   |
| ---------------- | ------------------------------------- | ------------------------------------------- |
| `GradientButton` | `gradient_button.dart`                | CTA con gradient verde + loading state      |
| `CustomAppBar`   | `custom_app_bar.dart`                 | AppBar Forest Green estandarizado           |
| `CustomToast`    | `custom_toast.dart`                   | SnackBar flotante con shape                 |
| `LoadingIndicator` | `loading_indicator.dart`            | Spinner centrado                            |

### 🎯 Componentes a crear (próxima fase)

| Widget              | Propósito                                          |
| ------------------- | -------------------------------------------------- |
| `StatusBadge`       | Chip pill (color + label) para estado de préstamo  |
| `MetricCard`        | Card con icono + label + valor                     |
| `SectionLabel`      | Header de sección con icono + texto bold           |
| `SoftCard`          | Container blanco con `AppColors.softShadow`        |
| `CurrencyText`      | Texto monetario formateado (RD$) con color         |
| `EmptyState`        | Placeholder cuando no hay datos                    |
| `GradientHeroCard` | Card hero con gradient (cartera total, balance)    |

---

## 📲 6. Pantallas — Estado actual

### ✅ Ya alineadas al sistema
- `CustomerFormScreen` (KYC) — usa `AppColors`, sections, date pickers, soft cards
- `LoanFormScreen` — usa AppColors, gradientes en headers, schedule list
- `LoanDetailScreen` — hero gradient, tabs, status colors
- `LoanListScreen` — header con gradient, tabs, FAB extendido
- `PaymentScreen`
- `ReceiptScreen`
- `PortfolioScreen`
- `AlertsScreen`

### ⚠️ Parcialmente alineadas (refactor pendiente)
- `DashboardScreen` (`features/dashboard/`) — usa colores hardcoded `Colors.green.shade800`, no `AppColors`
- `LoansScreen` (`features/loans/`) — usa colores hardcoded
- `LoginScreen` — usa colores hardcoded (login antiguo, menos prioritario)

### 🆕 Por crear / poblar
- `ClientDetailScreen` — solo placeholder, poblar con info de cliente + sus préstamos
- `ProfileScreen` / SettingsScreen — verificar implementación completa
- Dashboard nuevo y unificado (reemplazar versiones duplicadas)

---

## 🧭 7. Reglas de oro al diseñar UI nueva

1. **AppBar siempre `AppColors.primary`** con texto blanco bold, y `IconButton(Icons.close_rounded)` para salir.
2. **Background siempre `AppColors.background`** (`#F7F7F5`), no blanco puro ni gris.
3. **Cards blancas** con `BorderRadius.circular(16)` y `AppColors.softShadow`.
4. **Status colors semánticos**: success=al-día/cobrado, warning=pendiente/parcial, danger=mora/error.
5. **Bottom sheets** con `Radius.circular(28)` arriba + handle gris 4×40.
6. **Botones primarios**: `AppColors.accent` (primary green), bold, radius 14.
7. **Botones de éxito/cobro**: `AppColors.success`.
8. **Botones de peligro**: `AppColors.danger`.
9. **SnackBars**: floating, radius 10, fondo = color semántico.
10. **Iconografía**: usar `_rounded` variants (`Icons.attach_money_rounded`, `Icons.person_rounded`, etc.).
11. **Sin emojis en producción** (excepto en headers decorativos donde ya están ✅ ⚠️ ▶).
12. **Empty states**: icono grande (56px) en `textMuted.withOpacity(0.3)` + texto `textMuted` semibold.

---

## 🏗️ 8. Arquitectura del proyecto

```
lib/
├── core/                     # Theme, widgets, utils, constantes
│   ├── themes/app_colors.dart     ← Paleta canónica
│   ├── themes/app_theme.dart      ← ThemeData Material 3
│   └── widgets/                   ← Componentes reutilizables
├── features/
│   ├── auth/                # Login, splash, biometric lock
│   ├── dashboard/           # Home / KPIs
│   ├── clients/             # CRUD clientes + Clean Arch
│   ├── loans/               # CRUD préstamos + Clean Arch
│   ├── loan/                # Vista alternativa (legacy + KYC screens)
│   ├── kyc/                 # Customer form + list (offline-first)
│   ├── payments/            # Cobros
│   ├── profile/             # Perfil agente
│   └── settings/            # Ajustes
├── routes/                  # GoRouter
└── injection/               # GetIt + providers
```

> Hay duplicación intencional entre `features/loans` (Clean Arch con Bloc) y `features/loan` (pantallas conectadas a ApiService). Conviene unificar en el futuro.

---

## 🔗 9. Tipografía y patrón Money

```dart
// Formato consistente:
CurrencyFormatter.formatDOP(value); // → "RD$ 1,500.00"

// Color por estado:
- Cobrado / Al día / Pagado  → AppColors.success
- Pendiente / Parcial        → AppColors.warning  
- En mora / Error / Eliminar → AppColors.danger
- Activo / Capital / Default → AppColors.primary
```

---

> Última actualización: 2026-08-26. Mantener este doc vivo cuando se agreguen componentes o cambien tokens.
