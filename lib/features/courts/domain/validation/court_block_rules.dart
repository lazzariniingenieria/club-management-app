abstract final class CourtBlockRules {
  static const int maxReasonLength = 150;

  static bool reasonFits(String reason) =>
      reason.trim().length <= maxReasonLength;
}
