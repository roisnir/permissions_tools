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

  const Dir({
    @required this.dir,
    @required this.onChange,
    @required this.treeViewController,
    @required this.scrollController,
    this.onExpansionChange,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      controller: scrollController,
      isAlwaysShown: true,
      child: TreeView(
        theme: TreeViewTheme(colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary)),
        scrollController: scrollController,
        onNodeTap: onChange,
        onExpansionChanged: onExpansionChange,
        allowParentSelect: true,
        supportParentDoubleTap: true,
        controller: treeViewController,),
    );
  }
}
