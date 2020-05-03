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
  List<Node<Directory>> dirNodes;
  TextEditingController searchCtrl = TextEditingController();
  bool hasResults = true;

  @override
  void initState() {
    super.initState();
    selectedDir = widget.dir;
    dirNodes = <Node<Directory>>[createRootNode(widget.dir)];
    treeCtrl = TreeViewController(
      children: dirNodes,
    );
  }

  Node createRootNode(Directory _dir, [String search = '']) {
    final children = _dir.children
        .map<Node>((n) => createRootNode(n, search))
        .where((n) => n != null)
        .toList();
    if ((!search.isEmpty) && children.length == 0 && !_dir.path.contains(search)) return null;
    return Node<Directory>(
        key: _dir.path,
        label: _dir.path.split('\\').last,
        children: children,
        icon: NodeIcon(codePoint: Icons.folder.codePoint),
        data: _dir);
  }

  @override
  Widget build(BuildContext context) {
    final path = selectedDir.path.split('\\').sublist(2);
    final acumPath = List.generate(
        path.length, (i) => '\\\\' + path.sublist(0, i + 1).join('\\'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 20),
          child: BreadCrumb(
            items: acumPath
                .map<BreadCrumbItem>((path) => BreadCrumbItem(
                    content: Text(path.split('\\').last),
                    onTap: () {
                      if (!(treeCtrl.getNode(path) is Node)) {
                        return;
                      }
                      setState(() {
                        treeCtrl = treeCtrl.copyWith(selectedKey: path);
                        selectedDir = treeCtrl.selectedNode.data;
                      });
                    }))
                .toList(),
            divider: Icon(Icons.chevron_right),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Column(
                  children: [
                    buildTextField(),
                    Expanded(
                      child: hasResults ? buildDir() : Center(child: Text("No Results Found"),),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
              ),
              Flexible(
                child: PermissionList(selectedDir.permissions..sort((a, b) => a.displayName.compareTo(b.displayName))),
              ),
//          Expanded(child: Dir(dir: widget.dir)),
//          PermissionList(selectedDir.permissions),
            ],
          ),
        ),
      ],
    );
  }

  TextField buildTextField() {
    return TextField(
      decoration: InputDecoration(
          icon: Icon(Icons.search), hintText: "Search directory"),
      onChanged: (v) {
        if (v.isEmpty) {
          setState(() {
            treeCtrl = treeCtrl.copyWith(
                children: dirNodes, selectedKey: dirNodes[0].key);
          });
          return;
        }
        final newRoot = createRootNode(widget.dir, v);
        if (newRoot == null) {
          hasResults = false;
          return;
        }
        else
          hasResults = true;
        final selectedKey = getFirstLeaf(newRoot, v).key;
        setState(() {
          treeCtrl = treeCtrl
              .copyWith(children: <Node>[newRoot], selectedKey: selectedKey);
        });
      },
    );
  }

  Dir buildDir() {
    return Dir(
      dir: widget.dir,
      onChange: (path) {
        setState(() {
          treeCtrl = treeCtrl.copyWith(selectedKey: path);
          selectedDir = treeCtrl.getNode(path).data;
        });
      },
      treeViewController: treeCtrl,
    );
  }

  Node getFirstLeaf(Node root, String search) {
    if (root.children.length == 0 || root.key.contains(search)) return root;
    return getFirstLeaf(root.children[0], search);
  }
}
