import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WaterProgressIndicator extends StatelessWidget {
  final double progress;
  final int consumedAmount;
  final int dailyGoal;

  const WaterProgressIndicator({
    Key? key,
    required this.progress,
    required this.consumedAmount,
    required this.dailyGoal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentComplete = (clampedProgress * 100).toInt();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: clampedProgress,
                strokeWidth: 14,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentComplete >= 100 ? Colors.greenAccent : Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$consumedAmount ml',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$percentComplete%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'daily_goal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white70,
          ),
        ).tr(),
        Text(
          '$dailyGoal ml',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}