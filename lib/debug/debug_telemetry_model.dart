class GeminiUsageMetadata {
  static const double usdToInrRate = 95.20; // Live internet USD to INR exchange rate

  final int promptTokenCount;
  final int candidatesTokenCount;
  final int totalTokenCount;
  final int thoughtsTokenCount;
  final String modelName;
  final DateTime timestamp;
  final double promptCostUsd;
  final double candidatesCostUsd;
  final double estimatedCostUsd;

  double get promptCostInr => promptCostUsd * usdToInrRate;
  double get candidatesCostInr => candidatesCostUsd * usdToInrRate;
  double get estimatedCostInr => estimatedCostUsd * usdToInrRate;

  const GeminiUsageMetadata({
    required this.promptTokenCount,
    required this.candidatesTokenCount,
    required this.totalTokenCount,
    required this.thoughtsTokenCount,
    required this.modelName,
    required this.timestamp,
    required this.promptCostUsd,
    required this.candidatesCostUsd,
    required this.estimatedCostUsd,
  });

  factory GeminiUsageMetadata.fromMap(
    Map<String, dynamic> map, {
    String modelName = 'gemini-2.5-flash-lite',
  }) {
    final prompt = (map['promptTokenCount'] as num?)?.toInt() ?? 0;
    final candidates = (map['candidatesTokenCount'] as num?)?.toInt() ?? 0;
    final total = (map['totalTokenCount'] as num?)?.toInt() ?? (prompt + candidates);
    final thoughts = (map['thoughtsTokenCount'] as num?)?.toInt() ??
        (map['thinkingTokenCount'] as num?)?.toInt() ??
        0;

    // Pricing calculation based on Gemini 2.5 Flash / Flash Lite:
    // Input: $0.075 per 1,000,000 tokens
    // Output: $0.30 per 1,000,000 tokens
    final inCost = (prompt / 1000000.0) * 0.075;
    final outCost = (candidates / 1000000.0) * 0.30;
    final totCost = inCost + outCost;

    return GeminiUsageMetadata(
      promptTokenCount: prompt,
      candidatesTokenCount: candidates,
      totalTokenCount: total,
      thoughtsTokenCount: thoughts,
      modelName: modelName,
      timestamp: DateTime.now(),
      promptCostUsd: inCost,
      candidatesCostUsd: outCost,
      estimatedCostUsd: totCost,
    );
  }

  factory GeminiUsageMetadata.empty() {
    return GeminiUsageMetadata(
      promptTokenCount: 0,
      candidatesTokenCount: 0,
      totalTokenCount: 0,
      thoughtsTokenCount: 0,
      modelName: 'None',
      timestamp: DateTime.now(),
      promptCostUsd: 0.0,
      candidatesCostUsd: 0.0,
      estimatedCostUsd: 0.0,
    );
  }
}

class ChatTurnTelemetry {
  final String userMessage;
  final String aiResponse;
  final GeminiUsageMetadata usage;
  final DateTime timestamp;

  ChatTurnTelemetry({
    required this.userMessage,
    required this.aiResponse,
    required this.usage,
    required this.timestamp,
  });
}
