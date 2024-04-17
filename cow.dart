import 'dart:isolate';

import 'isolate_stdlib.dart';

void main(List<String> args, SendPort message) async {
  await cow(message);
  log('cow', 'done (end of func)');
  Isolate.exit();
}

Future<void> cow(SendPort message) async {
  try {
    SRPWrapper mainPort = SRPWrapper.fromSendPort(message, 'cow2Main');
    SRPWrapper pigPort = await setupPortsNonHost('cow', 'pig', mainPort);
    SRPWrapper grassPort = await setupPortsNonHost('cow', 'grass', mainPort);
    mainPort.send("ready");
    pigPort.send('moo');
    while (true) {
      String msg = await pigPort.readItem<String>();
      if (msg == 'done') {
        log('cow', 'pig gone, speed eating');
        break;
      }
      log('cow', 'got $msg, responding');
      pigPort.send('moo');
      grassPort.send('eat');
      String rx = await grassPort.readItem<String>();
      log('cow', 'ate, got $rx');
      if (rx == 'done') {
        pigPort.send('done');
        log('cow', 'done');
        Isolate.exit();
      }
    }
    while (true) {
      log('cow', 'moo');
      grassPort.send('eat');
      String rx = await grassPort.readItem<String>();
      log('cow', 'ate, got $rx');
      if (rx == 'done') {
        log('cow', 'done');
        Isolate.exit();
      }
    }
  } catch (e) {
    print('COW ERROR: $e');
  }
}
