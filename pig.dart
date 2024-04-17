import 'dart:isolate';

import 'isolate_stdlib.dart';
// ignore_for_file: experiment_not_enabled

void main(List<String> args, SendPort message) async {
  await pig(message);
  log('pig', 'done');
  Isolate.exit();
}

Future<void> pig(SendPort message) async {
  try {
    SRPWrapper mainPort = SRPWrapper.fromSendPort(message, 'pig2main');
    SRPWrapper cowPort = setupPortsHost('pig', 'cow', mainPort);
    SRPWrapper sheepPort = setupPortsHost('pig', 'sheep', mainPort);
    mainPort.send("ready");
    int oinks = 0;
    bool cow = true;
    bool sheep = true;
    while (oinks < 50 && (sheep || cow)) {
      if (cow && sheep) {
        (String, bool, int) msg =
            await firstToRespond<String>(cowPort, sheepPort);
        if (msg.$1 == 'done') {
          log('pig', '${msg.$2 ? 'cow' : 'sheep'} gone');
          if (msg.$2) {
            cow = false;
          } else {
            sheep = false;
          }
          continue;
        }
        log('pig',
            'got ${msg.$1} from ${msg.$2 ? 'cow' : 'sheep'}, (#${msg.$3}) responding');
        (msg.$2 ? cowPort : sheepPort).send('oink');
        oinks++;
      } else if (cow) {
        String msg = await cowPort.readItem<String>();
        if (msg == 'done') {
          log('pig', 'cow gone');
          cow = false;
          continue;
        }
        log('pig', 'got $msg from cow, responding');
        cowPort.send('oink');
        oinks++;
      } else {
        assert(sheep);
        String msg2 = await sheepPort.readItem<String>();
        if (msg2 == 'done') {
          log('pig', 'sheep gone');
          sheep = false;
          continue;
        }
        log('pig', 'got $msg2 from sheep, responding');
        sheepPort.send('oink');
        oinks++;
      }
    }
    //log('pig', '${cow ? 'Moo??' : 'ok'}/${sheep ? 'Baa??' : 'ok'}/${oinks}');
    assert(oinks == 50 || !cow && !sheep);
    while (oinks < 50) {
      log('pig', 'oink');
      oinks++;
    }
    log('pig', 'got tired');
    cowPort.send('done');
    sheepPort.send('done');
    log('pig', 'done');
    Isolate.exit();
  } catch (e) {
    print('PIG ERROR: $e');
  }
}
