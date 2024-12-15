import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/singletons/NotificationService.dart';
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

Future<String> serializeTree(List<TreeNode<NodeData>> tree){
  final List<dynamic> data=[];
  for(final node in tree){
    // if(node.data!.toSerializable())
  }
  return Future.value("");
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
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'save':
                  _saveFile();
                  break;
                case 'copy_to_clipboard':
                  _copyToClipboard(_contentStream.value);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Text('Save File'),
              ),
              const PopupMenuItem(
                value: 'copy_to_clipboard',
                child: Text('Copy to Clipboard'),
              ),
            ],
          ),
        ],
      ),
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
                        final indexKey=(nodeval.extras?['index'] is int && node.level==1 ? ('Index ${nodeval.extras?['index']}').toString() : null);
                        final key=nodeval.key ?? indexKey  ?? '';
                        return   Padding(
                          key: ValueKey(node.key),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 4.0),
                          child: RichText(text: buildInteractiveTextSpanWithBorder(
                                        key: key,
                                        value: nodeval.value,
                                        onKeyTap: nodeval.key == null ? null : () => _onKeyChange(node as TreeNode<NodeData>),
                                        onValueTap: nodeval.value == null ? null : () => _onValueChange(node as TreeNode<NodeData>))),
                        );
                      }),
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

  Future<void> _saveFile() async {
    // try {
    //   final file = File(widget.jsonFile.path);
    //   await file.writeAsString(widget.jsonTree.toString());
    //   _showSnackbar('File saved successfully at $_filePath');
    // } catch (e) {
    //   _showSnackbar('Failed to save file: $e');
    // }
  }

  // Copy to Clipboard Logic
  Future<void> _copyToClipboard(List<TreeNode<NodeData>> tree) async {
    // try {
    //   await Clipboard.setData(ClipboardData(text: widget.jsonTree.toString()));
    //   NotificationService.showSnackbar(text: 'JSON copied to clipboard',color: Colors.green);
    // } catch (e) {
    //   NotificationService.showSnackbar(text: 'Failed to copy to clipboard',color: Colors.red);
    // }
  }

  _killIsolate(){
    _isolate?.kill(priority: Isolate.immediate);
  }

  _onKeyChange(TreeNode<NodeData> node) async {
    if(node.data?.key==null) throw Exception("Dev error, invalid key");
    /// Shows a dialog for editing the key value.
    final currentKey=node.data!.key;
    final controller = TextEditingController(text:currentKey);

    final isChanged=await showDialog(
      context: context,
      builder: (context) => updateTextDialog(title: "Edit Key", placeholder: "Enter new key", controller: controller, onUpdate: () {
        final newKey = controller.text.trim();
        if (newKey.isEmpty || newKey == currentKey) {
          NotificationService.showSnackbar(text: "Invalid key (key cannot be empty or same)");
        }else{
          node.data!.key=newKey;
          Navigator.pop(context,true); // Close dialog after update
        }
      }, onCancel: () => Navigator.pop(context,false)),
    );
    if(isChanged) setState(() {});
  }

  _onValueChange(TreeNode<NodeData> node) async {
    if(node.data?.value==null) throw Exception("Dev error, invalid value");
    /// Shows a dialog for editing the key value.
    final currentValue=node.data!.value;//primitive
    final controller = TextEditingController(text:currentValue);

    final isChanged=await showDialog(context: context, builder: (context) {
      return updateTextDialog(title: "Edit Value", placeholder: "Enter new value", controller: controller, onUpdate: () {
        final newValue = controller.text.trim();
        if (newValue.isEmpty || newValue == currentValue) {
          NotificationService.showSnackbar(text: "Invalid value (value cannot be empty or same)");
        }else{
          node.data!.value=newValue;
          Navigator.pop(context,true); // Close dialog after update
        }
      }, onCancel: () => Navigator.pop(context,false));
    });

    if(isChanged) setState(() {});
  }

  @override
  void dispose() {
    _killIsolate();
    _contentStream.close();
    super.dispose();
  }

}

InlineSpan buildInteractiveTextSpanWithBorder({
  required String key,
  required dynamic value,
  required void Function()? onKeyTap,
  required void Function()? onValueTap,
}) {
  return TextSpan(
    children: [
      (onKeyTap==null) ? TextSpan(text:  key,style: const TextStyle(color: Colors.black)) : clickableText(
              onTap: onKeyTap,
              text: key,
              backgroundColor: Constants.green600.withOpacity(0.1),
              textColor: Constants.green600,
              borderColor: Constants.green600),
      if (key.isNotEmpty && value != null)
        const TextSpan(text: " : ",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 18)), // Separator text
      if (value != null)
        clickableText(
            onTap: onValueTap,
            text: value.toString(),
            backgroundColor: Colors.red.withOpacity(0.1),
            textColor: Colors.redAccent,
            borderColor: Colors.red)
    ],
  );
}

WidgetSpan clickableText({required String text,VoidCallback? onTap,Color? textColor,Color? borderColor,Color? backgroundColor}){
  return WidgetSpan(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? Constants.green600, width: 1), // Light border
          borderRadius: BorderRadius.circular(4),
          color: backgroundColor ?? Constants.green600.withOpacity(0.1), // Optional light background
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? Constants.green600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}


SimpleDialog updateTextDialog({required String title,required String placeholder,required TextEditingController controller,required VoidCallback onUpdate,required VoidCallback onCancel}){
  return SimpleDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.all(24),
      backgroundColor: Constants.green100,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
              hintText: placeholder,
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Constants.green400)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Constants.green600)),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)))
          ),
        ),
        const SizedBox(height: 10,),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              style:FilledButton.styleFrom(backgroundColor: Colors.red,padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 0)),
              onPressed: onCancel, // Close dialog on cancel
              child: const Text("Cancel"),
            ),
            const SizedBox(width: 10,),
            FilledButton(
              style:FilledButton.styleFrom(backgroundColor: Colors.green,padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 0)),
              onPressed: onUpdate,
              child: const Text("Update"),
            ),
          ],
        )
      ]
  );
}