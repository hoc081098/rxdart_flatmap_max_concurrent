# rxdart_flatmap_max_concurrent

Using `rxdart`'s `flatMap` with `maxConcurrent` to limit the number of concurrent requests.

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Frxdart_flatmap_max_concurrent&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

```dart
Stream<void> sendRequest(_Entry entry) {
  print('SimpleClient: --> ${entry.request.url}');

  return _client
      .send(entry.request)
      .asStream()
      .doOnError(entry.completer.completeError)
      .doOnData(entry.completer.complete)
      .onErrorResumeNext(Stream.empty())
      .doOnCancel(() => print('SimpleClient: <-- ${entry.request.url}'));
}

// Use [flatMap] from `rxdart` to limit the number of concurrent requests easily :))
requestController.stream
    .flatMap(sendRequest, maxConcurrent: maxConcurrent)
    .listen(null);
```
