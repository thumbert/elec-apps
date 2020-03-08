import 'dart:html';

import 'package:daily_draws_viewer/src/draws_viewer_app.dart';
import 'package:daily_draws_viewer/src/lib_contracts.dart';




void main() async {
  var app = DrawsViewerApp(querySelector('#wrapper'));
  await app.show();

}
