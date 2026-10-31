import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'debug_telemetry_manager.dart';
import 'debug_telemetry_model.dart';
import '../utils/app_theme.dart';

class DebugInspectorDialog extends StatelessWidget {
  const DebugInspectorDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DebugInspectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DebugTelemetryManager.instance,
      builder: (context, _) {
        final mgr = DebugTelemetryManager.instance;
        final last = mgr.lastUsage;
        final turns = mgr.turns;

        return Dialog(
          backgroundColor: const Color(0xFF0B132B), // Deep Slate Navy
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                        ),
                        child: const Icon(
                          Icons.bug_report_rounded,
                          color: Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Gemini AI Telemetry & Cost Debugger',
                                  style: GoogleFonts.syne(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                  ),
                                  child: Text(
                                    'LIVE INR ₹',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Real-time Token In/Out • Context Windows • Live INR (₹${GeminiUsageMetadata.usdToInrRate}/USD)',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reset Telemetry Session',
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8)),
                        onPressed: () => mgr.resetSession(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  const SizedBox(height: 14),

                  // ── Session Cumulative Totals Banner ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B).withValues(alpha: 0.9),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ALL-TIME SESSION USAGE & EXPENDITURE',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: const Color(0xFF38BDF8),
                              ),
                            ),
                            // Real INR Total Price Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF047857).withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Text(
                                'Total Cost: ₹${mgr.sessionTotalCostInr.toStringAsFixed(4)}  (\$${mgr.sessionTotalCostUsd.toStringAsFixed(6)})',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF34D399),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statBox(
                              label: 'Total In (Prompt)',
                              value: '${mgr.sessionPromptTokens} tokens',
                              subValue: '₹${mgr.sessionPromptCostInr.toStringAsFixed(4)} (\$${mgr.sessionPromptCostUsd.toStringAsFixed(6)})',
                              icon: Icons.login_rounded,
                              color: const Color(0xFF60A5FA),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              label: 'Total Out (Candidates)',
                              value: '${mgr.sessionCandidateTokens} tokens',
                              subValue: '₹${mgr.sessionCandidatesCostInr.toStringAsFixed(4)} (\$${mgr.sessionCandidatesCostUsd.toStringAsFixed(6)})',
                              icon: Icons.logout_rounded,
                              color: const Color(0xFFA78BFA),
                            ),
                            const SizedBox(width: 8),
                            _statBox(
                              label: 'Cumulative Context',
                              value: '${mgr.sessionTotalTokens} tokens',
                              subValue: '${turns.length} chat turns',
                              icon: Icons.all_inclusive_rounded,
                              color: const Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Latest Turn Snapshot ──
                  if (last != null) ...[
                    Text(
                      'PREVIOUS / LAST TURN PARAMETERS',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D31),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _miniMetric('Active Model', last.modelName),
                          _miniMetric('Prev In Tokens', '${last.promptTokenCount}', sub: '₹${last.promptCostInr.toStringAsFixed(4)}'),
                          _miniMetric('Prev Out Tokens', '${last.candidatesTokenCount}', sub: '₹${last.candidatesCostInr.toStringAsFixed(4)}'),
                          if (last.thoughtsTokenCount > 0)
                            _miniMetric('Thinking Tokens', '${last.thoughtsTokenCount}'),
                          _miniMetric('Turn Price', '₹${last.estimatedCostInr.toStringAsFixed(4)}', sub: '\$${last.estimatedCostUsd.toStringAsFixed(6)}', isAccent: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Turn-by-Turn History Log ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TURN TELEMETRY LOG (${turns.length})',
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        'Gemini pricing: \$0.075/1M in, \$0.30/1M out',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: turns.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 36, color: Color(0xFF475569)),
                                const SizedBox(height: 10),
                                Text(
                                  'No messages sent yet in this session.\nEvery new chat and message will track input/output tokens and real INR cost right here!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: turns.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final turn = turns[turns.length - 1 - i]; // Most recent first
                              return _turnCard(turn, turns.length - i);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _statBox({
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _miniMetric(String label, String value, {String? sub, bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isAccent ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 1),
          Text(
            sub,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  static Widget _turnCard(ChatTurnTelemetry turn, int turnNumber) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Turn #$turnNumber',
                  style: GoogleFonts.syne(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'In: ${turn.usage.promptTokenCount} | Out: ${turn.usage.candidatesTokenCount} | Real Price: ₹${turn.usage.estimatedCostInr.toStringAsFixed(4)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFF38BDF8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Q: ${turn.userMessage}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE2E8F0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A: ${turn.aiResponse}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
