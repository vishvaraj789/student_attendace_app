import 'package:flutter/material.dart';
import 'package:student_attendace_app/student_list_screen.dart';

class HomePage  extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
        centerTitle: true,
      ),
      body: Center(
      child: TextButton(onPressed: (){
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => StudentListScreen()));
      }, child: const Text("Student list"))
      ),
    );
  }
}