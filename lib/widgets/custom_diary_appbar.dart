import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class CustomDiaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;

  /// 조건부 팝업 설정
  final bool confirmOnBack;
  final bool confirmOnHome;

  const CustomDiaryAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.confirmOnBack = false,
    this.confirmOnHome = false,
  });

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('종료하시겠어요?'),
        content: const Text('지금 종료하면 진행 상황이 저장되지 않을 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(16,0,0,0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            if (confirmOnBack) {
              final confirmed = await _confirmExit(context);
              if (!confirmed) return;
              if (!context.mounted) return;
            }
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      titleSpacing: 8,
      title: Text(title, style: const TextStyle(color: AppColors.black)),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0,0,0,0),
          child: IconButton(
            icon: const Icon(Icons.storage_outlined, color: AppColors.black),
            onPressed: () async {
              if (confirmOnBack) {
                final confirmed = await _confirmExit(context);
                if (!confirmed) return;
                if (!context.mounted) return;
              }
              Navigator.pushNamed(context, '/diary_record');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0,0,16,0),
          child: IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.black),
            onPressed: () async {
              if (confirmOnHome) {
                final confirmed = await _confirmExit(context);
                if (!confirmed) return;
                if (!context.mounted) return;
              }
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

