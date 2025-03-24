import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mychat/services/socket_service.dart';
import 'package:mychat/services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String username;
  final String room;
  VideoCallScreen({required this.username, required this.room});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final videoCallService = VideoCallService();
  final socketService = SocketService();

  @override
  void initState() {
    super.initState();
    videoCallService.initRenderers();

    socketService.connect();

    socketService.socket.emit("room:join", {
      "username": widget.username,
      "room": widget.room,
    });

    socketService.socket.on("call:start", (_) {
      print("Another user joined. Starting call...");
      videoCallService.startCall();
    });

    socketService.socket.on("incoming:call", (data) {
      videoCallService.acceptCall(data);
    });
  }

  @override
  void dispose() {
    videoCallService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Room: ${widget.room}")),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(videoCallService.localRenderer, mirror: true)),
          Expanded(child: RTCVideoView(videoCallService.remoteRenderer)),
        ],
      ),
    );
  }
}
