import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    getUsers(); 
  }

  Future<void> getUsers() async {
    try {
      var response = await dio.get('https://mychat-backend-fml5.onrender.com/user');
      if (response.statusCode == 200) {
        setState(() {
          jsonList = response.data as List<dynamic>;
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
      appBar: AppBar(
        title: const Text('My Chat'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( // ✅ Added Pull-to-Refresh
              onRefresh: getUsers, // Calls getUsers() when pulled down
              child: ListView.builder(
                itemCount: jsonList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverName: jsonList[index]['name'],
                            receiverId: jsonList[index]['socketId'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(jsonList[index]['name']),
                        subtitle: Text(jsonList[index]['email']),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
