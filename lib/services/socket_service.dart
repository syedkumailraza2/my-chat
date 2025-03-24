import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  late IO.Socket socket;

  SocketService._internal() {
    socket = IO.io('http://192.168.0.104:8000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
  }

  void connect() {
    socket.connect();
    socket.onConnect((_) {
      print("Connected to WebSocket Server");
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
