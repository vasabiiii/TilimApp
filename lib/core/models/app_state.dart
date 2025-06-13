enum AppStatus {
  initial,
  loading,
  success,
  error
}

class AppState<T> {
  final AppStatus status;
  final T? data;
  final String? error;

  const AppState({
    this.status = AppStatus.initial,
    this.data,
    this.error,
  });

  AppState<T> copyWith({
    AppStatus? status,
    T? data,
    String? error,
  }) {
    return AppState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  bool get isInitial => status == AppStatus.initial;
  bool get isLoading => status == AppStatus.loading;
  bool get isSuccess => status == AppStatus.success;
  bool get isError => status == AppStatus.error;
} 