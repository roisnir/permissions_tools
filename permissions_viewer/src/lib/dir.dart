import 'package:flutter/material.dart';
import 'package:example_flutter/common/permission.dart';
import 'package:flutter_treeview/tree_view.dart';

class Dir extends StatefulWidget {
  final Directory dir;
  final Function(String) onChange;
  final TreeViewController treeViewController;

  Dir({@required this.dir, this.onChange, this.treeViewController});

  @override
  _DirState createState() => _DirState();
}

class _DirState extends State<Dir> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return TreeView(
      onNodeTap: widget.onChange,
      allowParentSelect: true,
      supportParentDoubleTap: true,
      controller: widget.treeViewController,);
  }

}
