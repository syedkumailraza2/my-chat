import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mychat/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio dio = Dio();
  List<dynamic> jsonList = [];
  bool isLoading = true; // Track loading state
  GetStorage box = GetStorage();

  @override
  void initState() {
    super.initState();
    getUsers();
  }

Future<void> getUsers() async {
  try {
    var response = await dio.get(
      'https://mychat-backend-fml5.onrender.com/user',
    );

    if (response.statusCode == 200) {
      List<dynamic> allUsers = response.data as List<dynamic>;

      // Replace 'currentUserId' with the actual variable storing the logged-in user's ID
      String currentUserId = box.read('mySocketId') ?? 'No User';; 

      setState(() {
        jsonList = allUsers.where((user) => user['id'] != currentUserId).toList();
        isLoading = false;
      });
    } else {
      print('Response status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching users: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), //#F5F5F5
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('My Chat'),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                // ✅ Added Pull-to-Refresh
                onRefresh: getUsers, // Calls getUsers() when pulled down
                child: Container(
                  padding: EdgeInsets.only(
                    top: 20,
                    right: 10,
                    left: 10,
                  ), // ✅ Correct
                  child: ListView.builder(
                    itemCount: jsonList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatScreen(
                                        receiverName: jsonList[index]['name'],
                                        receiverId: jsonList[index]['socketId'],
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ), // Adjust spacing as needed
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12)
                                  ),

                                width: 450,
                                height: 77,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    12,
                                  ), // Inner padding for content
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start, // Align text to the left
                                    children: [
                                      Text(
                                        jsonList[index]['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ), // Space between name and email
                                      Text(
                                        jsonList[index]['email'],
                                        style: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10), // Add spacing
                        ],
                      );
                    },
                  ),
                ),
              ),
    );
  }
}
