import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TimerSetting {
  String time;
  bool enable;
  int volume;

  TimerSetting({
    required this.time,
    required this.enable,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'enable': enable,
    'volume': volume,
  };

  factory TimerSetting.fromJson(Map<String, dynamic> json) => TimerSetting(
    time: json['time'],
    enable: json['enable'],
    volume: json['volume'],
  );
}

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
  TextEditingController _mqttUrlController = TextEditingController();
  TextEditingController _mqttUserController = TextEditingController();
  TextEditingController _mqttPasswordController = TextEditingController();
  TextEditingController _secondController = new TextEditingController(text:"1");
  TextEditingController _angleController = new TextEditingController(text:"130");
  int mqttState = 0;//0 未连接 1 已连接
  List<TimerSetting> timerSettings = [];
  
  // 添加一个控制展开/收起的状态变量
  bool _isMqttConfigExpanded = false;
  
  // 添加设备ID控制器
  TextEditingController _deviceIdController = TextEditingController();
  
  // 添加获取主题的方法
  String getSubscribeTopic() {
    return '/luatos/pub/pc';
  }
  
  String getPublishTopic() {
    return '/luatos/sub/${_deviceIdController.text}';
  }
  
  @override
  void initState() {
    super.initState();
    _loadMqttSettings();
  }

  Future<void> _loadMqttSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mqttUrlController.text = prefs.getString('mqtt_url') ?? '';
      _mqttUserController.text = prefs.getString('mqtt_user') ?? '';
      _mqttPasswordController.text = prefs.getString('mqtt_password') ?? '';
      _deviceIdController.text = prefs.getString('device_id') ?? 'ep32c3-1';
    });
  }

  Future<void> _saveMqttSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_url', _mqttUrlController.text);
    await prefs.setString('mqtt_user', _mqttUserController.text);
    await prefs.setString('mqtt_password', _mqttPasswordController.text);
    await prefs.setString('device_id', _deviceIdController.text);
  }

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
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onLongButton(){
    if(mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      builder3.addString('{"action":"trigger","second":1,"angle":80}');
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onParamsButton(){
    if(mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      String second =  _secondController.value.text.toString();
      String angle =  _angleController.value.text.toString();
      builder3.addString('{"action":"trigger","second":$second,"angle":$angle}');
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _onRebootButton() {
    if (mqttState == 1) {
      final builder3 = MqttClientPayloadBuilder();
      builder3.addString('{"action":"reboot"}');
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder3.payload!);
    }
  }
  void _readTimerSettings() {
    if(mqttState == 1) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"action":"read_timer"}');
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _saveTimerSettings() {
    if(mqttState == 1) {
      final builder = MqttClientPayloadBuilder();
      Map<String, dynamic> payload = {
        'action': 'save_timer',
        'timer_setting': timerSettings.map((e) => e.toJson()).toList(),
      };
      builder.addString(json.encode(payload));
      client.publishMessage(
          getPublishTopic(), MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _addTimerSetting() {
    setState(() {
      final time = DateTime.now();
      timerSettings.add(TimerSetting(
        time: "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
        enable: true,
        volume: 1,
      ));
    });
  }

  void _removeTimerSetting(int index) {
    setState(() {
      timerSettings.removeAt(index);
    });
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              
              Card(
                child: ExpansionTile(
                  initiallyExpanded: _isMqttConfigExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isMqttConfigExpanded = expanded;
                    });
                  },
                  title: Row(
                    children: [
                      Text('MQTT 配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '(${_mqttUrlController.text})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text("服务器", textAlign: TextAlign.right),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextField(controller: _mqttUrlController),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text("用户名", textAlign: TextAlign.right),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextField(controller: _mqttUserController),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text("密码", textAlign: TextAlign.right),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _mqttPasswordController,
                                  obscureText: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text("设备ID", textAlign: TextAlign.right),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextField(controller: _deviceIdController),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                _saveMqttSettings();
                                setState(() {
                                  _isMqttConfigExpanded = false;
                                });
                              },
                              child: Text('保存配置'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // 第一行：连接、轻按、重按、重启按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _onConnectButton,
                    child: Text(mqttState == 0 ? '连接' : '已连接'),
                  ),
                  TextButton(
                    onPressed: _onShortButton,
                    child: Text('轻按'),
                  ),
                  TextButton(
                    onPressed: _onLongButton,
                    child: Text('重按'),
                  ),
                  TextButton(
                    onPressed: _onRebootButton,
                    child: Text('重启'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // 参数控制容器
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('参数控制', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                   
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("时间（秒）", textAlign: TextAlign.right),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextField(controller: _secondController),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text("角度越小越往下", textAlign: TextAlign.right),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextField(controller: _angleController),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                   
                    Center(
                      child: ElevatedButton(
                        onPressed: _onParamsButton,
                        child: Text('发送'),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // 定时设置标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('定时设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _readTimerSettings,
                        child: Text('读取'),
                      ),
                      TextButton(
                        onPressed: _saveTimerSettings,
                        child: Text('保存'),
                      ),
                      TextButton(
                        onPressed: _addTimerSetting,
                        child: Text('添加'),
                      ),
                    ],
                  ),
                ],
              ),
              
              // 定时设置列表
              Column(
                children: List.generate(timerSettings.length, (index) {
                  final timer = timerSettings[index];
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() {
                                    timer.time = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                              child: Text(timer.time),
                            ),
                          ),
                          Switch(
                            value: timer.enable,
                            onChanged: (value) {
                              setState(() {
                                timer.enable = value;
                              });
                            },
                          ),
                          SizedBox(
                            width: 50,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '次数',
                              ),
                              controller: TextEditingController(
                                  text: timer.volume.toString()),
                              onChanged: (value) {
                                timer.volume = int.tryParse(value) ?? 1;
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeTimerSetting(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 20),
              
              // 日志区域标题和清空按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('接收日志', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: clearLog,
                    child: Text('清空日志'),
                  ),
                ],
              ),
              
              // 日志显示区域
              Container(
                height: 200,
                child: TextField(
                  controller: _logTextController,
                  maxLines: null,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
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
      'vafd5285.ala.cn-hangzhou.emqxsl.cn', 'flutter_client', 8883);


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
        .authenticateAs(_mqttUserController.text, _mqttPasswordController.text)
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
    final topic = getSubscribeTopic();
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      if (payload.startsWith('json:')) {
        final jsonStr = payload.substring(5);
        final jsonData = json.decode(jsonStr);
        
        if (jsonData['action'] == 'read_timer') {
          setState(() {
            timerSettings = (jsonData['timer_setting'] as List)
                .map((e) => TimerSetting.fromJson(e))
                .toList();
          });
        }
      }
      
      addLog(payload);
      print('Received message:$payload from topic: ${c[0].topic}>');
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
