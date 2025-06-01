class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String message, [dynamic error]) {
    return ApiResponse(
      success: false,
      message: message,
      error: error,
    );
  }

  bool get hasError => !success;
  bool get hasData => data != null;

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, data: $data, error: $error}';
  }
} 