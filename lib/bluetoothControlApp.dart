import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothControlApp extends StatefulWidget {
  const BluetoothControlApp({super.key});

  @override
  State<BluetoothControlApp> createState() => _BluetoothControlAppState();
}

class _BluetoothControlAppState extends State<BluetoothControlApp> {
  // Trạng thái kết nối
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;

  // Trạng thái giao diện
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _showDeviceList = false;
  String _statusText = 'Đang khởi tạo...';
  
  final _dataController = StreamController<String>.broadcast();

  // Dữ liệu ứng dụng
  List<BluetoothDevice> _devices = [];
  List<bool> _relayStates = List.generate(9, (index) => false);
  String _currentBinaryStatus = "000000000";

  // Các thành phần hệ thống
  static const String _prefsKey = 'last_connected_device_address';
  String _dataBuffer = '';
  StreamSubscription<BluetoothState>? _bluetoothStateSubscription;
  StreamSubscription<BluetoothDiscoveryResult>? _scanSubscription;
  Timer? _statusUpdateTimer;

  late Future<bool> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
    _bluetoothStateSubscription = FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      if (mounted) {
        // Rebuild lại widget để FutureBuilder chạy lại và kiểm tra trạng thái mới
        setState(() {}); 
      }
    });
  }

  Future<bool> _initializeApp() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      _statusText = 'Cần cấp quyền để ứng dụng hoạt động.';
      if (mounted) setState(() {});
      return false; 
    }

    bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
    if (!isEnabled && mounted) {
      isEnabled = await _requestBluetoothEnable();
    }

    if (isEnabled && mounted) {
      await _attemptAutoConnect();
    }
    return isEnabled; 
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> _requestBluetoothEnable() async {
    bool? requestResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu Bluetooth'),
        content: const Text('Ứng dụng này cần bật Bluetooth để hoạt động. Bạn có muốn bật nó không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('THOÁT')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('BẬT BLUETOOTH')),
        ],
      ),
    );
    if (requestResult == true) {
      await FlutterBluetoothSerial.instance.requestEnable();
      return true;
    } else {
      SystemNavigator.pop();
      return false;
    }
  }
  
  Future<void> _attemptAutoConnect() async {
    if (_isConnected) return;

    final prefs = await SharedPreferences.getInstance();
    final deviceAddress = prefs.getString(_prefsKey);
    
    if (deviceAddress != null && deviceAddress.isNotEmpty) {
      if (mounted) setState(() => _isConnecting = true);
      _statusText = 'Đang tìm thiết bị đã lưu...';
      
      try {
        await Future.delayed(const Duration(seconds: 1));
        List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
        int deviceIndex = bondedDevices.indexWhere((d) => d.address.toLowerCase() == deviceAddress.toLowerCase());
        
        if (deviceIndex >= 0) {
          await _connectToDevice(bondedDevices[deviceIndex]);
        } else {
          BluetoothDevice tempDevice = BluetoothDevice(name: "ESP32", address: deviceAddress);
          await _connectToDevice(tempDevice);
        }
      } catch (e) {
          if (mounted) setState(() => _statusText = 'Lỗi khi tự động kết nối.');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
    } else {
      if (mounted) setState(() => _statusText = 'Chào mừng! Hãy chọn một thiết bị.');
    }
  }

  Future<void> _saveConnectedDeviceAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, address);
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await _scanSubscription?.cancel();
      if (mounted) setState(() => _isScanning = false);
    } else {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần quyền vị trí để quét tìm thiết bị.')));
        openAppSettings();
        return;
      }

      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devices = bondedDevices;
        _isScanning = true;
      });

      _scanSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        if (mounted) {
          final existingIndex = _devices.indexWhere((device) => device.address == result.device.address);
          if (existingIndex < 0) setState(() => _devices.add(result.device));
        }
      });
      
      _scanSubscription!.onDone(() {
        if(mounted) setState(() => _isScanning = false);
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isScanning) {
      await _scanSubscription?.cancel();
      if (mounted) setState(() => _isScanning = false);
    }
    
    if (mounted) {
      setState(() {
        _isConnecting = true;
        _statusText = 'Đang kết nối tới ${device.name ?? device.address}...';
      });
    }
    
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnected = true;
      _showDeviceList = false;
      _statusText = 'Đã kết nối: ${_connectedDevice?.name ?? _connectedDevice?.address}';
      
      await _saveConnectedDeviceAddress(device.address);
      if (mounted) setState(() {});

      _connection!.input!.listen((Uint8List data) {
        _dataBuffer += utf8.decode(data, allowMalformed: true);
        if (mounted) _processDataBuffer();
      }).onDone(() {
        if (mounted) _disconnect();
      });
      
      _startAutoStatusUpdate();
    } catch (e) {
      if (mounted) _statusText = 'Lỗi kết nối. Hãy đảm bảo thiết bị đã bật và ở gần.';
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }
  
  void _processDataBuffer() {
      while (_dataBuffer.contains('\n')) {
          final endOfPacket = _dataBuffer.indexOf('\n');
          final completePacket = _dataBuffer.substring(0, endOfPacket).trim();
          _dataBuffer = _dataBuffer.substring(endOfPacket + 1);
          if (completePacket.isNotEmpty) _handleCompletePacket(completePacket);
      }
  }
  
  void _handleCompletePacket(String packet) {
      _dataController.add(packet);
      if (packet.length == 9 && RegExp(r'^[01]+$').hasMatch(packet)) {
        _currentBinaryStatus = packet;
        _updateRelayStateFromBinaryString(packet);
      } else {
        _updateRelayStateFromResponse(packet);
      }
      if (mounted) setState(() {});
  }

  Future<void> _disconnect() async {
    _stopAutoStatusUpdate();
    await _connection?.close();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _relayStates = List.generate(9, (index) => false);
        _currentBinaryStatus = "000000000";
        _statusText = 'Đã ngắt kết nối.';
      });
    }
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected) return;
    final fullCommand = '$command\n';
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(fullCommand)));
      await _connection!.output.allSent;
    } catch (e) {
      _disconnect();
    }
  }

  Future<void> _sendRelayCommand(int relayNumber, bool turnOn) async {
    if (mounted) setState(() => _relayStates[relayNumber - 1] = turnOn);
    await _sendCommand('RELAY $relayNumber ${turnOn ? 'ON' : 'OFF'}');
    await Future.delayed(const Duration(milliseconds: 50));
    await _requestStatus();
  }

  Future<void> _turnAllRelaysOn() async {
    if (mounted) setState(() => _relayStates = List.generate(9, (index) => true));
    await _sendCommand('RELAY ALL ON');
    await Future.delayed(const Duration(milliseconds: 50));
    await _requestStatus();
  }
  
  Future<void> _turnAllRelaysOff() async {
    if (mounted) setState(() => _relayStates = List.generate(9, (index) => false));
    await _sendCommand('RELAY ALL OFF');
    await Future.delayed(const Duration(milliseconds: 50));
    await _requestStatus();
  }

  Future<void> _requestStatus() async {
    await _sendCommand('GET_STATUS');
  }

  void _startAutoStatusUpdate() {
    _statusUpdateTimer?.cancel(); 
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isConnected) _requestStatus();
      else timer.cancel();
    });
  }

  void _stopAutoStatusUpdate() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

  void _updateRelayStateFromResponse(String response) {
    final pattern = RegExp(r'RELAY (\d+) (ON|OFF)');
    final match = pattern.firstMatch(response);
    if (match != null) {
      final relayNumber = int.parse(match.group(1)!);
      final isOn = match.group(2) == 'ON';
      if (mounted) setState(() => _relayStates[relayNumber - 1] = isOn);
    }
  }

  void _updateRelayStateFromBinaryString(String binaryString) {
    if (binaryString.length != 9) return;
    final reversedString = binaryString.split('').reversed.join('');
    if (mounted) {
      setState(() {
        for (int i = 0; i < 9; i++) _relayStates[i] = reversedString[i] == '1';
      });
    }
  }

  @override
  void dispose() {
    _bluetoothStateSubscription?.cancel();
    _scanSubscription?.cancel();
    _stopAutoStatusUpdate();
    _connection?.dispose();
    _dataController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        title: const Text('App Điều Khiển LED'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.bluetooth_drive),
            label: Text(_showDeviceList ? 'Ẩn DS' : 'Hiện DS'),
            onPressed: () => setState(() => _showDeviceList = !_showDeviceList),
          ),
          if (_isConnected)
            IconButton(icon: const Icon(Icons.link_off), onPressed: _disconnect),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang khởi tạo ứng dụng...'),
                ],
              ),
            );
          }
          
          final isBluetoothOn = snapshot.data ?? false;

          if (isBluetoothOn) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatusPanel(),
                  if (_showDeviceList) _buildDeviceList(),
                  if (_isConnected) _buildRelayControlPanel(),
                ],
              ),
            );
          } else {
            return _buildBluetoothDisabledMessage();
          }
        },
      ),
    );
  }

  Widget _buildBluetoothDisabledMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Bluetooth đang tắt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Vui lòng bật Bluetooth để sử dụng ứng dụng.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializationFuture = _initializeApp();
              });
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    IconData statusIcon;
    Color statusColor;
    if (_isConnecting) {
      statusIcon = Icons.sync;
      statusColor = Colors.orange;
    } else if (_isConnected) {
      statusIcon = Icons.bluetooth_connected;
      statusColor = Colors.blue;
    } else {
      statusIcon = Icons.bluetooth_disabled;
      statusColor = Colors.grey;
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: (_isConnecting || _isScanning)
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
            : Icon(statusIcon, color: statusColor),
        title: Text(_statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Danh sách thiết bị', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: ElevatedButton.icon(
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Dừng' : 'Quét mới'),
              onPressed: _toggleScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const Divider(),
          SizedBox(
            height: 200,
            child: _devices.isEmpty
                ? const Center(child: Text('Không có thiết bị nào. Hãy thử quét mới.'))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.devices),
                        title: Text(device.name ?? 'Thiết bị không tên'),
                        subtitle: Text(device.address),
                        trailing: ElevatedButton(
                          onPressed: _isConnecting ? null : () => _connectToDevice(device),
                          child: const Text('Kết nối'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayControlPanel() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Bảng Điều Khiển', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2),
          itemCount: 9,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final relayNumber = index + 1;
            final isOn = _relayStates[index];
            return Card(
              elevation: 4,
              color: isOn ? Colors.blue.shade600 : Colors.grey.shade300,
              child: InkWell(
                onTap: () => _sendRelayCommand(relayNumber, !isOn),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Relay $relayNumber', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isOn ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(isOn ? 'BẬT' : 'TẮT', style: TextStyle(fontSize: 14, color: isOn ? Colors.white70 : Colors.black54)),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.power),
                  label: const Text('BẬT TẤT CẢ'),
                  onPressed: _turnAllRelaysOn,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.power_off),
                  label: const Text('TẮT TẤT CẢ'),
                  onPressed: _turnAllRelaysOff,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            
          ),
        ),
      ],
    );
  }
}