import 'package:example_flutter/common/permission.dart';
import 'package:example_flutter/common/rights.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PermissionList extends StatelessWidget {
  final List<Permission> permissions;
  final ScrollController controller;

  PermissionList(this.permissions, this.controller);

  @override
  Widget build(BuildContext context) {
    return CupertinoScrollbar(
      controller: controller,
      isAlwaysShown: true,
      child: ListView.separated(
        controller: controller,
          itemBuilder: (c, i) => ListTile(
            contentPadding: EdgeInsets.all(0),
            leading: Icon(Icons.person),
            title: Text(permissions[i].displayName),
            subtitle: Text(permissions[i].rights.simpleName),
          ),
          separatorBuilder: (c, i) => Divider(height: 0.1,),
          itemCount: permissions.length),
    );
  }
}
