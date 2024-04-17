import 'dart:isolate';

import 'srp.dart';

Future<IsolatePort> registerIsolate(String name) async {
  ReceivePort _port = ReceivePort();
  Isolate isolate = await Isolate.spawnUri(
    Uri(path: '$name.dart'),
    [],
    _port.sendPort,
  );
  SRPWrapper port = SRPWrapper(_port, 'main2$name');
  log('main', 'registered $name');
  return (isolate, port, name);
}

Future<SendPort> setupPorts(IsolatePort from, IsolatePort to) async {
  SendPort port = await to.$2.readItem<SendPort>();
  from.$2.send(port);
  log('main', 'registered ${from.$3}2${to.$3}');
  return port;
}

Future<void> awaitReady(IsolatePort isolate) async {
  String msg = await isolate.$2.readItem<String>();
  assert(msg == 'ready');
  log('main', '${isolate.$3} ready');
}

typedef IsolatePort = (Isolate, SRPWrapper, String);
void main() async {
  try {
    IsolatePort cow = await registerIsolate('cow');
    IsolatePort pig = await registerIsolate('pig');
    IsolatePort grass = await registerIsolate('grass');
    IsolatePort sheep = await registerIsolate('sheep');
    await setupPorts(cow, pig);
    await setupPorts(sheep, pig);
    await setupPorts(cow, grass);
    await setupPorts(sheep, grass);
    await awaitReady(cow);
    await awaitReady(pig);
    await awaitReady(grass);
    await awaitReady(sheep);
    log('main', 'done');
    //Isolate.exit();
  } catch (e) {
    print('MAIN ERROR: $e');
  }
}
