import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  void initState() {
    super.initState();
    _getData().then((data) {
      if (data == null) {
        setState(() {
          Text("0 Tarefas Adicionadas",
              style: TextStyle(color: Colors.redAccent));
        });
      }
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  List _toDoList = [];
  final TextEditingController taskController = TextEditingController();
  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPos;

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _getData() async {
    final file = await _getFile();
    return file.readAsString();
  }

  void _addTask() {
    setState(() {
      Map<String, dynamic> newTask = Map();
      newTask["title"] = taskController.text;
      taskController.text = "";
      newTask["ok"] = false;
      _toDoList.add(newTask);
    });
    _saveData();
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b) {
        if (a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  Widget _buildItem(context, index) {
    return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();

            final undo = SnackBar(
              backgroundColor: Colors.redAccent,
              closeIconColor: Colors.white,
              content: Text("Tarefa \"${_lastRemoved?["title"]}\" removida!"),
              action: SnackBarAction(
                label: "Desfazer",
                textColor: Colors.white,
                onPressed:(){
                  setState(() {
                    _toDoList.insert(_lastRemovedPos!, _lastRemoved);
                    _saveData();
                  });
                }),
              duration: Duration(seconds: 2),
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(undo);
          });
        },
        background: Container(
            color: Colors.red,
            child: Align(
                alignment: Alignment(-0.9, 0),
                child: Icon(Icons.delete, color: Colors.white)
            )
        ),
        child: CheckboxListTile(
            secondary: CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(_toDoList[index]["ok"] ? Icons.done : Icons.error,
                    color: Colors.white)),
            title: Text(_toDoList[index]["title"]),
            value: _toDoList[index]["ok"],
            activeColor: Colors.redAccent,
            onChanged: (done) {
              setState(() {
                _toDoList[index]["ok"] = done;
              });
              _saveData();
            })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
            padding: EdgeInsets.fromLTRB(15, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                ElevatedButton(
                    onPressed: _addTask,
                    child: Text("ADD"),
                    style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => Colors.redAccent),
                        foregroundColor: MaterialStateColor.resolveWith(
                            (states) => Colors.white)))
              ],
            )),
        Expanded(
            child: RefreshIndicator(
              color: Colors.redAccent,
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: _buildItem),
            ))
      ]),
    );
  }
}