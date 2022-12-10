import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

class _Entry {
  final http.BaseRequest request;
  final Completer<http.StreamedResponse> completer;

  _Entry(this.request, this.completer);
}

/// A http client that limits the number of concurrent requests.
class SimpleClient extends http.BaseClient {
  final requestController = StreamController<_Entry>();
  late final StreamSubscription<void> _subscription;

  final http.Client _client;

  /// Constructs a [SimpleClient].
  /// [maxConcurrent] is the maximum number of concurrent requests.
  /// If [maxConcurrent] is null, there is no limit.
  SimpleClient({
    http.Client? client,
    int? maxConcurrent,
  })  : assert(maxConcurrent == null || maxConcurrent > 0),
        _client = client ?? http.Client() {
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
    _subscription = requestController.stream
        .flatMap(sendRequest, maxConcurrent: maxConcurrent)
        .listen(null);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // We use sync Completer here because the completion is the result
    // of the stream, which is already asynchronous.
    final completer = Completer<http.StreamedResponse>.sync();
    requestController.add(_Entry(request, completer));
    return completer.future;
  }

  @override
  void close() {
    super.close();
    _client.close();
    _subscription.cancel().then((_) => requestController.close());
  }
}

void main() async {
  final simpleClient = SimpleClient(maxConcurrent: 2);

  final futures = <Future<void>>[
    for (var i = 1; i <= 5; i++)
      simpleClient
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users/$i'))
          .then((res) => print('Response: id=$i -> ${res.statusCode}'))
          .onError((e, s) => print('Response: id=$i -> $e, $s')),
  ];

  await Future.wait(futures);
  simpleClient.close();
  print('Done');
}

// SimpleClient: --> https://jsonplaceholder.typicode.com/users/1
// SimpleClient: --> https://jsonplaceholder.typicode.com/users/2
// SimpleClient: <-- https://jsonplaceholder.typicode.com/users/2
// SimpleClient: --> https://jsonplaceholder.typicode.com/users/3
// Response: id=2 -> 200
// SimpleClient: <-- https://jsonplaceholder.typicode.com/users/1
// SimpleClient: --> https://jsonplaceholder.typicode.com/users/4
// Response: id=1 -> 200
// SimpleClient: <-- https://jsonplaceholder.typicode.com/users/4
// SimpleClient: --> https://jsonplaceholder.typicode.com/users/5
// Response: id=4 -> 200
// SimpleClient: <-- https://jsonplaceholder.typicode.com/users/3
// Response: id=3 -> 200
// SimpleClient: <-- https://jsonplaceholder.typicode.com/users/5
// Response: id=5 -> 200
// Done
