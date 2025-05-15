import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class AnxietyCard extends StatelessWidget {
  final Widget? topImage;
  final Widget? content;
  final List<Widget>? actions;
  final double? height;
  final String? text;
  final VoidCallback? onTap;

  const AnxietyCard({
    super.key,
    this.topImage,
    this.content,
    this.actions,
    this.height,
    this.text,
    this.onTap,
  });

  const AnxietyCard.text({
    super.key,
    required String cause,
    required VoidCallback this.onTap,
  }) : text = cause,
       topImage = null,
       content = null,
       actions = null,
       height = null;

  @override
  Widget build(BuildContext context) {
    if (text != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: Colors.indigo, width: 1),
              ),
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Text(
                text!,
                style: const TextStyle(fontSize: AppSizes.fontSize, color: Colors.black87),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (topImage != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                        child: topImage!,
                      ),
                    if (content != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.padding),
                          color: AppColors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              content!,
                              if (actions != null)
                                Row(
                                  children: [
                                    for (
                                      int i = 0;
                                      i < actions!.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(width: AppSizes.space),
                                      Expanded(child: actions![i]),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
