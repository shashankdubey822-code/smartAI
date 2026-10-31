// lib/widgets/timetable_sync_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/timetable_sync_service.dart';

class TimetableSyncDialog extends StatefulWidget {
  final String targetSection;
  final String userRole;
  final VoidCallback? onSynced;

  const TimetableSyncDialog({
    super.key,
    this.targetSection = 'CSE 5A',
    this.userRole = 'student',
    this.onSynced,
  });

  static Future<void> show(
    BuildContext context, {
    String targetSection = 'CSE 5A',
    String userRole = 'student',
    VoidCallback? onSynced,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TimetableSyncDialog(
        targetSection: targetSection,
        userRole: userRole,
        onSynced: onSynced,
      ),
    );
  }

  @override
  State<TimetableSyncDialog> createState() => _TimetableSyncDialogState();
}

class _TimetableSyncDialogState extends State<TimetableSyncDialog> {
  final ScrollController _scrollController = ScrollController();
  int _lastLogCount = 0;

  late final List<Map<String, String>> _syncSteps;

  @override
  void initState() {
    super.initState();
    _syncSteps = [
      {
        'title': 'Connecting to University Portal',
        'keyword': 'CONNECT',
        'detail': 'Handshaking with https://mru.edupage.org/timetable/view.php for ${widget.targetSection}...',
      },
      {
        'title': 'Extracting Official aSc Schema',
        'keyword': 'SCHEMA',
        'detail': 'Querying regulartt.js database for section ${widget.targetSection} lesson definitions...',
      },
      {
        'title': 'Processing 100-Min Lab Durations',
        'keyword': 'PARSER',
        'detail': 'Computing horizontal G1/G2 splits, double-period lab spans & room allocations...',
      },
      {
        'title': 'Updating AI RAG & Repository Index',
        'keyword': 'INDEX',
        'detail': 'Indexing verified ${widget.targetSection} schedule into live memory cache...',
      },
      {
        'title': 'Live Synchronization Complete',
        'keyword': 'SUCCESS',
        'detail': 'Schedule for ${widget.targetSection} verified & locked with live timestamp.',
      },
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncService = context.read<TimetableSyncService>();
      if (!syncService.isSyncing) {
        syncService.syncSectionInBackground(widget.targetSection);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _getStepIndex(double progress, bool isSuccess) {
    if (isSuccess || progress >= 1.0) return 4;
    if (progress >= 0.80) return 3;
    if (progress >= 0.55) return 2;
    if (progress >= 0.30) return 1;
    return 0;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<TimetableSyncService>();
    final isSyncing = syncService.isSyncing;
    final isComplete = syncService.isSuccess || (!syncService.isSyncing && syncService.progress >= 1.0);
    final hasError = syncService.errorMessage != null;
    final progress = syncService.progress;
    final logs = syncService.logs;

    if (logs.length != _lastLogCount) {
      _lastLogCount = logs.length;
      _scrollToBottom();
    }

    final currentStepIndex = _getStepIndex(progress, isComplete);
    final currentStep = _syncSteps[currentStepIndex];
    final syncedTimestamp = syncService.lastSyncedAt ?? DateTime.now();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Dialog Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isComplete
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 22)
                        : hasError
                            ? const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 22)
                            : const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                                ),
                              ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MANAV RACHNA UNIVERSITY',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'aSc Timetables Live Synchronization Engine',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // ── Body & Step Progress ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Step Badge & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isComplete
                              ? const Color(0xFFECFDF5)
                              : hasError
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isComplete
                                ? const Color(0xFFA7F3D0)
                                : hasError
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Text(
                          isComplete
                              ? 'SYNCHRONIZED'
                              : hasError
                                  ? 'FAILED'
                                  : 'STEP ${currentStepIndex + 1} OF 5',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isComplete
                                ? const Color(0xFF047857)
                                : hasError
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF1D4ED8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasError ? 'Sync Interrupted' : currentStep['title']!,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasError ? (syncService.errorMessage ?? 'An error occurred during sync.') : currentStep['detail']!,
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      color: hasError ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: isComplete ? 1.0 : (progress > 0 ? progress : null),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(
                        isComplete
                            ? const Color(0xFF10B981)
                            : hasError
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Live Terminal Console Box ──
                  Container(
                    width: double.infinity,
                    height: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: logs.isEmpty
                        ? Center(
                            child: Text(
                              'Initializing connection...',
                              style: GoogleFonts.firaCode(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: logs.length,
                            itemBuilder: (_, idx) {
                              final log = logs[idx];
                              Color logColor = const Color(0xFF94A3B8);
                              if (log.startsWith('[CONNECT]')) logColor = const Color(0xFF38BDF8);
                              if (log.startsWith('[SCHEMA]')) logColor = const Color(0xFFA78BFA);
                              if (log.startsWith('[PARSER]')) logColor = const Color(0xFFFBBF24);
                              if (log.startsWith('[INDEX]')) logColor = const Color(0xFF60A5FA);
                              if (log.startsWith('[SUCCESS]')) logColor = const Color(0xFF4ADE80);
                              if (log.startsWith('[ERROR]')) logColor = const Color(0xFFF87171);
                              if (log.startsWith('[CACHE]') || log.startsWith('[OFFLINE]')) {
                                logColor = const Color(0xFF34D399);
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  log,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 10.5,
                                    color: logColor,
                                    height: 1.3,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Timestamp Display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Synchronization Timestamp',
                                style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy • h:mm:ss a').format(syncedTimestamp),
                                style: GoogleFonts.lato(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        if (isComplete)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  'Live Active',
                                  style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Dialog Actions ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Run in Background button (closes dialog immediately while sync runs in background)
                  if (isSyncing) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.layers_outlined, size: 15),
                      label: Text(
                        'Run in Background',
                        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (hasError) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => syncService.syncSectionInBackground(widget.targetSection),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text('Retry Sync', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isComplete ? const Color(0xFF047857) : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: isComplete
                          ? () {
                              widget.onSynced?.call();
                              Navigator.of(context).pop();
                            }
                          : null,
                      icon: isComplete
                          ? const Icon(Icons.check_rounded, size: 16)
                          : const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white70)),
                            ),
                      label: Text(
                        isComplete ? 'View Updated Timetable' : 'Synchronizing...',
                        style: GoogleFonts.lato(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
