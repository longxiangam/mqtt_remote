# 舵机远程控制系统

这是一个基于MQTT协议的舵机远程控制系统，包含Flutter客户端和LuatOS设备端程序。系统支持实时控制、参数调节和定时任务等功能。

## 系统架构

### 客户端 (Flutter)
- 使用Flutter开发的跨平台控制应用
- 通过MQTT协议与设备通信
- 支持实时控制和定时任务管理

### 设备端 (LuatOS)
- 基于ESP32C3开发板
- 运行LuatOS系统
- 控制舵机执行动作
- 支持WiFi连接和MQTT通信

## 功能特性

### 实时控制
- 快捷按键：轻按、重按预设动作
- 参数控制：可调节时间和角度
- 设备重启功能

### 参数设置
- 执行时间（秒）可调
- 舵机角度可调（角度越小越往下）
- 实时参数下发

### 定时任务
- 支持多个定时任务
- 每个任务可设置：
  - 执行时间
  - 启用状态
  - 执行次数
- 定时任务的读取与保存

### 系统监控
- 设备连接状态显示
- 操作日志实时显示
- 日志清空功能

## 通信协议

### MQTT主题
- 发布主题：/luatos/pub/pc
- 订阅主题：/luatos/sub/ep32c3-1

## 项目结构

```
├── lib/
│   └── main.dart          // Flutter应用主程序
├── pwmduoji/
│   ├── main.lua           // LuatOS设备端程序
│   └── index.html         // Web控制页面
├── luatos/
│   └── LuatOS-SoC_V1004_ESP32C3_BLE_USB.soc         // LuatOS 固件
├── 3dprint/                // 3d打印模型
└── README.md
```

## 开发环境
- Flutter SDK
- LuatOS IDE
- MQTT服务器
