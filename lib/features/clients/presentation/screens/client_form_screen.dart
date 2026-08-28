import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/offline_sync_queue_manager.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_toast.dart';

class ClientFormScreen extends StatefulWidget {
  final Map<String, dynamic>? clientToEdit;

  const ClientFormScreen({super.key, this.clientToEdit});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String? _frontDocPath;
  String? _backDocPath;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.clientToEdit != null) {
      final c = widget.clientToEdit!;
      _firstNameController.text = c['first_name'] ?? '';
      _lastNameController.text = c['last_name'] ?? '';
      _cedulaController.text = c['identity_document'] ?? '';
      _phoneController.text = c['phone'] ?? '';
      _emailController.text = c['email'] ?? '';
      _addressController.text = c['address'] ?? c['city'] ?? '';
      _frontDocPath = c['identity_document_front'];
      _backDocPath = c['identity_document_back'];
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (photo != null) {
        setState(() {
          if (isFront) {
            _frontDocPath = photo.path;
          } else {
            _backDocPath = photo.path;
          }
        });
      }
    } catch (e) {
      CustomToast.show(context, 'Error al seleccionar imagen: $e', type: ToastType.error);
    }
  }

  void _showImagePickerSheet(bool isFront) {
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFront ? 'Foto Anverso de Cédula' : 'Foto Reverso de Cédula',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              ),
              title: const Text('Tomar Foto con Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Capturar directamente el documento en vivo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isFront, ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
              ),
              title: const Text('Seleccionar de Galería', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Elegir foto existente desde la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isFront, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderDocPreview(String path) {
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
      return const Center(child: Icon(Icons.badge_rounded, size: 40, color: AppColors.primary));
    }
  }

  Widget _buildKycCard({
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
        border: Border.all(
          color: hasImage ? AppColors.success.withOpacity(0.6) : Colors.grey.shade300,
          width: hasImage ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Cargado ✓',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 110,
                width: double.infinity,
                color: Colors.black12,
                child: _renderDocPreview(path),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onPick,
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                    label: const Text('Reemplazar', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.dangerBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onPick,
              icon: const Icon(Icons.add_a_photo_rounded, size: 16, color: AppColors.primary),
              label: Text('Adjuntar $title', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final String cedulaRaw = _cedulaController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (!CedulaValidator.validate(cedulaRaw)) {
      CustomToast.show(context, 'La Cédula Dominicana debe contener 11 dígitos', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      if (widget.clientToEdit != null) 'id': widget.clientToEdit!['id'],
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'identity_document': cedulaRaw,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Santo Domingo',
      'identity_document_front': _frontDocPath,
      'identity_document_back': _backDocPath,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save locally & queue for remote sync
    await ApiService.createCustomer(payload);
    OfflineSyncQueueManager.enqueue(type: SyncTaskType.createCustomer, payload: payload);

    setState(() => _isSubmitting = false);

    if (mounted) {
      CustomToast.show(
        context,
        widget.clientToEdit != null ? 'Cliente actualizado con éxito' : 'Cliente registrado con éxito',
        type: ToastType.success,
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        context.go('/clients');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.clientToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: isEditing ? 'Editar Cliente' : 'Nuevo Cliente',
        subtitle: 'KYC y Registro PrestaRD',
        onBackPressed: () => context.go('/clients'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Personal Data
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Datos Personales',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Nombres *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Apellidos *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Cédula Dominicana
                    TextFormField(
                      controller: _cedulaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cédula Dominicana (11 dígitos) *',
                        hintText: '001-0000000-0',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa la cédula';
                        final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                        if (clean.length != 11) return 'Debe contener 11 dígitos';
                        if (!CedulaValidator.validate(clean)) return 'Cédula inválida (dígito verificador incorrecto)';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Teléfono RD
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono / WhatsApp *',
                        hintText: '809-555-0199',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa el teléfono';
                        if (val.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Teléfono debe tener al menos 10 dígitos';
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Dirección
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Dirección de Residencia',
                        hintText: 'Calle, Sector, Ciudad',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Email (Opcional)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico (Opcional)',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: KYC Documentation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Documentación KYC (Cédula)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Captura fotos nítidas de la cédula del cliente para validación y archivo.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    _buildKycCard(
                      title: 'Cédula (Anverso / Frontal)',
                      path: _frontDocPath,
                      onPick: () => _showImagePickerSheet(true),
                      onDelete: () => setState(() => _frontDocPath = null),
                    ),
                    const SizedBox(height: 12),
                    _buildKycCard(
                      title: 'Cédula (Reverso / Trasera)',
                      path: _backDocPath,
                      onPick: () => _showImagePickerSheet(false),
                      onDelete: () => setState(() => _backDocPath = null),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.textMuted),
                      ),
                      onPressed: () => context.go('/clients'),
                      child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _handleSave,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, color: Colors.white),
                      label: Text(
                        isEditing ? 'Actualizar Cliente' : 'Guardar Cliente',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
