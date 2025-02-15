import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '远程控制',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '远程控制'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> logList = [];
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  void clearLog(){
    setState(() {
      logList.clear();
      _logTextController.text = logList.join('\n');
    }); 
  }
  
  void addLog(String log) {
    setState(() {
      logList.add("${DateTime.now()} : {$log}");
      _logTextController.text = logList.join('\n');
    });
  }
  final TextEditingController _logTextController = TextEditingController();
  TextEditingController _mqttUrlController = new TextEditingController(text:"");
  TextEditingController _secondController = new TextEditingController(text:"1");
  TextEditingController _angleController = new TextEditingController(text:"130");
  int mqttState = 0;//0 未连接 1 已连接
  void _onConnectButton(){
    if(mqttState == 0){
      connect();
    }else{
      client.disconnect();
    }
  }
  void _onShortButton(){
    if(mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      builder3.addString('{"action":"trigger","second":1,"angle":100}');
      print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIPTION >>>>');
      client.publishMessage(
          "/luatos/sub/ep32c3-1", MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onLongButton(){
    if(mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      builder3.addString('{"action":"trigger","second":1,"angle":80}');
      print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIPTION >>>>');
      client.publishMessage(
          "/luatos/sub/ep32c3-1", MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onParamsButton(){
    if(mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      String second =  _secondController.value.text.toString();
      String angle =  _angleController.value.text.toString();
      builder3.addString('{"action":"trigger","second":$second,"angle":$angle}');
      print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIPTION >>>>');
      client.publishMessage(
          "/luatos/sub/ep32c3-1", MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onRebootButton() {
    if (mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      String second = _secondController.value.text.toString();
      String angle = _angleController.value.text.toString();
      builder3.addString('{"action":"reboot"}');
      print('EXAMPLE:: <<<< PUBLISH 3 - NO SUBSCRIPTION >>>>');
      client.publishMessage(
          "/luatos/sub/ep32c3-1", MqttQos.atLeastOnce, builder3.payload!);
    }
  }
    @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(onPressed: _onConnectButton, child:  Text(
              mqttState == 0 ? '连接':'已连接',
            )),
            TextButton(onPressed: _onShortButton, child:  Text(
              '轻按',
            )),
            TextButton(onPressed: _onLongButton, child:  Text(
              '重按',
            )),

            Text("时间（秒）"),
            TextField(controller: _secondController,),
            Text("角度越小越往下"),
            TextField(controller:_angleController),
            TextButton(onPressed: _onParamsButton, child:  Text(
              '参数控制',
            )),
            TextButton(onPressed: _onRebootButton, child:  Text(
              '重启',
            )),
            ElevatedButton(
              onPressed: () {
                // 添加一条日志示例
                clearLog();
              },
              child: Text('清空日志'),
            ),
            Expanded(
              child: TextField(
                controller: _logTextController,
                maxLines: null, // 允许无限多行
                readOnly: true, // 设置为只读，防止用户编辑
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '接收日志',
                ),
              ),
            ),
          /*  Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
*/

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


  MqttServerClient client= MqttServerClient.withPort(
      '', 'flutter_client', 8883);


  Future<MqttServerClient> connect() async {

    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
;

    final connMessage = MqttConnectMessage()
        .authenticateAs('longxiang', '')
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.keepAlivePeriod = 60;
    client.connectionMessage = connMessage;
    client.secure = true;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
    const topic = '/luatos/pub/pc'; // Not a wildcard topic
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final payload =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      //MqttPublishPayload.bytesToStringAsString(message.toString());
      addLog(payload);
      print('Received message:$payload from topic: ${c[0].topic}>');
      print("Received message");
    });

    return client;
  }


// 连接成功
  void onConnected() {
    print('Connected');
    setState(() {
      mqttState = 1;
    });
  }

// 连接断开
  void onDisconnected() {
    print('Disconnected');
    setState(() {
      mqttState = 0;
    });
  }

// 订阅主题成功
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

// 订阅主题失败
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

// 成功取消订阅
  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

// 收到 PING 响应
  void pong() {
    print('Ping response client callback invoked');
  }

}
