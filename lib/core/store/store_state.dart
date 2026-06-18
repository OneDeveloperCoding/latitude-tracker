sealed class StoreState<T> {
  const StoreState();
}

final class StoreLoading<T> extends StoreState<T> {
  const StoreLoading();
}

final class StoreLoaded<T> extends StoreState<T> {
  const StoreLoaded(this.data);
  final T data;
}

final class StoreError<T> extends StoreState<T> {
  const StoreError(this.error);
  final Object error;
}
