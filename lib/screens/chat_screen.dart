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

  final Dio dio = Dio();
  List<dynamic> jsonList = []; 
  dynamic incomingSDPOffer;

String? RoomId; // ✅ Nullable to prevent LateInitializationError

void initState() {
  super.initState();
  print("✅ initState() called");

  if (socket == null || !(socket!.connected)) {
    print("✅ Socket is null or not connected, initializing...");
    socket = SignallingService.instance.socket;

    socket!.onConnect((_) {
      print("✅ Connected to socket");
      joinRoom(userId, widget.receiverId); // 🔥 Debug: Check if this runs
    });

    // ✅ Ensure RoomId is set before fetching chats
    socket!.on("roomJoined", (roomId) {
      print("🔄 Received roomJoined event with roomId: $roomId");
      if (mounted) {
        setState(() {
          RoomId = roomId.toString();
        });
        print('😀 Joined Room: $RoomId');

        // 🔥 Fetch chats only after RoomId is set
        getAllChats();
      }
    });

    // ✅ Listen for incoming messages and update list
    socket!.on("receiveMessage", (data) {
      if (mounted) {
        setState(() {
          jsonList.add(data);
        });
      }
      print("📩 New message received: $data");
    });

    // 🔥 Fallback: Retry fetching chats if RoomId isn't set within 5 sec
    Future.delayed(Duration(seconds: 5), () {
      if (RoomId == null) {
        print("⏳ Room ID not received, retrying getAllChats()...");
        getAllChats();
      }
    });

  } else {
    print("✅ Socket is already connected, checking RoomId...");

    joinRoom(userId, widget.receiverId); 

    socket!.on("roomJoined", (roomId) {
      print("🔄 Received roomJoined event with roomId: $roomId");
      if (mounted) {
        setState(() {
          RoomId = roomId.toString();
        });
        print('😀 Joined Room: $RoomId');

        // 🔥 Fetch chats only after RoomId is set
        getAllChats();
      }
    });

    if (RoomId != null) {
      getAllChats(); 
    } else {
      print("⚠️ Room ID not set yet, waiting for roomJoined event...");
    }
  }
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
  // if (RoomId.isEmpty) {
  //   print("Room ID not set yet");
  //   return;
  // }
  try {
    var response = await dio.get('https://mychat-backend-fml5.onrender.com/chat/$RoomId'); 
    if (response.statusCode == 200) {
      setState(() {
        jsonList = response.data as List<dynamic>;
        print('😀 jsonList $jsonList');
      });
    } else {
      print('🤣🤣Response status code: ${response.statusCode}');
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
                            color: jsonList[index]['senderId'] == userId ? Color(0XFF27272A) : Color(0XFFE3E3E3), //#27272A
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(jsonList[index]['message'], style: TextStyle(fontSize: 16,color: jsonList[index]['senderId'] == userId ? Colors.white : Colors.black,)),
                              SizedBox(height: 5),
                              // Text('Time', 
                              // style: TextStyle(
                              //   fontSize: 12, 
                              //   color: jsonList[index]['senderId'] == userId ? Colors.white : Colors.black,
                              //   )),
                            
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
