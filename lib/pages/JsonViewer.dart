import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/singletons/AdsSingleton.dart';
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
    for (int i=0;i<lines.length;i++) {
      final line=lines[i];
      partial.add(line);
      // await Future.delayed(const Duration(milliseconds: 10));
      if(i+1==lines.length || partial.length%100==0) sendPort.send(Result(data: partial)); // Send one line at a time.
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
  final ScrollController controller=ScrollController();
  final _contentStream=StreamController<List<String>>();
  ValueNotifier<bool> isStreamClosed=ValueNotifier(false);
  Isolate? _isolate;

  @override
  void initState() {
    AdsSingleton().dispatch(LoadInterstitialAd());
    super.initState();
    _startPrettifying();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JSON Viewer"),
        actions: [
          IconButton(onPressed: ()=>controller.jumpTo(controller.position.minScrollExtent), icon: Icon(Icons.first_page)),
          ValueListenableBuilder(valueListenable:isStreamClosed, builder: (context, value,child) => !_contentStream.isClosed ? const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: SpinKitThreeBounce(color: Constants.green100,size: 12),
          ) : IconButton(onPressed: ()=>controller.jumpTo(controller.position.maxScrollExtent), icon:  Icon(Icons.last_page)),)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<String>>(
          stream: _contentStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  ListView.builder(
                    controller: controller,
                    scrollDirection: Axis.vertical,
                    itemCount: snapshot.data!.length,itemBuilder: (context, index) {
                    return Text(snapshot.data![index],
                      softWrap: true,
                      textAlign: TextAlign.start, );
                  },),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black,borderRadius: BorderRadius.circular(4)),
                      child: RichText(text: TextSpan(text: "Total lines : ",children: [TextSpan(text:"${snapshot.data!.length}",style: TextStyle(fontWeight: FontWeight.bold))])),
                    ),
                  )
                ],
              );
            }else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else {
              return const Center(child: SpinKitThreeBounce(color: Constants.green600));
            }
          },
        ),
      ),
    );
  }

  Future<void> _startPrettifying() async {
    final receivePort = ReceivePort();

    // Spawn the isolate.
    _isolate = await Isolate.spawn(
      prettifyJsonInChunks,
      [widget.jsonFile, receivePort.sendPort],
    );

    // Listen for data from the isolate.
    receivePort.listen((data) {
      if(_contentStream.isClosed) return;
      if (data == null) {
        _contentStream.close();
        isStreamClosed.value=true;
        receivePort.close();
      } else if((data as Result).error!=null) {
        _contentStream.addError(data.error!); // Add data to the stream.
        _contentStream.close();
        isStreamClosed.value=true;
      }else {
        _contentStream.add(data.data!); // Add data to the stream.
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
    controller.dispose();
    super.dispose();
  }

}
