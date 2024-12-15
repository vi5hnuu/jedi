import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/utility.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

final uuid=Uuid();
class Result {
  final List<TreeNode<NodeData>>? data;
  final String? error;

  Result({this.data, this.error});
}

class NodeData{
  String? key;
  dynamic value;//primitive
  Map<String,dynamic>? extras;
  
  NodeData({this.value,this.key,this.extras});
}

TreeNode<NodeData> _createNode(String? dataKey,dynamic value){
  final node = TreeNode<NodeData>(key: uuid.v4(),data: NodeData(key: dataKey));
  if(value is! List && value is! Map){
    node.data=NodeData(key: dataKey,value: value);
  }else{
    node.addAll(_getNodes(value));
  }
  return node;
}

List<TreeNode<NodeData>> _getNodes(dynamic jsonData,[TreeNode? parent]){
  final nodes = <TreeNode<NodeData>>[];

  if (jsonData is Map) {
    jsonData.forEach((key, value) {
      // Sanitize the key by replacing period (.) with an underscore (_)
      final sanitizedDataKey = key.replaceAll('.', '#');
      final node=_createNode(sanitizedDataKey,value);
      parent?.add(node);
      nodes.add(node);
    });
  } else if (jsonData is List) {
    for (int itemNo=0;itemNo<jsonData.length;itemNo++) {
      final item=jsonData[itemNo];
      final node=_createNode(null, item);
      node.data?.extras={'index':itemNo};
      nodes.add(node);
    }
  } else {
    final node = _createNode(null, jsonData);
    nodes.add(node);
  }
  return nodes;
}

Future<void> jsonNodesInChunks(List<Object> args) async {
  final File jsonFile = args[0] as File;
  final SendPort sendPort = args[1] as SendPort;

  try {
    final jsonData = jsonDecode(await jsonFile.readAsString());

    final List<TreeNode<NodeData>> nodes=_getNodes(jsonData);
    for(int i=0;i<nodes.length;i+=20){
      sendPort.send(Result(data: nodes.sublist(i,min(nodes.length, i+20))));
      await Future.delayed(Duration(milliseconds: 500));
    }
    sendPort.send(null);
  } catch (e) {
    sendPort.send(Result(error: (e is FormatException) ? e.message : 'Failed to read json file'));
    sendPort.send(null); // Indicate completion in case of error.
  }
}


class JsonEditor extends StatefulWidget {
  final File jsonFile;

  const JsonEditor({super.key,required this.jsonFile});

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  final _contentStream=BehaviorSubject<List<TreeNode<NodeData>>>();
  ValueNotifier<bool> isStreamClosed=ValueNotifier(false);
  Isolate? _isolate;
  var contentLoading=false;
  String? contentError;
  String? content;

  @override
  void initState() {
    if(!Utility.isJsonFile(widget.jsonFile) || !widget.jsonFile.existsSync()) throw Exception("Dev error");
    _startPrettifying();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<List<TreeNode<NodeData>>>(
          stream: _contentStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  TreeView.simple(
                    key: ValueKey('tree'),
                      indentation: const Indentation(width: 16,style: IndentStyle.roundJoint,thickness: 2,color: Constants.green600),
                      shrinkWrap: true,
                      showRootNode: false,
                      expansionIndicatorBuilder: (_, tree) => PlusMinusIndicator(tree: tree,alignment: Alignment.centerRight,color: Constants.green600),
                      expansionBehavior: ExpansionBehavior.none,
                      focusToNewNode: false,
                      tree: TreeNode.root()..addAll(snapshot.data!),
                      builder: (context, node) {
                        final nodeval=node.data as NodeData;
                        final key=nodeval.key ?? (nodeval.extras?['index'] is int && node.level==1 ? ('Index ${nodeval.extras?['index']}').toString() : null) ?? '';
                        // build your node item here
                        // return any widget that you need
                        return   Padding(
                          key: ValueKey(node.key),
                          padding: const EdgeInsets.symmetric(horizontal: 36.0,vertical: 8.0),
                          child: RichText(text:TextSpan(text:  key,style: TextStyle(color: Colors.black),children:   [if(key.isNotEmpty && nodeval.value!=null) TextSpan(text:"  :  "),if(nodeval.value!=null) TextSpan(text: nodeval.value)],)),
                        );
                      }),
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
        )
      )),
    );
  }

  Future<void> _startPrettifying() async {
    final receivePort = ReceivePort();

    // Spawn the isolate.
    _isolate = await Isolate.spawn(
      jsonNodesInChunks,
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
        _contentStream.add((_contentStream.valueOrNull ?? [])..addAll(data.data!)); // Add data to the stream.
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
}