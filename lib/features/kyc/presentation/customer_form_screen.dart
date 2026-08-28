import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/document_cache_service.dart';


class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({Key? key}) : super(key: key);

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();

  String _selectedCity = 'Santo Domingo';
  bool _isLoading = false;

  // Document photo paths (Frente y Reverso)
  String? _frontIdPath;
  String? _backIdPath;

  final ImagePicker _picker = ImagePicker();

  final List<String> _dominicanCities = [
    'Santo Domingo',
    'Santiago de los Caballeros',
    'San Cristóbal',
    'La Vega',
    'San Pedro de Macorís',
    'La Romana',
    'Puerto Plata',
    'Moca',
    'Bonao',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  /// Displays modal options: Camera, Gallery, Device Storage
  Future<void> _showImagePickerSourceSheet(bool isFront) async {
    final title = isFront ? 'Frente de la Cédula' : 'Reverso de la Cédula';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Adjuntar $title',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona cómo deseas cargar la foto del documento de identidad:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
                ),
                title: const Text('Tomar Foto con la Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capturar directamente el documento en vivo con la cámara', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isFront, ImageSource.camera);
                },
              ),
              const Divider(height: 1),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.success),
                ),
                title: const Text('Seleccionar de la Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Elegir una foto existente desde tu galería de fotos', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isFront, ImageSource.gallery);
                },
              ),
              const Divider(height: 1),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
                ),
                title: const Text('Subir Documento desde el Dispositivo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Explorar archivos y almacenamiento del dispositivo', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isFront, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Lightweight image compression
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (photo != null) {
        // Save image to local device storage folder first (instant local availability)
        final String savedLocalPath = await DocumentCacheService.saveDocumentLocally(
          photo,
          prefix: isFront ? 'id_front' : 'id_back',
        );

        setState(() {
          if (isFront) {
            _frontIdPath = savedLocalPath;
          } else {
            _backIdPath = savedLocalPath;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la imagen: $e')),
      );
    }
  }

  void _showImageZoomDialog(String title, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: kIsWeb || path.startsWith('http')
                    ? Image.network(path, fit: BoxFit.contain)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCardUploader({
    required String title,
    required String subtitle,
    required String? path,
    required bool isFront,
  }) {
    final bool hasImage = path != null && path.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? AppColors.success.withOpacity(0.5) : Colors.grey.shade300,
          width: hasImage ? 1.5 : 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasImage ? Icons.check_circle_rounded : Icons.badge_rounded,
                    color: hasImage ? AppColors.success : AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✅ Guardado Local',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                    ),
                    child: kIsWeb || path.startsWith('http')
                        ? Image.network(path, fit: BoxFit.cover)
                        : Image.file(File(path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_rounded, size: 16, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: () => _showImageZoomDialog(title, path),
                        tooltip: 'Ver foto completa',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showImagePickerSourceSheet(isFront),
                    icon: const Icon(Icons.published_with_changes_rounded, size: 16, color: AppColors.accent),
                    label: const Text('Reemplazar Imagen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isFront) {
                        _frontIdPath = null;
                      } else {
                        _backIdPath = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                  tooltip: 'Eliminar foto',
                ),
              ],
            ),
          ] else ...[
            InkWell(
              onTap: () => _showImagePickerSourceSheet(isFront),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3), style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_rounded, color: AppColors.accent, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para adjuntar foto ($title)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                    const SizedBox(height: 2),
                    const Text('Guardado rápido local sin sobrecargar el servidor', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'identity_document': _cedulaController.text.trim(),
      'identity_document_front': _frontIdPath,
      'identity_document_back': _backIdPath,
      'has_id_documents': (_frontIdPath != null || _backIdPath != null),
      'phone': _phoneController.text.trim(),
      'whatsapp': _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : _phoneController.text.trim(),
      'city': _selectedCity,
      'address': _addressController.text.trim(),
      'salary': double.tryParse(_salaryController.text) ?? 0.0,
    };

    // Save customer locally in ApiService & sync to server
    final result = await ApiService.createCustomer(payload);
    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cliente y documentos de identidad guardados correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Registrar Nuevo Cliente'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Salir',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        labelText: 'Nombres *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  labelText: 'Número de Cédula *',
                  hintText: '00100000000',
                  prefixIcon: Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el número de cédula';
                  if (v.replaceAll(RegExp(r'\D'), '').length != 11) return 'La cédula debe tener 11 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Documento de Identidad (Fotos Frente y Reverso) ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_camera_front_rounded, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Documento de Identidad (Cédula)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adjunta las fotos legibles del frente y reverso del documento.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Frente
                    _buildIdCardUploader(
                      title: 'Frente de la Cédula',
                      subtitle: 'Foto de la parte frontal donde aparece el rostro y datos',
                      path: _frontIdPath,
                      isFront: true,
                    ),
                    const SizedBox(height: 12),

                    // Reverso
                    _buildIdCardUploader(
                      title: 'Reverso de la Cédula',
                      subtitle: 'Foto de la parte posterior con código y sello',
                      path: _backIdPath,
                      isFront: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono *',
                        hintText: '809-555-0000',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp',
                        hintText: '829-555-0000',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: const InputDecoration(
                  labelText: 'Ciudad / Provincia *',
                  prefixIcon: Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _dominicanCities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCity = val!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dirección completa *',
                  prefixIcon: Icon(Icons.home_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese la dirección' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  labelText: 'Sueldo o Ingreso Mensual (RD\$)',
                  prefixText: 'RD\$ ',
                  prefixIcon: Icon(Icons.monetization_on_rounded),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Guardar Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
