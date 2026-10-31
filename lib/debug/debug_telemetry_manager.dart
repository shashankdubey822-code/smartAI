import 'package:flutter/foundation.dart';
import 'debug_telemetry_model.dart';

class DebugTelemetryManager extends ChangeNotifier {
  static final DebugTelemetryManager _instance = DebugTelemetryManager._internal();
  factory DebugTelemetryManager() => _instance;
  DebugTelemetryManager._internal();

  static DebugTelemetryManager get instance => _instance;

  final List<ChatTurnTelemetry> _turns = [];

  // Running totals across the session
  int _sessionPromptTokens = 0;
  int _sessionCandidateTokens = 0;
  int _sessionThoughtTokens = 0;
  int _sessionTotalTokens = 0;
  double _sessionPromptCostUsd = 0.0;
  double _sessionCandidatesCostUsd = 0.0;
  double _sessionTotalCostUsd = 0.0;
  GeminiUsageMetadata? _lastUsage;

  List<ChatTurnTelemetry> get turns => List.unmodifiable(_turns);
  int get sessionPromptTokens => _sessionPromptTokens;
  int get sessionCandidateTokens => _sessionCandidateTokens;
  int get sessionThoughtTokens => _sessionThoughtTokens;
  int get sessionTotalTokens => _sessionTotalTokens;
  double get sessionPromptCostUsd => _sessionPromptCostUsd;
  double get sessionCandidatesCostUsd => _sessionCandidatesCostUsd;
  double get sessionTotalCostUsd => _sessionTotalCostUsd;

  double get sessionPromptCostInr => _sessionPromptCostUsd * GeminiUsageMetadata.usdToInrRate;
  double get sessionCandidatesCostInr => _sessionCandidatesCostUsd * GeminiUsageMetadata.usdToInrRate;
  double get sessionTotalCostInr => _sessionTotalCostUsd * GeminiUsageMetadata.usdToInrRate;

  GeminiUsageMetadata? get lastUsage => _lastUsage;

  void recordTurn({
    required String userMessage,
    required String aiResponse,
    required GeminiUsageMetadata usage,
  }) {
    _lastUsage = usage;
    _sessionPromptTokens += usage.promptTokenCount;
    _sessionCandidateTokens += usage.candidatesTokenCount;
    _sessionThoughtTokens += usage.thoughtsTokenCount;
    _sessionTotalTokens += usage.totalTokenCount;
    _sessionPromptCostUsd += usage.promptCostUsd;
    _sessionCandidatesCostUsd += usage.candidatesCostUsd;
    _sessionTotalCostUsd += usage.estimatedCostUsd;

    _turns.add(ChatTurnTelemetry(
      userMessage: userMessage,
      aiResponse: aiResponse,
      usage: usage,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
  }

  void resetSession() {
    _turns.clear();
    _sessionPromptTokens = 0;
    _sessionCandidateTokens = 0;
    _sessionThoughtTokens = 0;
    _sessionTotalTokens = 0;
    _sessionPromptCostUsd = 0.0;
    _sessionCandidatesCostUsd = 0.0;
    _sessionTotalCostUsd = 0.0;
    _lastUsage = null;
    notifyListeners();
  }
}
