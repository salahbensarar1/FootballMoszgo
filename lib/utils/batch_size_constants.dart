/// Constants for safe batch operations and memory management
/// Prevents memory crashes when loading large datasets
class BatchSizeConstants {
  /// Maximum number of documents to load in a single query
  /// Based on mobile memory constraints and Firestore limits
  static const int maxQuerySize = 500;

  /// Safe batch size for cleanup operations
  /// Smaller to ensure cleanup operations don't timeout
  static const int cleanupBatchSize = 100;

  /// Maximum items to process in a single batch write
  /// Firestore limit is 500, we use 450 for safety margin
  static const int maxBatchWrites = 450;

  /// Page size for pagination in UI lists
  static const int uiPaginationSize = 50;

  /// Chunk size for bulk migration operations
  static const int migrationChunkSize = 200;

  /// Maximum items to load for dropdown selectors
  static const int dropdownMaxItems = 100;

  /// Safe limit for real-time stream listeners
  static const int streamListenerLimit = 100;

  /// Memory safety warning threshold
  static const int memoryWarningThreshold = 1000;

  /// Error messages for batch size violations
  static const String memoryRiskWarning =
      'Operation cancelled: Potential memory risk detected. Use pagination instead.';

  static const String batchSizeExceededError =
      'Batch size exceeds safe limits. Operation split into smaller chunks.';

  /// Check if a query size is safe for memory
  static bool isSafeQuerySize(int count) => count <= maxQuerySize;

  /// Check if a batch operation is safe
  static bool isSafeBatchSize(int count) => count <= cleanupBatchSize;

  /// Get safe chunk size for bulk operations
  static int getSafeChunkSize(int totalItems) {
    if (totalItems <= cleanupBatchSize) return totalItems;
    return cleanupBatchSize;
  }

  /// Calculate number of chunks needed for safe processing
  static int calculateChunkCount(int totalItems, {int? customChunkSize}) {
    final chunkSize = customChunkSize ?? cleanupBatchSize;
    return (totalItems / chunkSize).ceil();
  }
}