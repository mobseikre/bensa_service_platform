import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/password_strength_indicator.dart';
import './widgets/role_selection_widget.dart';
import './widgets/terms_checkbox_widget.dart';
import './widgets/service_categories_selector.dart';

/// Registration screen for new user account creation
/// Supports both customer and technician role selection
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  final _cityController = TextEditingController();
  final _nationalityController = TextEditingController();

  String _selectedRole = 'customer';
  bool _isPasswordVisible = false;
  bool _isPasswordConfirmationVisible = false;
  bool _termsAccepted = false;
  bool _isLoading = false;
  List<String> _selectedServiceCategories = [];

  final _apiService = ApiService();

  // Validation states
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _passwordConfirmationError;
  String? _cityError;
  String? _nationalityError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _cityController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    bool baseValid = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _passwordConfirmationController.text.trim().isNotEmpty &&
        _termsAccepted &&
        _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _passwordConfirmationError == null;

    if (_selectedRole == 'technician') {
      return baseValid &&
          _cityController.text.trim().isNotEmpty &&
          _nationalityController.text.trim().isNotEmpty &&
          _selectedServiceCategories.isNotEmpty &&
          _cityError == null &&
          _nationalityError == null;
    }

    return baseValid;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الاسم الكامل';
    }
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف يجب أن يكون 9 أرقام';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (_selectedRole != 'technician') return null;
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال المدينة';
    }
    if (value.trim().length > 100) {
      return 'اسم المدينة طويل جداً';
    }
    return null;
  }

  String? _validateNationality(String? value) {
    if (_selectedRole != 'technician') return null;
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال الجنسية';
    }
    if (value.trim().length > 100) {
      return 'اسم الجنسية طويل جداً';
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (!_isFormValid()) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == 'technician' && _selectedServiceCategories.isEmpty
                ? 'الرجاء اختيار خدمة واحدة على الأقل'
                : 'الرجاء إكمال جميع الحقول المطلوبة',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+218${_phoneController.text.trim()}',
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        role: _selectedRole,
        city: _selectedRole == 'technician' ? _cityController.text.trim() : null,
        nationality: _selectedRole == 'technician'
            ? _nationalityController.text.trim()
            : null,
        serviceCategories: _selectedRole == 'technician'
            ? _selectedServiceCategories
            : null,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'تم التسجيل بنجاح'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );

      // Small delay to ensure SnackBar is shown
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Navigate to OTP verification screen
      try {
        await Navigator.pushNamed(
        context,
        '/otp-verification-screen',
        arguments: {
          'phone': '+218${_phoneController.text.trim()}',
          'email': _emailController.text.trim(),
          'role': _selectedRole,
            'requires_approval': response['requires_approval'] ?? false,
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الانتقال: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      final errorMessage = e.getFirstError() ?? e.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التسجيل. الرجاء المحاولة مرة أخرى'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              _buildHeader(theme),
              SizedBox(height: 4.h),
              _buildRegistrationForm(theme),
              SizedBox(height: 3.h),
              _buildRegisterButton(theme),
              SizedBox(height: 2.h),
              _buildLoginLink(theme),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'person_add',
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'إنشاء حساب جديد',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'أدخل بياناتك للبدء في استخدام منصة بنسة',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleSelectionWidget(
            selectedRole: _selectedRole,
            onRoleChanged: (role) {
              setState(() {
                _selectedRole = role;
                // Clear technician-specific fields when switching to customer
                if (role == 'customer') {
                  _cityController.clear();
                  _nationalityController.clear();
                  _selectedServiceCategories.clear();
                  _cityError = null;
                  _nationalityError = null;
                }
              });
              HapticFeedback.selectionClick();
            },
          ),
          SizedBox(height: 3.h),
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الكامل',
            hint: 'أدخل اسمك الكامل',
            iconName: 'person',
            keyboardType: TextInputType.name,
            validator: _validateName,
            onChanged: (value) {
              setState(() => _nameError = _validateName(value));
            },
            errorText: _nameError,
            theme: theme,
          ),
          SizedBox(height: 2.h),
          _buildTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            iconName: 'email',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            onChanged: (value) {
              setState(() => _emailError = _validateEmail(value));
            },
            errorText: _emailError,
            theme: theme,
          ),
          SizedBox(height: 2.h),
          _buildPhoneField(theme),
          SizedBox(height: 2.h),
          _buildPasswordField(theme),
          PasswordStrengthIndicator(password: _passwordController.text),
          SizedBox(height: 2.h),
          _buildPasswordConfirmationField(theme),
          // Technician-only fields
          if (_selectedRole == 'technician') ...[
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _cityController,
              label: 'المدينة',
              hint: 'أدخل المدينة',
              iconName: 'location_city',
              keyboardType: TextInputType.text,
              validator: _validateCity,
              onChanged: (value) {
                setState(() => _cityError = _validateCity(value));
              },
              errorText: _cityError,
              theme: theme,
            ),
            SizedBox(height: 2.h),
            _buildTextField(
              controller: _nationalityController,
              label: 'الجنسية',
              hint: 'أدخل الجنسية',
              iconName: 'flag',
              keyboardType: TextInputType.text,
              validator: _validateNationality,
              onChanged: (value) {
                setState(() => _nationalityError = _validateNationality(value));
              },
              errorText: _nationalityError,
              theme: theme,
            ),
            SizedBox(height: 2.h),
            ServiceCategoriesSelector(
              selectedCategories: _selectedServiceCategories,
              onCategoriesChanged: (categories) {
                setState(() => _selectedServiceCategories = categories);
              },
            ),
          ],
          SizedBox(height: 3.h),
          TermsCheckboxWidget(
            isAccepted: _termsAccepted,
            onChanged: (value) {
              setState(() => _termsAccepted = value ?? false);
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String iconName,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required ValueChanged<String> onChanged,
    required String? errorText,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodyMedium,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            errorText: errorText,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم الهاتف',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '+218',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium,
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  setState(() => _phoneError = _validatePhone(value));
                },
                decoration: InputDecoration(
                  hintText: '912345678',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  errorText: _phoneError,
                  errorMaxLines: 2,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        if (_phoneError == null)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium,
          onChanged: (value) {
            setState(() {
              _passwordError = _validatePassword(value);
              // Re-validate password confirmation when password changes
              if (_passwordConfirmationController.text.isNotEmpty) {
                _passwordConfirmationError =
                    _validatePasswordConfirmation(_passwordConfirmationController.text);
              }
            });
          },
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: _isPasswordVisible ? 'visibility' : 'visibility_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
                HapticFeedback.selectionClick();
              },
            ),
            errorText: _passwordError,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordConfirmationField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تأكيد كلمة المرور',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordConfirmationController,
          obscureText: !_isPasswordConfirmationVisible,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium,
          onChanged: (value) {
            setState(() =>
                _passwordConfirmationError = _validatePasswordConfirmation(value));
          },
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: _isPasswordConfirmationVisible
                    ? 'visibility'
                    : 'visibility_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() =>
                    _isPasswordConfirmationVisible =
                        !_isPasswordConfirmationVisible);
                HapticFeedback.selectionClick();
              },
            ),
            errorText: _passwordConfirmationError,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(ThemeData theme) {
    final isEnabled = _isFormValid();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !_isLoading ? _handleRegistration : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor:
              theme.colorScheme.outline.withValues(alpha: 0.3),
          disabledForegroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'إنشاء الحساب',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Navigate to login screen
          Navigator.pushReplacementNamed(context, '/login-screen');
        },
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'لديك حساب بالفعل؟ '),
              TextSpan(
                text: 'تسجيل الدخول',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
