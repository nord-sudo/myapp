import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<dynamic> _customers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers([String? query]) async {
    setState(() => _isLoading = true);
    final data = await ApiService.getCustomers(search: query);
    if (mounted) {
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _openNewClientForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientFormScreen()),
    );
    _fetchCustomers();
  }

  void _showCustomerDocumentsSheet(Map<String, dynamic> customer) {
    String? frontPath = customer['identity_document_front'];
    String? backPath = customer['identity_document_back'];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickDoc(bool isFront, ImageSource src) async {
            try {
              final XFile? file = await picker.pickImage(source: src, imageQuality: 85);
              if (file != null) {
                final String docNum = '${customer['identity_document']}';
                setModalState(() {
                  if (isFront) {
                    frontPath = file.path;
                    customer['identity_document_front'] = file.path;
                    ApiService.updateCustomerDocument(docNum, frontPath: file.path);
                  } else {
                    backPath = file.path;
                    customer['identity_document_back'] = file.path;
                    ApiService.updateCustomerDocument(docNum, backPath: file.path);
                  }
                });
                setState(() {});
              }
            } catch (e) {
              CustomToast.show(context, 'Error al cargar imagen: $e', type: ToastType.error);
            }
          }

          void showPickerOptions(bool isFront) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Adjuntar Cédula', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                      ),
                      title: const Text('Tomar Foto con Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Capturar directamente el documento en vivo'),
                      onTap: () { Navigator.pop(context); pickDoc(isFront, ImageSource.camera); },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                      ),
                      title: const Text('Seleccionar de Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Elegir foto existente desde la galería'),
                      onTap: () { Navigator.pop(context); pickDoc(isFront, ImageSource.gallery); },
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cédula de ${customer['first_name']} ${customer['last_name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            Text(
                              'N° Cédula: ${CurrencyFormatter.formatCedula(customer['identity_document'] ?? '')}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 24),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildDocCard(
                    title: 'Frente de la Cédula',
                    path: frontPath,
                    onPick: () => showPickerOptions(true),
                    onDelete: () {
                      setModalState(() {
                        frontPath = null;
                        customer['identity_document_front'] = null;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildDocCard(
                    title: 'Reverso de la Cédula',
                    path: backPath,
                    onPick: () => showPickerOptions(false),
                    onDelete: () {
                      setModalState(() {
                        backPath = null;
                        customer['identity_document_back'] = null;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar Documento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _renderDocImage(String path) {
    if (path.startsWith('data:image') || path.length > 500) {
      final String base64Str = path.contains(',') ? path.split(',').last : path;
      return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
    } else if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
      return const Center(child: Icon(Icons.badge_rounded, size: 36, color: AppColors.primary));
    }
  }

  Widget _buildDocCard({
    required String title,
    required String? path,
    required VoidCallback onPick,
    required VoidCallback onDelete,
  }) {
    final bool hasImage = path != null && path.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasImage ? AppColors.success.withOpacity(0.5) : Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Cargado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.black12,
                child: _renderDocImage(path),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: onPick,
                    icon: const Icon(Icons.published_with_changes_rounded, size: 15, color: AppColors.primary),
                    label: const Text('Reemplazar', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.dangerBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  tooltip: 'Eliminar foto',
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPick,
              icon: const Icon(Icons.add_a_photo_rounded, size: 18, color: AppColors.primary),
              label: Text('Adjuntar $title', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  void _showContactOptions(Map<String, dynamic> customer) {
    final String name = '${customer['first_name']} ${customer['last_name']}';
    final String phone = customer['phone'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Tel: $phone', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_rounded, color: Colors.green),
              ),
              title: const Text('Enviar WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Abrir chat directo con el cliente'),
              onTap: () {
                Navigator.pop(ctx);
                CustomToast.show(context, 'Abriendo WhatsApp para $phone...', type: ToastType.info);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.phone_rounded, color: Colors.blue),
              ),
              title: const Text('Llamada Telefónica', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Llamar al número de teléfono'),
              onTap: () {
                Navigator.pop(ctx);
                CustomToast.show(context, 'Llamando a $phone...', type: ToastType.info);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mis Clientes',
        subtitle: 'Gestión y Expedientes KYC',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
            tooltip: 'Nuevo Cliente',
            onPressed: _openNewClientForm,
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openNewClientForm,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // ─── Search Bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _fetchCustomers(val),
              decoration: InputDecoration(
                hintText: 'Buscar por Nombre, Cédula o Teléfono...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchCustomers();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ─── Client List with Slidable actions ───────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('No se encontraron clientes', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text('Presiona + para registrar a tu primer cliente', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCustomers,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            final int id = int.tryParse('${customer['id']}') ?? 0;
                            final String first = (customer['first_name'] ?? 'C').toString();
                            final String last = (customer['last_name'] ?? '').toString();
                            final String fullName = '$first $last'.trim();
                            final String initials = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
                            final String cedula = customer['identity_document'] ?? '';
                            final String city = customer['city'] ?? customer['address'] ?? 'Santo Domingo';
                            final String phone = customer['phone'] ?? '';
                            final bool hasDoc = (customer['identity_document_front'] != null && customer['identity_document_front'].toString().isNotEmpty) ||
                                                (customer['identity_document_back'] != null && customer['identity_document_back'].toString().isNotEmpty);
                            final bool isOverdue = (customer['active_loans_count'] ?? 0) > 0 && customer['status'] == 'overdue';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Slidable(
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) => context.go('/payment?clientId=$id'),
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      icon: Icons.attach_money_rounded,
                                      label: 'Cobrar',
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                    ),
                                    SlidableAction(
                                      onPressed: (context) => _showContactOptions(customer),
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      icon: Icons.phone_rounded,
                                      label: 'Contactar',
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => context.go('/clients/$id'),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: AppColors.softShadow,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFFF1F5F9),
                                            child: Text(
                                              initials.isNotEmpty ? initials : 'CL',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        fullName.isNotEmpty ? fullName : 'Cliente sin nombre',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isOverdue ? AppColors.dangerBg : AppColors.successBg,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        isOverdue ? 'En mora' : 'Al día',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: isOverdue ? AppColors.danger : AppColors.success,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Cédula: ${CurrencyFormatter.formatCedula(cedula)}',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFEF4444)),
                                                    const SizedBox(width: 2),
                                                    Flexible(
                                                      child: Text(
                                                        city,
                                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      phone,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                InkWell(
                                                  onTap: () => _showCustomerDocumentsSheet(customer),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: hasDoc ? AppColors.successBg : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: hasDoc ? AppColors.success : Colors.grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          hasDoc ? Icons.badge_rounded : Icons.camera_alt_rounded,
                                                          size: 13,
                                                          color: hasDoc ? AppColors.success : const Color(0xFF475569),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          hasDoc ? 'Cédula Cargada' : 'Adjuntar Cédula',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: hasDoc ? AppColors.success : const Color(0xFF475569),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Préstamos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              break;
            case 2:
              context.go('/loans');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}
