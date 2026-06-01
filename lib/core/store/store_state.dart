sealed class StoreState<T> {
  const StoreState();
}

final class StoreLoading<T> extends StoreState<T> {
  const StoreLoading();
}

final class StoreLoaded<T> extends StoreState<T> {
  final T data;
  const StoreLoaded(this.data);
}

final class StoreError<T> extends StoreState<T> {
  final Object error;
  const StoreError(this.error);
}
