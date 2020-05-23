import 'dart:io';
import 'package:example_flutter/common/permission.dart';
import 'package:example_flutter/common/rights_filter.dart';
import 'file:///D:/dev/permissions/permissions_viewer/src/lib/permissions_list.dart';
import 'package:example_flutter/dir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:flutter_treeview/tree_view.dart';

class PermissionsView extends StatefulWidget {
  final Directory dir;

  const PermissionsView(this.dir);

  @override
  _PermissionsViewState createState() => _PermissionsViewState();
}

class _PermissionsViewState extends State<PermissionsView> {
  Directory selectedDir;
  TreeViewController treeCtrl;
  List<Node<Directory>> dirNodes;
  TextEditingController userSearchCtrl = TextEditingController();
  ScrollController permissionsScrollController = ScrollController();
  ScrollController dirScrollController = ScrollController();
  RightsFilter rightsFilter = RightsFilter();
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
    if ((search.isNotEmpty) && children.isEmpty && !_dir.path.toLowerCase().contains(search.toLowerCase())) return null;
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
        path.length, (i) => '\\\\${path.sublist(0, i + 1).join('\\')}');
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: BreadCrumb(
                  items: acumPath
                      .map<BreadCrumbItem>((path) => BreadCrumbItem(
                      content: Text(path.split('\\').last),
                      onTap: () {
                        if (!(treeCtrl.getNode(path) is Node)) {
                          return;
                        }
                        setState(() {
                          userSearchCtrl.clear();
                          treeCtrl = treeCtrl.copyWith(selectedKey: path);
                          selectedDir = treeCtrl.selectedNode.data;
                        });
                      }))
                      .toList(),
                  divider: Icon(Icons.chevron_right),
                ),
              ),
              buildTextField(),
              Expanded(
                child: hasResults ? buildDir() : Center(child: Text('No Results Found'),),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10)
                ),
                padding: EdgeInsets.only(right: 15),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    buildCheckbox('Read', value: rightsFilter.showRead ,onChanged: (v)=>setState(()=>rightsFilter.showRead=v)),
                    buildCheckbox('List Files', value: rightsFilter.showListFiles ,onChanged: (v)=>setState(()=>rightsFilter.showListFiles=v)),
                    buildCheckbox('Create', value: rightsFilter.showCreate ,onChanged: (v)=>setState(()=>rightsFilter.showCreate=v)),
                    buildCheckbox('Write', value: rightsFilter.showWrite ,onChanged: (v)=>setState(()=>rightsFilter.showWrite=v)),
                    buildCheckbox('Full Control', value: rightsFilter.showFullControl ,onChanged: (v)=>setState(()=>rightsFilter.showFullControl=v)),
                  ],
                ),
              ),
              TextField(
                decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search user'),
                controller: userSearchCtrl,
                onChanged: (v){
                  setState(() {
                    userSearchCtrl = userSearchCtrl;
                  });
                },
          ),
              Expanded(child:
                buildPermissionList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCheckbox(String label, {@required bool value, @required Function(bool) onChanged}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(value: value ,onChanged: onChanged),
      Text(label)
    ],
  );

  Widget buildPermissionList() {
    final permissions = selectedDir.permissions
        .where((perm) => perm.displayName.toLowerCase().contains(userSearchCtrl.text.toLowerCase()) && rightsFilter.shouldShow(perm.rights)).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (permissions.isEmpty)
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: Text('no results found'),
        ),);
    return PermissionList(
                      permissions,
                      permissionsScrollController);
  }

  TextField buildTextField() {
    return TextField(
      decoration: InputDecoration(
          icon: Icon(Icons.search), hintText: 'Search directory'),
      onChanged: (v) {
        userSearchCtrl.clear();
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
          userSearchCtrl.clear();
          treeCtrl = treeCtrl.copyWith(selectedKey: path);
          selectedDir = treeCtrl.getNode(path).data;
        });
      },
      treeViewController: treeCtrl,
      scrollController: dirScrollController,
    );
  }

  Node getFirstLeaf(Node root, String search) {
    if (root.children.isEmpty || root.key.contains(search)) return root;
    return getFirstLeaf(root.children[0], search);
  }
}
