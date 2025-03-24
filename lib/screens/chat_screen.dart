import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mychat/screens/calling_screen.dart';
import 'package:mychat/services/signalling.service.dart';
import 'package:socket_io_client/socket_io_client.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  var socket = SignallingService.instance.socket;
  final box = GetStorage();
  late String userId = box.read('mySocketId') ?? 'No User'; // Get user ID
  final _messageController = TextEditingController();
  late String RoomId;
  final Dio dio = Dio();
  List<dynamic> jsonList = []; 
  dynamic incomingSDPOffer;

@override
void initState() {
  super.initState();
  
  getAllChats();

  if (socket == null || !(socket!.connected)) {
    print("Socket is null or not connected, initializing...");
    socket = SignallingService.instance.socket;
  }

  SignallingService.instance.socket!.on("newCall", (data) {
    print("Incoming Call Event Received: $data");
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });
  


  socket!.onConnect((_) {
    print("Connected to socket");
    joinRoom(userId, widget.receiverId);
  });

  socket!.on("roomJoined", (roomId) {
    if (mounted) {
      setState(() {
        RoomId = roomId;
      });
      print('Joined Room: $RoomId');
      getAllChats();
    }
  });

socket!.on("receiveMessage", (data) {
  if (mounted) {
    setState(() {
      jsonList.add(data); // ✅ Append the new message to the list
    });
  }
  print("New message received: $data");
});

}

@override
void dispose() {
  _messageController.dispose();
  
  // Remove socket listeners
  socket?.off("roomJoined");
  socket?.off("receiveMessage");
  
  super.dispose();
}

_joinCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }

// Fetch all messages for the room
void getAllChats() async {
  if (RoomId.isEmpty) {
    print("Room ID not set yet");
    return;
  }

  try {
    var response = await dio.get('https://mychat-backend-fml5.onrender.com/chat/$RoomId'); 
    if (response.statusCode == 200) {
      setState(() {
        jsonList = response.data as List<dynamic>;
      });
    } else {
      print('Response status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching chats: $e');
  }
}



  void joinRoom(String userId, String receiverId) {
    if (socket == null) {
      print("Socket not initialized yet.");
      return;
    }

    socket!.emit("joinChatRoom", {"userId": userId, "receiverId": receiverId});
  }

  void sendMessage(String message) {
    if (socket == null) {
      print("Socket not initialized yet.");
      return;
    }
    print("Socket initialized propperly. ${socket}");
    print("Sending Message: $message");

    socket!.emit("sendMessage", {
      "senderId": userId,
      "receiverId": widget.receiverId,
      "message": message,
    });

    _messageController.clear(); // Clear input after sending
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () => _joinCall(
                            callerId: userId,
                            calleeId: widget.receiverId,
                          ),
              child: Icon(Icons.video_call)),
          )
        ],
        ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
            children: [
              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  itemCount: jsonList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Align(
                        alignment: jsonList[index]['senderId'] == userId ? Alignment.centerRight : Alignment.centerLeft, // Align messages
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6, // Reduce width to 60% of screen
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: jsonList[index]['senderId'] == userId ? Colors.blueGrey[200] : Colors.blueAccent[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jsonList[index]['message'], style: TextStyle(fontSize: 16,color: Colors.black)),
                              SizedBox(height: 5),
                              Text('Time', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          
              // Message Input Field
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          sendMessage(_messageController.text.trim());
                        }
                      },
                      child: Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (incomingSDPOffer != null)
              Positioned(
                child: ListTile(
                  title: Text(
                    "Incoming Call from ${incomingSDPOffer["callerId"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call_end),
                        color: Colors.redAccent,
                        onPressed: () {
                          setState(() => incomingSDPOffer = null);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.call),
                        color: Colors.greenAccent,
                        onPressed: () {
                          _joinCall(
                            callerId: incomingSDPOffer["callerId"]!,
                            calleeId: userId,
                            offer: incomingSDPOffer["sdpOffer"],
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
        ]
        ),
      ),
    );
  }
}
