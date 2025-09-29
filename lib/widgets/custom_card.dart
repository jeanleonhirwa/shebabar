import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../config/app_config.dart';

class CustomCard extends StatelessWidget {
  final String? title;
  final String? value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;

  const CustomCard({
    super.key,
    this.title,
    this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.child,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppConfig.cardPadding),
          child: child ?? _buildDefaultContent(context),
        ),
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null || title != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? ThemeConfig.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? ThemeConfig.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeConfig.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        if (value != null) ...[
          Text(
            value!,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: color ?? ThemeConfig.primaryText,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeConfig.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: ThemeConfig.secondaryText,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeConfig.secondaryText,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          if (isLoading)
            const SizedBox(
              height: 32,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Text(
              value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: ThemeConfig.primaryText,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeConfig.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Widget? action;

  const InfoCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeConfig.secondaryText,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ] else if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              color: ThemeConfig.secondaryText,
              size: 16,
            ),
        ],
      ),
    );
  }
}
