import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  final bool isCompact;

  const MedicalDisclaimerBanner({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppConstants.standardDisclaimer,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: AppColors.primaryDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
