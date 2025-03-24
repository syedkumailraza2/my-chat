import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mychat/screens/home_screen.dart';
import 'package:mychat/screens/signup_screen.dart';

class LoginPage extends StatefulWidget {
  final String socketId;
  const LoginPage({super.key, required this.socketId});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final box = GetStorage();
  final dio = Dio();

  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<Response<dynamic>> createUser() async {
    try {
      var response = await dio.post(
        'https://mychat-backend-fml5.onrender.com/user/login',
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      var socketId = response.data['user']['socketId'];
      print('SocketId: $socketId');

      box.write('mySocketId', socketId);

      print('User Login ${response}');
      return response; // ✅ Now returning the response properly
    } catch (e) {
      print('Error while logging user: ${e}');
      rethrow; // ✅ Re-throwing error to handle it outside
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo or Image (optional)
                Container(
                  width: 100,
                  height: 100,
                  child: Image(
                    image: AssetImage('assets/login.png'),
                    )),
                //Icon(Icons.person_outline_outlined, size: 100, color: Colors.black),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    border:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Sign up button
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // createUser();

                      try {
                        var response = await dio.post(
                          'https://mychat-backend-fml5.onrender.com/user/login',
                          data: {
                            'email': _emailController.text,
                            'password': _passwordController.text,
                          },
                        );

                        var socketId = response.data['user']['socketId'];
                        print('SocketId: $socketId');

                        box.write('mySocketId', socketId);

                        print('User Login ${response}');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response.data['message'].toString()),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      } catch (e) {
                        print('Error while logging user: ${e}');
                        rethrow; // ✅ Re-throwing error to handle it outside
                      }
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New user?', style: TextStyle(color:Color(0xFF4B5563), fontSize: 16),),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SignupPage(socketId: widget.socketId),
                          ),
                        );
                      },
                      child: const Text('Signup', style: TextStyle(color:Colors.black, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
