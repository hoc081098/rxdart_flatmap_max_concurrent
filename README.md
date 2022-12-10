# rxdart_flatmap_max_concurrent

Using `rxdart`'s `flatMap` with `maxConcurrent` to limit the number of concurrent requests.

```dart
Stream<void> sendRequest(_Entry entry) {
  print('SimpleClient: --> ${entry.request.url}');

  return _client
      .send(entry.request)
      .asStream()
      .doOnData(entry.completer.complete)
      .doOnCancel(() => print('SimpleClient: <-- ${entry.request.url}'));
}

// Use [flatMap] from `rxdart` to limit the number of concurrent requests easily :))
requestController.stream
    .flatMap(sendRequest, maxConcurrent: maxConcurrent)
    .listen(null);
```