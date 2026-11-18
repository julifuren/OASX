import 'package:flutter/material.dart';
import 'package:oasx/views/layout/appbar.dart';

import 'package:oasx/views/nav/view_nav.dart';
import 'package:oasx/views/layout/content.dart';
import 'package:oasx/views/layout/page_header.dart';

class DesktopLayoutView extends StatelessWidget {
  const DesktopLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context),
      body: body(),
    );
  }

  Widget body() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Nav(),
        const TreeMenuView(),
        Expanded(
          child: Column(
            children: [
              const PageHeader(),
              Expanded(child: Center(child: content())),
            ],
          ),
        )
      ],
    );
  }
}
