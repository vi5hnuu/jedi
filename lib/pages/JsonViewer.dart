import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/utils/Constants.dart';

class Result {
  final List<String>? data;
  final String? error;

  Result({this.data, this.error});
}

Future<void> prettifyJsonInChunks(List<Object> args) async {
  final File jsonFile = args[0] as File;
  final SendPort sendPort = args[1] as SendPort;

  const encoder = JsonEncoder.withIndent('  '); // Pretty-print with 2 spaces.

  try {
    final content = jsonDecode(await jsonFile.readAsString());
    final prettyContent = encoder.convert(content);

    final lines = prettyContent.split('\n');

    final List<String> partial=[];
    for (final line in lines) {
      partial.add(line);
      await Future.delayed(const Duration(milliseconds: 10));
      sendPort.send(Result(data: partial)); // Send one line at a time.
      await Future.delayed(Duration.zero); // Allow main thread to process.
    }
    sendPort.send(null); // Indicate completion.
  } catch (e) {
    sendPort.send(Result(error: (e is FormatException) ? e.message : 'Failed to read json file'));
    sendPort.send(null); // Indicate completion in case of error.
  }
}

class JsonViewer extends StatefulWidget {
  final File jsonFile;

  const JsonViewer({Key? key, required this.jsonFile}) : super(key: key);

  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  final _contentStream=StreamController<List<String>>();
  Isolate? _isolate;

  @override
  void initState() {
    super.initState();
    _startPrettifying();
  }

  Future<void> _startPrettifying() async {
    _killIsolate();
    final receivePort = ReceivePort();

    // Spawn the isolate.
    _isolate = await Isolate.spawn(
      prettifyJsonInChunks,
      [widget.jsonFile, receivePort.sendPort],
    );

    // Listen for data from the isolate.
    receivePort.listen((data) {
      if (data == null) {
        receivePort.close();
      } else if((data as Result).error!=null) {
        if(!_contentStream.isClosed) _contentStream.addError(data.error!); // Add data to the stream.
      }else {
        if(!_contentStream.isClosed) _contentStream.add(data.data!); // Add data to the stream.
      }
    });
  }

  _killIsolate(){
    _isolate?.kill(priority: Isolate.immediate);
  }

  @override
  void dispose() {
    _killIsolate();
    _contentStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JSON Viewer"),
      ),
      body: StreamBuilder<List<String>>(
        stream: _contentStream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(itemCount: snapshot.data!.length,itemBuilder: (context, index) {
              return Text(snapshot.data![index]);
            },);
          }else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                  IconButton(onPressed: _startPrettifying, icon: Icon(Icons.refresh,color: Colors.red,size: 32,))
                ],
              ),
            );
          } else {
            return const Center(child: SpinKitThreeBounce(color: Constants.green600));
          }
        },
      ),
    );
  }
}
