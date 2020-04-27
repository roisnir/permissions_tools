import 'dart:io';
import 'package:example_flutter/common/permission.dart';
import 'package:example_flutter/common/permissions_list.dart';
import 'package:example_flutter/dir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_treeview/tree_view.dart';

class PermissionsView extends StatefulWidget {
  final Directory dir;

  PermissionsView(this.dir);

  @override
  _PermissionsViewState createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  Directory selectedDir;
  TreeViewController treeCtrl;

  @override
  void initState() {
    super.initState();
    selectedDir = widget.dir;
    final nodes = <Node<Directory>>[createRootNode(widget.dir)];
    treeCtrl = TreeViewController(
      children: nodes,
    );
  }

  Node createRootNode(Directory _dir)=> Node<Directory>(
      key: _dir.path,
      label: _dir.path.split('\\').last,
      children: _dir.children.map<Node>(createRootNode).toList(),
      icon: NodeIcon(codePoint: Icons.folder.codePoint),
      data: _dir
  );

  @override
  Widget build(BuildContext context) {
    final path = selectedDir.path.split('\\').sublist(2);
    final acumPath = List.generate(path.length, (i) => '\\\\' + path.sublist(0, i + 1).join('\\'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 20),
          child: BreadCrumb(items: acumPath.map<BreadCrumbItem>(
                  (path) => BreadCrumbItem(
                      content: Text(path.split('\\').last),
                      onTap: (){
                        if (!(treeCtrl.getNode(path) is Node)) {return;}
                        setState(() {
                          treeCtrl = treeCtrl.copyWith(selectedKey: path);
                          selectedDir = treeCtrl.selectedNode.data;
                  });})).toList(),
          divider: Icon(Icons.chevron_right),),
        ),
        Expanded(
          child: Row(
            children: [
            Flexible(child: Dir(
              dir: widget.dir,
              onChange: (path){
              setState(() {
                treeCtrl = treeCtrl.copyWith(selectedKey: path);
                selectedDir = treeCtrl.getNode(path).data;
              });
            },
            treeViewController: treeCtrl,),),
            Padding(padding: EdgeInsets.only(left: 20),),
            Flexible(child: PermissionList(selectedDir.permissions),),
//          Expanded(child: Dir(dir: widget.dir)),
//          PermissionList(selectedDir.permissions),
            ],
          ),
        ),
      ],
    );
  }
}
