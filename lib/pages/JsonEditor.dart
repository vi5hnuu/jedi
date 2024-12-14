import 'dart:convert';
import 'dart:io';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/utility.dart';
import 'package:rxdart/rxdart.dart';

class JsonEditor extends StatefulWidget {
  final File jsonFile;

  const JsonEditor({super.key,required this.jsonFile});

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  var contentLoading=false;
  String? contentError;
  String? content;

  @override
  void initState() {
    if(!Utility.isJsonFile(widget.jsonFile) || !widget.jsonFile.existsSync()) throw Exception("Dev error");
    _loadFileContent();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Flex(
          direction: Axis.vertical,
          children: [
            if(content!=null) Container(
              height: 500,
              child: TreeView.simple(
                      tree: TreeNode.root()..addAll(_getNodes(jsonDecode(content!))),
                      builder: (context, node) {
                      // build your node item here
                      // return any widget that you need
                      return Container(
                          height: 100,
                          child: ListTile(
              title: Text("Item ${node.level}-${node.key}"),
              subtitle: Text('Level ${node.level}'),
                          ),
                      );
                    }),
            )
            else if(contentError!=null) Center(child: Text(contentError!,style: TextStyle(color: Colors.red,fontSize: 24),))
            else SpinKitThreeBounce(color: Constants.green600,)
          ],
        ),
      )),
    );
  }

  void _loadFileContent()async {
    try{
      setState(()=>contentLoading=true);
      const JsonEncoder encoder = JsonEncoder.withIndent('     ');
      final content = encoder.convert(jsonDecode(await widget.jsonFile.readAsString()));

      setState((){
        contentLoading=false;
        this.content=content;
      });
    }catch(e){
      setState(()=>contentError="failed to load file");
    }
  }
  List<TreeNode> _getNodes(dynamic jsonDecode, {TreeNode? parent}) {
    final nodes = <TreeNode>[];

    if (jsonDecode is Map) {
      // If the JSON is a map, iterate over the entries and create nodes for each key-value pair.
      jsonDecode.forEach((key, value) {
        // Sanitize the key by replacing period (.) with an underscore (_)
        final sanitizedKey = key.replaceAll('.', '_');

        // Create a node with the sanitized key and pass the parent to child nodes.
        final node = TreeNode(
          data: (value is Map || value is List)
              ? _getNodes(value, parent: parent) // If it's a Map/List, recursively call _getNodes
              : value, // Otherwise, set the data as is.
          parent: parent, // Link to the parent node.
        );
        nodes.add(node);

        // If the value is a Map or List, recursively process it.
        if (value is Map || value is List) {
          nodes.addAll(_getNodes(value, parent: node)); // Pass the current node as parent for deeper recursion.
        }
      });
    } else if (jsonDecode is List) {
      // If the JSON is a list, iterate over the items and create nodes for each item.
      for (var item in jsonDecode) {
        if (item is List || item is Map) {
          // Recursively process nested lists/maps and pass the parent node.
          nodes.addAll(_getNodes(item, parent: parent));
        } else {
          // For primitive types, just create a node with sanitized key.
          final sanitizedKey = item.toString().replaceAll('.', '_');
          final node = TreeNode<dynamic>(
            data: item, // The item itself as the data.
            parent: parent, // Link to the parent node.
          );
          nodes.add(node);
        }
      }
    } else {
      // For leaf nodes (basic data types), just create a node without children.
      final sanitizedKey = jsonDecode.toString().replaceAll('.', '_');
      final node = TreeNode<dynamic>(
        data: jsonDecode, // Leaf node data
        parent: parent, // Link to the parent node.
      );
      nodes.add(node);
    }

    return nodes;
  }

}