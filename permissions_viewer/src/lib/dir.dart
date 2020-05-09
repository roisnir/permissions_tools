import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:example_flutter/common/permission.dart';
import 'package:flutter_treeview/tree_view.dart';

class Dir extends StatelessWidget {
  final Directory dir;
  final Function(String) onChange;
  final Function(String, bool) onExpansionChange;
  final TreeViewController treeViewController;
  final ScrollController scrollController;

  Dir({
    @required this.dir,
    @required this.onChange,
    this.onExpansionChange,
    @required this.treeViewController,
    @required this.scrollController
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      controller: scrollController,
      isAlwaysShown: true,
      child: TreeView(
        scrollController: scrollController,
        onNodeTap: onChange,
        onExpansionChanged: onExpansionChange,
        allowParentSelect: true,
        supportParentDoubleTap: true,
        controller: treeViewController,),
    );
  }
}
