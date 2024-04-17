import 'dart:async';
import 'dart:isolate';

import 'srp.dart';
export 'srp.dart';

// ignore_for_file: experiment_not_enabled

SRPWrapper setupPortsHost(String name, String target, SRPWrapper proxy) {
  ReceivePort _port = ReceivePort();
  proxy.send(_port.sendPort);
  SRPWrapper port = SRPWrapper(_port, '${name}2$target');
  log(name, 'registered $target');
  return port;
}

Future<SRPWrapper> setupPortsNonHost(
    String name, String target, SRPWrapper proxy) async {
  SendPort _port = await proxy.readItem<SendPort>();
  SRPWrapper port = SRPWrapper.fromSendPort(_port, '${name}2$target');
  log(name, 'registered $target');
  return port;
}

/// DO NOT readItem() before this future completes, it may cause a race condition.
int i = 0;
Future<(T, bool, int)> firstToRespond<T>(SRPWrapper a, SRPWrapper b) async {
  Completer<T> v2 = Completer();
  Completer<bool> wasA = Completer();
  a.readItem<T>(false).then((value) {
    if(v2.isCompleted) return;
    v2.complete(value);
    wasA.complete(true);
  });
  b.readItem<T>(false).then((value) {
    if(v2.isCompleted) return;
    v2.complete(value);
    wasA.complete(false);
  });
  T value = await v2.future;
  bool a2 = await wasA.future;
  if (a2) {
    a.items.removeAt(0).toString();
  } else {
    b.items.removeAt(0).toString();
  }
  i++;
  return (value, a2, i);
}
