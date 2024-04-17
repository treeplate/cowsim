import 'dart:isolate';

import 'isolate_stdlib.dart';

void main(List<String> args, SendPort message) async {
  await sheep(message);
  log('sheep', 'done (end of func)');
  Isolate.exit();
}

Future<void> sheep(SendPort message) async {
  try {
    SRPWrapper mainPort = SRPWrapper.fromSendPort(message, 'sheep2main');
    SRPWrapper pigPort = await setupPortsNonHost('sheep', 'pig', mainPort);
    SRPWrapper grassPort = await setupPortsNonHost('sheep', 'grass', mainPort);
    mainPort.send("ready");
    pigPort.send('baa');
    while (true) {
      String msg = await pigPort.readItem<String>();
      if (msg == 'done') {
        log('sheep', 'pig gone, speed eating');
        break;
      }
      log('sheep', 'got $msg, responding');
      pigPort.send('baa');
      grassPort.send('eat');
      String rx = await grassPort.readItem<String>();
      log('sheep', 'ate, got $rx');
      if (rx == 'done') {
        pigPort.send('done');
        log('sheep', 'done');
        Isolate.exit();
      }
    }
    while (true) {
      log('sheep', 'baa');
      grassPort.send('eat');
      String rx = await grassPort.readItem<String>();
      log('sheep', 'ate, got $rx');
      if (rx == 'done') {
        log('sheep', 'done');
        Isolate.exit();
      }
    }
  } catch (e) {
    print('SHEEP ERROR: $e');
  }
}
