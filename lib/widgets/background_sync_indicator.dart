// lib/widgets/background_sync_indicator.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/timetable_sync_service.dart';
import 'timetable_sync_dialog.dart';

/// An elegant, non-blocking floating pill/banner that reflects live timetable background sync.
/// Features glowing radar pulse, continuous rotation, real-time stage descriptions,
/// and smooth transitions to a verified emerald state.
class BackgroundSyncIndicator extends StatefulWidget {
  final bool isTop;
  final EdgeInsets padding;

  const BackgroundSyncIndicator({
    super.key,
    this.isTop = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<BackgroundSyncIndicator> createState() => _BackgroundSyncIndicatorState();
}

class _BackgroundSyncIndicatorState extends State<BackgroundSyncIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<TimetableSyncService>();

    final isSyncing = syncService.isSyncing;
    final isSuccess = syncService.isSuccess;
    final hasError = syncService.errorMessage != null;

    final shouldShow = isSyncing || isSuccess || hasError;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        final offsetTween = widget.isTop
            ? Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero)
            : Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero);
        return SlideTransition(
          position: offsetTween.animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: !shouldShow
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: widget.padding,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        TimetableSyncDialog.show(
                          context,
                          targetSection: syncService.currentSection,
                        );
                      },
                      child: _buildPillContent(syncService, isSyncing, isSuccess, hasError),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPillContent(
    TimetableSyncService syncService,
    bool isSyncing,
    bool isSuccess,
    bool hasError,
  ) {
    Color bgGradientStart;
    Color bgGradientEnd;
    Color borderColor;
    Color iconColor;
    Color titleColor;
    Color subColor;

    if (hasError) {
      bgGradientStart = const Color(0xFF450A0A);
      bgGradientEnd = const Color(0xFF1F0606);
      borderColor = const Color(0xFFDC2626).withValues(alpha: 0.6);
      iconColor = const Color(0xFFF87171);
      titleColor = Colors.white;
      subColor = const Color(0xFFFCA5A5);
    } else if (isSuccess) {
      bgGradientStart = const Color(0xFF064E3B);
      bgGradientEnd = const Color(0xFF022C22);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.6);
      iconColor = const Color(0xFF34D399);
      titleColor = Colors.white;
      subColor = const Color(0xFFA7F3D0);
    } else {
      // Syncing
      bgGradientStart = const Color(0xFF0F172A);
      bgGradientEnd = const Color(0xFF1E293B);
      borderColor = const Color(0xFF0284C7).withValues(alpha: 0.5);
      iconColor = const Color(0xFF38BDF8);
      titleColor = Colors.white;
      subColor = const Color(0xFF94A3B8);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgGradientStart, bgGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isSuccess
                    ? const Color(0xFF10B981)
                    : hasError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0284C7))
                .withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Radar / Icon with pulsing glow ──
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSyncing)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 28 * _pulseAnimation.value,
                      height: 28 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0284C7).withValues(
                          alpha: math.max(0.0, 0.35 - (_pulseAnimation.value - 0.85) * 0.4),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSuccess
                      ? Icon(Icons.check_circle_rounded, color: iconColor, size: 16)
                      : hasError
                          ? Icon(Icons.error_outline_rounded, color: iconColor, size: 16)
                          : RotationTransition(
                              turns: _rotateController,
                              child: Icon(Icons.sync_rounded, color: iconColor, size: 16),
                            ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // ── Text Info & Section Badge ──
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xFF047857)
                            : hasError
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF0369A1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        syncService.currentSection.toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        isSuccess
                            ? 'Timetable Synchronized'
                            : hasError
                                ? 'Sync Interrupted'
                                : 'Syncing Live Timetable...',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isSuccess
                      ? '${syncService.slotCount} official slots verified & active'
                      : hasError
                          ? (syncService.errorMessage ?? 'Tap to retry')
                          : (syncService.currentStage.isNotEmpty
                              ? syncService.currentStage
                              : 'Connecting to university portal...'),
                  style: GoogleFonts.lato(
                    fontSize: 10.5,
                    color: subColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Progress or Action Button ──
          if (isSyncing)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 4),
              child: CircularProgressIndicator(
                value: syncService.progress > 0 ? syncService.progress : null,
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                backgroundColor: Colors.white12,
              ),
            )
          else
            GestureDetector(
              onTap: () => syncService.dismissIndicator(),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
