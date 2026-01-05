import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAddresses();
      // API returns: {success: true, data: [...]}
      final List<dynamic> data = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _addresses = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل العناوين: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAddAddress() async {
    final result = await Navigator.pushNamed(context, AppRoutes.mapPicker);

    if (result != null && result is Map<String, dynamic>) {
      _saveAddress(result);
    }
  }

  Future<void> _saveAddress(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.createAddress(
        address: data['address'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        label: data['label'],
        isDefault: _addresses.isEmpty, // Set as default if it's the first one
      );
      _loadAddresses(); // Refresh list
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ العنوان: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateAddress(
        addressId: addressId,
        isDefault: true,
      );
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تعيين العنوان كافتراضي: $e')),
        );
      }
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا العنوان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteAddress(addressId);
        _loadAddresses();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حذف العنوان: $e')),
          );
        }
      }
    }
  }

  Future<void> _editAddress(Map<String, dynamic> address) async {
    final result = await Navigator.pushNamed(
      context,
      '/map-picker-screen',
      arguments: {
        'id': address['id'],
        'latitude': address['latitude'],
        'longitude': address['longitude'],
        'address': address['address_line'] ?? address['address'],
        'label': address['title'],
        'isEditing': true,
      },
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() => _isLoading = true);
      try {
        await _apiService.updateAddress(
          addressId: address['id'],
          address: result['address'],
          latitude: result['latitude'],
          longitude: result['longitude'],
          label: result['label'],
        );
        _loadAddresses();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تحديث العنوان: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'عناويني',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading // Assuming _isLoadingUserData was a typo and _isLoading is intended
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  // Added SafeArea as per the instruction's snippet
                  child: RefreshIndicator(
                    onRefresh: _loadAddresses,
                    child: _addresses.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildAddressList(theme),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddAddress,
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text(
          'إضافة عنوان جديد',
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد عناوين محفوظة',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف عنوانك الأول لتسهيل عملية طلب الخدمة',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isDefault =
            address['is_default'] == 1 || address['is_default'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isDefault
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5)
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!isDefault) _setDefaultAddress(address['id']);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge (Top Left)
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'الافتراضي',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Spacer(),
                      // Info
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              address['title'] ?? 'عنوان بدون اسم',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address['address_line'] ??
                                  address['address'] ??
                                  '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Icon (Right)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDefault
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isDefault ? Icons.home_rounded : Icons.place_rounded,
                          color: isDefault
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _deleteAddress(address['id']),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'حذف',
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => _editAddress(address),
                        icon: Icon(Icons.edit_outlined,
                            color: theme.colorScheme.primary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'تعديل',
                      ),
                      const Spacer(),
                      if (!isDefault)
                        TextButton(
                          onPressed: () => _setDefaultAddress(address['id']),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'تعيين كافتراضي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
