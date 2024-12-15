import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/extensions/map-entensions.dart';
import 'package:jedi/singletons/AdsSingleton.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/utility.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

/*
* Coming in future
  In list items can be primitive,object,list
  for object,list a dummy node is created , know why ?
  *
  * eg : {'x':[5,{'name':'vishnu','age':'25'},[5]]}
  * in above object for node with key x we have value type list
  * iterating list
  *   for item 1 we have node with value type primitive and key null -> return 5
  *   for item 2 we have value type object and key null -> obviously value=null but have childs that makes up {'name':'vishnu','age':'25'}
  *   item 2 makes a node called dummy node with key,value null (same for item 3)
  *
  *   dummy node can never be primitive** why ?
* Reverse to serialize
* */


final uuid=Uuid();

enum ValueType{
  primitive,
  list,
  object
}

class Result {
  final List<TreeNode<NodeData>>? data;
  final String? error;

  Result({this.data, this.error});
}

class NodeData{
  String? key;
  dynamic value;//primitive
  ValueType valueType;
  ValueType? rootType;//assigned to top level nodes to know while serializing are they really in list or object
  Map<String,dynamic>? extras;
  
  NodeData({this.rootType,required this.valueType,this.value,this.key,this.extras});
  
  bool isKeyUpdated(String nodeKey){
    if(extras?['updated']?[nodeKey]==null) return false;
    
    return (extras?['updated']?[nodeKey] as Map).containsKey('key');
  }

  bool isValueUpdated(String nodeKey){
    if(extras?['updated']?[nodeKey]==null) return false;

    return (extras?['updated']?[nodeKey] as Map).containsKey('value');
  }
}

class ActionStatus{
  bool? loading;
  String? error;

  ActionStatus({this.loading,this.error});

  isLoading(){
    return loading==true;
  }

  isError(){
    return error!=null;
  }
}

TreeNode<NodeData> _createNode(String? dataKey,dynamic value){
  final node = TreeNode<NodeData>(key: uuid.v4(),data: NodeData(key: dataKey,valueType: (value is List) ? ValueType.list : (value is Map ? ValueType.object : ValueType.primitive)));
  if(value is! List && value is! Map){
    node.data!.value=value;
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
    final rootNodeType=jsonData is Map ? ValueType.object : (jsonData is List ? ValueType.list : ValueType.primitive);
    final List<TreeNode<NodeData>> nodes=_getNodes(jsonData);

    //assign root type to top level roots
    nodes.forEach((node)=>node.data!.rootType=rootNodeType);

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


/*
* node ::
* [key?] : [
*   primitive,
*   object
* ]
*
* in this case node->key may or may not be null (doesn't matter)
* node -> value type -> list
* for each node child
*   first is -> primitive
*   second is node{key->null,value->null,valutype->object|list,children:{{key:'id',value:1},{key:'name',value:'vishnu'}}}
* */

dynamic serializeNode(TreeNode<NodeData> node) {
  final data = node.data!;
  if(node.data?.key==null && node.data?.value==null){
    return serializeDummyNode(node);
  }

  if(data.valueType==ValueType.primitive) {
    return data.key!=null ? {data.key:data.value} : data.value;
  } else if(data.valueType==ValueType.list){
    final List<dynamic> jsonData = [];

    for (var child in node.children.values.toList()){
      child=child as TreeNode<NodeData>;
      final serializedChild=serializeNode(child);
      jsonData.add(serializedChild);
    }
    return data.key!=null ? {data.key:jsonData} : jsonData;
  }else{ // {key:null,value:null,children:obj}
    final Map<String,dynamic> jsonData = {};

    for (var child in node.children.values.toList()){
      child=child as TreeNode<NodeData>;
      final serializedData=serializeNode(child) as Map;
      if(serializedData.length>1) throw Exception("Something went wrong");
      jsonData.put(serializedData.keys.first,serializedData.values.first);
    }
    return data.key!=null ? {data.key:jsonData} : jsonData;
  }
}

dynamic serializeDummyNode(TreeNode<NodeData> dummyNode){
  if(dummyNode.data?.key!=null || dummyNode.data?.value!=null) throw Exception("Node is not dummy");

  if(dummyNode.data?.valueType==ValueType.list){
    final serializedJson=[];
    for(final child in dummyNode.children.values){
      serializedJson.add(serializeNode(child as TreeNode<NodeData>));
    }
    return serializedJson;
  }else{//object
    final Map<String,dynamic> jsonData = {};
    for (var child in dummyNode.children.values){
      child=child as TreeNode<NodeData>;
      final serializedData=serializeNode(child) as Map;
      if(serializedData.length>1) throw Exception("Something went wrong");
      jsonData.put(serializedData.keys.first,serializedData.values.first);
    }
    return jsonData;
  }
}

Future<String> serializeTree(List<TreeNode<NodeData>> tree) async {

  // Serialize the root list of nodes
  if(tree.isEmpty) return "";
  final serialized = tree.map(serializeNode).toList();

  if(tree.first.data!.rootType==ValueType.object){
    final jsonData=Map.fromEntries(serialized.map((item)=>MapEntry((item as Map).keys.first, item.values.first)));
    return jsonEncode(jsonData);
  }else if(tree.first.data!.rootType==ValueType.list){
    return jsonEncode(serialized);
  }
  return jsonEncode(serialized.first);
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
  ActionStatus _saveStatus=ActionStatus();

  @override
  void initState() {
    AdsSingleton().dispatch(LoadInterstitialAd());
    if(!Utility.isJsonFile(widget.jsonFile) || !widget.jsonFile.existsSync()) throw Exception("Dev error");
    _startPrettifying();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  ValueListenableBuilder(valueListenable: isStreamClosed,builder: (context, isStreamClosed, child)=>isStreamClosed ? Text("Json Editor",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 24),) : SpinKitPouringHourGlass(color: Colors.white,size: 24,)),
        actions: [
          ValueListenableBuilder(valueListenable: isStreamClosed,builder: (context, isStreamClosed, child) {
            return PopupMenuButton<String>(
              onSelected:  (value) async {
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
                PopupMenuItem(
                  enabled: isStreamClosed,
                  value: 'save',
                  child: Text('Save File'),
                ),
                PopupMenuItem(
                  enabled: isStreamClosed,
                  value: 'copy_to_clipboard',
                  child: Text('Copy to Clipboard'),
                ),
              ],
            );
          },)
        ],
      ),
      body: SafeArea(child: Stack(
        children: [
          Padding(
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
                            final nodeVal=node.data as NodeData;
                            final indexKey=(nodeVal.extras?['index'] is int && node.level==1 ? ('Index ${nodeVal.extras?['index']}').toString() : null);
                            final key=nodeVal.key ?? indexKey  ?? '';
                            return   Padding(
                              key: ValueKey(node.key),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 4.0),
                              child: RichText(text: buildInteractiveTextSpanWithBorder(
                                  node:node as TreeNode<NodeData>,
                                  onKeyTap: nodeVal.key == null ? null : () => _onKeyChange(node),
                                  onValueTap: nodeVal.value == null ? null : () => _onValueChange(node))),
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
            ),
          ),
          if(_saveStatus.isLoading()) Container(decoration: const BoxDecoration(color: Colors.black54),child: Center(child: SpinKitThreeBounce(color: Colors.green,size: 45,),),)
        ],
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
    try{
      setState(() =>_saveStatus=ActionStatus(loading: true));
      final data= await serializeTree(_contentStream.value);
      await widget.jsonFile.writeAsString(data,mode: FileMode.write,flush: true);
      setState(() =>_saveStatus=ActionStatus());
      NotificationService.showSnackbar(text: "Json saved successfully",color: Colors.green);
    }catch(e){
      setState(() =>_saveStatus=ActionStatus(error: "Failed to save json"));
      NotificationService.showSnackbar(text: "Failed to save json",color: Colors.red);
    }
  }

  // Copy to Clipboard Logic
  Future<void> _copyToClipboard(List<TreeNode<NodeData>> tree) async {
    try {
      await Clipboard.setData(ClipboardData(text: await serializeTree(_contentStream.value)));
      NotificationService.showSnackbar(text: 'JSON copied to clipboard',color: Colors.green);
    } catch (e) {
      NotificationService.showSnackbar(text: 'Failed to copy to clipboard',color: Colors.red);
    }
  }

  _killIsolate(){
    _isolate?.kill(priority: Isolate.immediate);
  }

  _onKeyChange(TreeNode<NodeData> node) async {
    if(node.data?.key==null) throw Exception("Dev error, invalid key");
    /// Shows a dialog for editing the key value.
    final currentKey=node.data!.key.toString();
    final controller = TextEditingController(text:currentKey);

    final isChanged=await showDialog(
      context: context,
      builder: (context) => updateTextDialog(title: "Edit Key", placeholder: "Enter new key", controller: controller, onUpdate: () {
        final newKey = controller.text.trim();
        if (newKey.isEmpty || newKey == currentKey) {
          NotificationService.showSnackbar(text: "Invalid key (key cannot be empty or same)");
        }else{
          node.data!.key=newKey;
          
          //marked this updated
          _markUpdated(node,true,currentKey);
          Navigator.pop(context,true); // Close dialog after update
        }
      }, onCancel: () => Navigator.pop(context,false)),
    );
    if(isChanged) setState(() {});
  }
  
  _markUpdated(TreeNode<NodeData> node,bool isKeyUpdated,dynamic oldValue){
    if(node.data!.extras==null) node.data!.extras=Map();
    if(node.data!.extras!['updated']==null) node.data!.extras!['updated']=Map();
    if(node.data!.extras!['updated'][node.key]==null)node.data!.extras!['updated'][node.key]=Map();
    if(node.data!.extras!['updated'][node.key][isKeyUpdated ? 'key':'value']==(isKeyUpdated ? node.data!.key : node.data!.value)){
      (node.data!.extras!['updated'][node.key] as Map).remove(isKeyUpdated ? 'key':'value');
    }else{
      node.data!.extras!['updated'][node.key][isKeyUpdated ? 'key':'value']=oldValue;
    }
  }

  _onValueChange(TreeNode<NodeData> node) async {
    if(node.data?.value==null) throw Exception("Dev error, invalid value");
    /// Shows a dialog for editing the key value.
    final currentValue=node.data!.value.toString();//primitive
    final controller = TextEditingController(text:currentValue);

    final isChanged=await showDialog(context: context, builder: (context) {
      return updateTextDialog(title: "Edit Value", placeholder: "Enter new value", controller: controller, onUpdate: () {
        final newValue = controller.text.trim();
        if (newValue.isEmpty || newValue == currentValue) {
          NotificationService.showSnackbar(text: "Invalid value (value cannot be empty or same)");
        }else{
          node.data!.value=newValue;
          //marked this updated
          _markUpdated(node,false,currentValue);
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
  required TreeNode<NodeData> node,
  required void Function()? onKeyTap,
  required void Function()? onValueTap,
}) {
  final nodeVal=node.data as NodeData;
  final isDummyNode=nodeVal.key==null && nodeVal.value==null;
  final indexKey=(nodeVal.extras?['index'] is int && node.level==1 ? ('Index ${nodeVal.extras?['index']}').toString() : null);
  final key=nodeVal.key ?? indexKey  ?? '';
  return TextSpan(
    children: [
      (onKeyTap==null) ? TextSpan(text:  isDummyNode ? (nodeVal.valueType==ValueType.object ? "{...}" : "[...]") : key,style: const TextStyle(color: Colors.black)) : clickableText(
              onTap: onKeyTap,
              text: isDummyNode ? (nodeVal.valueType==ValueType.object ? "{...}" : "[...]") : key,
              backgroundColor: (node.data!.isKeyUpdated(node.key) ? Colors.orangeAccent : Constants.green600).withOpacity(0.1),
              textColor: node.data!.isKeyUpdated(node.key) ? Colors.orangeAccent : Constants.green600,
              borderColor: node.data!.isKeyUpdated(node.key) ? Colors.orangeAccent : Constants.green600),
      if (key.isNotEmpty && nodeVal.value != null)
        const TextSpan(text: " : ",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 18)), // Separator text
      if (nodeVal.value != null)
        clickableText(
            onTap: onValueTap,
            text: nodeVal.value.toString(),
            backgroundColor: (node.data!.isValueUpdated(node.key) ? Colors.orangeAccent : Colors.red).withOpacity(0.1),
            textColor: node.data!.isValueUpdated(node.key) ? Colors.orangeAccent : Colors.redAccent,
            borderColor: node.data!.isValueUpdated(node.key) ? Colors.orangeAccent : Colors.red)
    ],
  );
}

WidgetSpan clickableText({required String text,
  VoidCallback? onTap,
  Color? textColor,
  Color? borderColor,
  Color? backgroundColor}){
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