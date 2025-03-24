import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'socket_service.dart';

class VideoCallService {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  final socketService = SocketService();

Future<void> initRenderers() async {
  try {
    await _requestPermissions(); // Request permissions

    await localRenderer.initialize();
    await remoteRenderer.initialize();
    print("✅ Renderers initialized");
  } catch (e) {
    print("❌ Error initializing renderers: $e");
  }
}

Future<void> _requestPermissions() async {
  var statusCamera = await Permission.camera.request();
  var statusMicrophone = await Permission.microphone.request();

  if (statusCamera.isDenied || statusMicrophone.isDenied) {
    print("❌ Camera or Microphone permission denied");
    return;
  }
}


  Future<void> startCall() async {
    await _createPeerConnection();
    await _getUserMedia();
    
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    socketService.socket.emit("user:call", {
      "to": "PARTNER_SOCKET_ID",
      "offer": offer.toMap(),
    });
  }

  Future<void> acceptCall(Map<String, dynamic> data) async {
    await _createPeerConnection();
    await _getUserMedia();

    RTCSessionDescription offer =
        RTCSessionDescription(data["offer"]["sdp"], data["offer"]["type"]);
    await _peerConnection!.setRemoteDescription(offer);

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    socketService.socket.emit("call:accepted", {
      "to": data["from"],
      "answer": answer.toMap(),
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
    });

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
  }

Future<void> _getUserMedia() async {
  try {
    _localStream = await navigator.mediaDevices.getUserMedia({
      "video": true,
      "audio": true,
    });

    localRenderer.srcObject = _localStream;
    _localStream!.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    print("✅ Media stream initialized");
  } catch (e) {
    print("❌ Error getting user media: $e");
  }
}

  void dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
