import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/anchor_login_controller.dart';

/// 主播登录页面
class AnchorLoginPage extends StatelessWidget {
  const AnchorLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnchorLoginController());
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo 和标题
                _buildHeader(),
                
                const SizedBox(height: 48),
                
                // 登录表单
                _buildLoginForm(controller),
                
                const SizedBox(height: 16),
                
                // 记住密码和忘记密码
                _buildOptions(controller),
                
                const SizedBox(height: 32),
                
                // 登录按钮
                _buildLoginButton(controller),
                
                const SizedBox(height: 24),
                
                // 注册链接
                _buildRegisterLink(controller),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建头部
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1493).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.videocam_rounded,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        
        // 标题
        const Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          'Anchor Login',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        // 非生产环境时显示当前环境，便于区分登录账号
        if (EnvironmentConfig.current != AppEnvironment.production) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFC107), width: 1),
            ),
            child: Text(
              _getEnvironmentName(EnvironmentConfig.current),
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getEnvironmentName(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }
  
  /// 构建登录表单
  Widget _buildLoginForm(AnchorLoginController controller) {
    return Column(
      children: [
        // 邮箱输入框
        TextFormField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintText: 'Please enter email',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: controller.validateEmail,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        
        // 密码输入框
        Obx(() => TextFormField(
          controller: controller.passwordController,
          obscureText: controller.obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintText: 'Please enter password',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[400],
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1493), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: controller.validatePassword,
          textInputAction: TextInputAction.next,
        )),
      ],
    );
  }
  
  /// 构建选项（记住密码、忘记密码）
  Widget _buildOptions(AnchorLoginController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 记住密码
        Obx(() => GestureDetector(
          onTap: controller.toggleRememberPassword,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: controller.rememberPassword 
                        ? const Color(0xFFFF1493) 
                        : Colors.grey[600]!,
                    width: 2,
                  ),
                  color: controller.rememberPassword 
                      ? const Color(0xFFFF1493) 
                      : Colors.transparent,
                ),
                child: controller.rememberPassword
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Remember Password',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        )),
        
        // 忘记密码
        GestureDetector(
          onTap: controller.forgotPassword,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Color(0xFFFF1493),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  /// 构建登录按钮
  Widget _buildLoginButton(AnchorLoginController controller) {
    return Obx(() => Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1493).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.isLoading ? null : controller.login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: controller.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ));
  }
  
  /// 构建注册链接
  Widget _buildRegisterLink(AnchorLoginController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        GestureDetector(
          onTap: controller.goToRegister,
          child: const Text(
            ' Sign Up Now',
            style: TextStyle(
              color: Color(0xFFFF1493),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
