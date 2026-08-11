import 'package:flutter/material.dart';
import '../../../widgets/app_colors.dart';

class HomeAIBanner extends StatelessWidget {
  final VoidCallback? onTryNow;

  const HomeAIBanner({
    super.key,
    this.onTryNow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppColors.paddingMD),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius:
              BorderRadius.circular(AppColors.radiusLG),
        ),
        child: Row(
          children: [

            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    Text(
                      "AI Virtual\nTry-On",
                      style: AppColors.sectionTitle,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "See how your favourite outfit looks on you before buying.",
                      style: AppColors.body,
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton(
                      onPressed: onTryNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                      ),
                      child: const Text("Try Now"),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 12),
                child: Image.asset(
                  "assets/images/ai_model.jpg",
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}