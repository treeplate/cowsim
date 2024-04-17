import 'dart:isolate';

import 'isolate_stdlib.dart';

// ignore_for_file: experiment_not_enabled
typedef voidT = void;

void main(List<String> args, SendPort message) async {
  await grass(message);
  log('grass', 'done');
  Isolate.exit();
}

Future<void> grass(SendPort message) async {
  try {
    SRPWrapper mainPort = SRPWrapper.fromSendPort(message, 'grass2Main');
    SRPWrapper cowPort = setupPortsHost('grass', 'cow', mainPort);
    SRPWrapper sheepPort = setupPortsHost('grass', 'sheep', mainPort);
    mainPort.send("ready");
    int grass = 40;
    while (grass > 0) {
      (String, bool, int) msg =
          await firstToRespond<String>(cowPort, sheepPort);
      if (msg.$1 == 'eat') {
        grass--;
        if (grass > 0) {
          if (msg.$2) {
            log('grass', 'cow ate #${msg.$3}');
            cowPort.send('grass');
          } else {
            log('grass', 'sheep ate #${msg.$3}');
            sheepPort.send('grass');
          }
        } else {
          if (msg.$2) {
            log('grass', 'cow failed to eat #${msg.$3}');
            cowPort.send('done');
            String msg2 = await sheepPort.readItem<String>();
            while (msg2 != 'eat') {
              msg2 = await sheepPort.readItem<String>();
            }
            log('grass', 'sheep failed to eat #${msg.$3}');
            sheepPort.send('done');
          } else {
            log('grass', 'sheep failed to eat #${msg.$3}');
            sheepPort.send('done');
            String msg2 = await cowPort.readItem<String>();
            while (msg2 != 'eat') {
              msg2 = await cowPort.readItem<String>();
            }
            log('grass', 'cow failed to eat #${msg.$3}');
            cowPort.send('done');
          }
        }
      }
    }
    log('grass', 'grass depleted');
    ;
    log('grass', 'done');
    Isolate.exit();
  } catch (e) {
    print('GRASS ERROR: $e');
  }
}
