import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/models/location_model.dart';
import '../../core/models/time_slot_model.dart';
import './widgets/datetime_picker_section.dart';
import './widgets/description_input.dart';
import './widgets/location_section.dart';
import './widgets/service_category_selector.dart';

/// Create Request Screen - Comprehensive service request creation matching requested design
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  LatLng? _currentLocation;
  String? _address;
  String? _locationLabel;
  List<TimeSlotCandidate> _selectedTimeSlots = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _serviceCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadServiceCategories();
    _loadDefaultAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSelectedCategory();
    });
  }

  void _checkForSelectedCategory() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final selectedCategoryEn = args['selectedCategory'] as String?;
      if (selectedCategoryEn != null && _serviceCategories.isNotEmpty) {
        final category = _serviceCategories.firstWhere(
          (cat) => cat['nameEn'] == selectedCategoryEn,
          orElse: () => {},
        );
        if (category.isNotEmpty) {
          setState(() {
            _selectedCategory = category['name'];
          });
        }
      }
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final response = await _apiService.getAddresses();
      final List<dynamic> addresses = response['data'] ?? [];

      final defaultAddr = addresses.firstWhere(
        (a) => a['is_default'] == 1 || a['is_default'] == true,
        orElse: () => null,
      );

      if (defaultAddr != null && mounted) {
        setState(() {
          _locationLabel = defaultAddr['title'] ?? defaultAddr['label'];
          _address = defaultAddr['address_line'] ?? defaultAddr['address'];
          _currentLocation =
              LatLng(defaultAddr['latitude'], defaultAddr['longitude']);
        });
      }
    } catch (e) {
      debugPrint('Error loading default address: $e');
    }
  }

  Future<void> _loadServiceCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await _apiService.getServiceCategories();
      final categories = response['data'] as List<dynamic>?;

      if (categories != null) {
        final mappedCategories = categories.map<Map<String, dynamic>>((cat) {
          final category = cat as Map<String, dynamic>;
          final nameAr = category['name_ar'] as String? ?? '';
          final nameEn = category['name'] as String? ??
              category['name_en'] as String? ??
              '';
          final categoryName = nameAr.isNotEmpty ? nameAr : nameEn;

          return {
            'id': category['id'],
            'name': categoryName,
            'nameEn': nameEn, // Use English name for backend matching
            'icon': _getCategoryIcon(categoryName),
          };
        }).toList();

        if (mounted) {
          setState(() {
            _serviceCategories = mappedCategories;
            _isLoadingCategories = false;
          });
          _checkForSelectedCategory();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();
    if (name.contains('ستالايت') || name.contains('satellite'))
      return 'satellite';
    if (name.contains('أثاث')) return 'chair_alt';
    if (name.contains('طلاء') || name.contains('دهان')) return 'format_paint';
    if (name.contains('كهرب')) return 'electrical_services';
    if (name.contains('كمياء')) return 'science';
    if (name.contains('نجارة')) return 'construction';
    if (name.contains('سباكة')) return 'plumbing';
    if (name.contains('تكييف') || name.contains('تبريد') || name.contains('ac'))
      return 'ac_unit';
    if (name.contains('شبكات') || name.contains('network')) return 'router';
    if (name.contains('كاميرا') || name.contains('camera')) return 'videocam';
    if (name.contains('تنظيف') || name.contains('cleaning'))
      return 'cleaning_services';
    if (name.contains('نقل') || name.contains('shipping'))
      return 'local_shipping';
    return 'build';
  }

  void _navigateToManageAddresses() async {
    await Navigator.pushNamed(context, '/my-addresses-screen');
    _loadDefaultAddress();
  }

  Future<void> _submitRequest() async {
    if (_selectedCategory == null) {
      _showError('يرجى اختيار القسم');
      return;
    }
    if (_selectedTimeSlots.isEmpty) {
      _showError('يرجى اختيار موعد واحد على الأقل');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('يرجى وصف المشكلة');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // For now, we take the first slot as the scheduled_at for the API
      // In the future, the backend might handle multiple candidates
      final firstSlot = _selectedTimeSlots.first;
      final scheduledAt = DateTime(
        firstSlot.date.year,
        firstSlot.date.month,
        firstSlot.date.day,
        firstSlot.from.hour,
        firstSlot.from.minute,
      );

      // CRITICAL FIX: Send English name to backend for robust matching
      // The _selectedCategory contains the display name (possibly Arabic)
      String categoryToSend = _selectedCategory!;
      try {
        if (_serviceCategories.isNotEmpty) {
          final catObj = _serviceCategories.firstWhere(
            (c) => c['name'] == _selectedCategory,
            orElse: () => {},
          );
          if (catObj.isNotEmpty && catObj['nameEn'] != null) {
            categoryToSend = catObj['nameEn'];
          }
        }
      } catch (e) {
        // Fallback to selected category
      }

      await _apiService.createRequest(
        category: categoryToSend,
        description: _descriptionController.text.trim(),
        locationLat: _currentLocation?.latitude ?? 0,
        locationLng: _currentLocation?.longitude ?? 0,
        address: _address,
        scheduledAt: scheduledAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إرسال طلبك بنجاح'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('فشل إرسال الطلب: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
              iconName: 'close', color: theme.colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('طلب خدمة جديد',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Location Section
                    LocationSection(
                      currentLocation: _currentLocation,
                      address: _address,
                      label: _locationLabel,
                      isLoading: _isLoadingLocation,
                      onChangeLocation: _navigateToManageAddresses,
                    ),
                    const SizedBox(height: 24),

                    // 2. Category Section
                    ServiceCategorySelector(
                      selectedCategory: _selectedCategory,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      categories: _serviceCategories,
                    ),
                    const SizedBox(height: 24),

                    // 3. Time Slots Section
                    // DateTimePickerSection(
                    //   selectedSlots: _selectedTimeSlots,
                    //   onAddSlot: (slot) =>
                    //       setState(() => _selectedTimeSlots.add(slot)),
                    //   onRemoveSlot: (index) =>
                    //       setState(() => _selectedTimeSlots.removeAt(index)),
                    // ),
                    // const SizedBox(height: 24),

                    // 4. Description Section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'تفاصيل المشكلة',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DescriptionInput(
                      controller: _descriptionController,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'إرسال الطلب',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
