import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audit_status_controller.dart';
import '../../core/constants/app_constants.dart';

/// 审核状态页面
class AuditStatusPage extends StatelessWidget {
  const AuditStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuditStatusController());
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Onboarding review',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: controller.logout,
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
      body: Obx(() => RefreshIndicator(
        onRefresh: controller.refresh,
        color: const Color(0xFFFF1493),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 状态图标
              _buildStatusIcon(controller),
              const SizedBox(height: 32),
              
              // 状态标题
              _buildStatusTitle(controller),
              const SizedBox(height: 16),
              
              // 状态描述
              _buildStatusDescription(controller),
              const SizedBox(height: 32),
              
              // 审核拒绝原因
              if (controller.auditStatus.value == AuditStatus.rejected)
                _buildRejectReason(controller),
              
              // 待审核提示
              if (controller.auditStatus.value == AuditStatus.pending)
                _buildPendingTips(),
              
              const SizedBox(height: 40),
              
              // 操作按钮
              _buildActionButtons(controller),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      )),
    );
  }
  
  /// 状态图标
  Widget _buildStatusIcon(AuditStatusController controller) {
    return Obx(() {
      final isAnimating = controller.auditStatus.value == AuditStatus.pending;
      
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isAnimating ? 1 : 0),
        duration: const Duration(seconds: 2),
        builder: (context, value, child) {
          return Transform.rotate(
            angle: isAnimating ? value * 6.28 : 0,
            child: child,
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: controller.statusColor.withOpacity(0.1),
            border: Border.all(
              color: controller.statusColor,
              width: 3,
            ),
          ),
          child: Icon(
            controller.statusIcon,
            color: controller.statusColor,
            size: 60,
          ),
        ),
      );
    });
  }
  
  /// 状态标题
  Widget _buildStatusTitle(AuditStatusController controller) {
    return Obx(() => Text(
      controller.statusTitle,
      style: TextStyle(
        color: controller.statusColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ));
  }
  
  /// 状态描述
  Widget _buildStatusDescription(AuditStatusController controller) {
    return Obx(() => Text(
      controller.statusDescription,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 16,
        height: 1.5,
      ),
    ));
  }
  
  /// 审核拒绝原因
  Widget _buildRejectReason(AuditStatusController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Rejection reason',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            controller.auditReason.value.isEmpty 
                ? 'No reason provided. Please contact support.'
                : controller.auditReason.value,
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 14,
              height: 1.5,
            ),
          )),
        ],
      ),
    );
  }
  
  /// 待审核提示
  Widget _buildPendingTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Tips',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• You will be notified when approved\n'
            '• Pull down to refresh for latest status\n'
            '• Contact support if you have questions',
            style: TextStyle(
              color: Colors.orange[300],
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 操作按钮
  Widget _buildActionButtons(AuditStatusController controller) {
    return Obx(() {
      final status = controller.auditStatus.value;
      
      return Column(
        children: [
          // 审核拒绝时显示重新提交按钮
          if (status == AuditStatus.rejected) ...[
            Container(
              width: double.infinity,
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
                onPressed: controller.resubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Resubmit application',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 联系客服按钮
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: ElevatedButton(
              onPressed: controller.contactSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    'Contact support',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 待审核时显示刷新提示
          if (status == AuditStatus.pending) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, color: Colors.grey[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Pull down to refresh for latest status',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}
