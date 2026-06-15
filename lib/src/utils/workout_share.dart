import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/workout_session.dart';
import '../widgets/workout/workout_share_card.dart';

/// Renders a [WorkoutShareCard] off-screen via an [OverlayEntry], captures it
/// as a PNG, and opens the system share sheet. This avoids keeping the large
/// (1080x1350) card permanently in the visible widget tree.
Future<void> shareWorkoutSession(
  BuildContext context, {
  required WorkoutSession session,
  required Duration elapsed,
  int prCount = 0,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final cardKey = GlobalKey();

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Off-screen so the user never sees it, but it is still laid out + painted.
      left: -3000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: cardKey,
          child: WorkoutShareCard(
            session: session,
            elapsed: elapsed,
            prCount: prCount,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    // Wait until the overlay has been laid out and painted at least once.
    await Future.delayed(const Duration(milliseconds: 60));

    final boundary =
        cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Share card not ready');
    }

    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode image');
    final pngBytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/reprise_workout_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'Crushed my ${session.dayName} workout with RepRise! 💪 '
          '${session.totalVolumeKg} kg total volume.',
    );
  } finally {
    entry.remove();
  }
}
