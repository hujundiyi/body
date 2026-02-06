import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 带占位图的网络头像
/// 加载中或加载失败时显示占位图（灰色圆形 + 人像图标，或可选 asset 占位图）
class AvatarNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BoxBorder? border;
  final Color? placeholderColor;
  final Color? placeholderIconColor;
  /// 可选：占位图资源路径，若提供则加载中/失败时显示该图
  final String? placeholderAssetImage;

  const AvatarNetworkImage({
    super.key,
    required this.imageUrl,
    this.size = 70,
    this.border,
    this.placeholderColor,
    this.placeholderIconColor,
    this.placeholderAssetImage,
  });

  /// 占位图 Widget（加载中 / 加载失败 / 无 URL 时显示）
  Widget _buildPlaceholder() {
    if (placeholderAssetImage != null && placeholderAssetImage!.isNotEmpty) {
      final path = placeholderAssetImage!;
      final isSvg = path.toLowerCase().endsWith('.svg');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipOval(
          child: isSvg
              ? SvgPicture.asset(
                  path,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                )
              : Image.asset(
                  path,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, __, ___) => _buildIconPlaceholder(),
                ),
        ),
      );
    }
    return _buildIconPlaceholder();
  }

  Widget _buildIconPlaceholder() {
    final bg = placeholderColor ?? const Color(0xFF4A4A5A);
    final iconColor = placeholderIconColor ?? Colors.white54;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: border,
      ),
      child: Icon(Icons.person, color: iconColor, size: size * 0.55),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder();
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      ),
    );
  }
}
