import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      if (success) {
        Helpers.showSuccessMessage(context, 'Mwakiriwe neza!');
      } else {
        Helpers.showErrorMessage(context, authProvider.errorMessage ?? AppConstants.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo and Title
                _buildHeader(),
                const SizedBox(height: 50),
                
                // Login Form
                _buildLoginForm(),
                const SizedBox(height: 30),
                
                // Login Button
                _buildLoginButton(),
                const SizedBox(height: 20),
                
                // Remember Me Checkbox
                _buildRememberMeCheckbox(),
                const SizedBox(height: 40),
                
                // App Version
                _buildVersionInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: ThemeConfig.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ThemeConfig.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.store,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        // App Name
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: ThemeConfig.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          AppConstants.tagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: ThemeConfig.secondaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        
        // Login Title
        Text(
          AppConstants.loginTitle,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: ThemeConfig.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username Field
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: AppConfig.bodyFontSize),
            decoration: InputDecoration(
              labelText: AppConstants.username,
              prefixIcon: const Icon(Icons.person, size: 28),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: Validators.validateUsername,
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
          const SizedBox(height: 20),
          
          // Password Field
          TextFormField(
            controller: _passwordController,
            style: const TextStyle(fontSize: AppConfig.bodyFontSize),
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: AppConstants.password,
              prefixIcon: const Icon(Icons.lock, size: 28),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: AppConfig.buttonHeight,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppConstants.loginButton,
                    style: const TextStyle(
                      fontSize: AppConfig.buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: ThemeConfig.primaryColor,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: Text(
            'Nzibuke',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeConfig.primaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      children: [
        Text(
          'Verisiyo ${AppConfig.appVersion}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeConfig.secondaryText,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '© 2025 Sheba Bar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeConfig.secondaryText,
          ),
        ),
      ],
    );
  }
}
