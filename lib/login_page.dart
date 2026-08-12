import 'package:flutter/material.dart';
import 'register_page.dart';
import 'home_page.dart';
class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final _formKey = GlobalKey<FormState>();

TextEditingController _emailController = TextEditingController();
TextEditingController _passwordController = TextEditingController();

bool? _value = false;

class _LoginPageState extends State<LoginPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text("login page"),),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 24,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                      "Welcome to Login Page",
                      textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Enter your Email",
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: "Enter your Password",
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  CheckboxListTile(
                      value: _value,
                      title: const Text("Remember Me"),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? newValue){
                      setState(() {
                        _value = newValue ?? false;
                      });
                  }),

                  const SizedBox(height: 20),

                  TextButton(
                      onPressed: (){},
                      child: const Text("Forgot Password",
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                      )
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                      onPressed: (){
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const HomePage()));
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.blue),
                      ),
                      child: const Text("Login",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                      onPressed: (){
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const RegisterPage()));},
                      child: const Text("Don't have an account? Sign Up")
                  ),

                  ],
                )
              )
            ),
          ),
        ),
       );
    }
}