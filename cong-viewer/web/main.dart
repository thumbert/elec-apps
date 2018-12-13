

import 'dart:html';
import 'package:http/http.dart';
import 'package:timezone/browser.dart';
import 'package:cong_viewer/all_nodes/all_nodes_app.dart';


void openTab(String tabName) {
  List<DivElement> x = document.getElementsByClassName('tab-content');
  for (int i = 0; i < x.length; i++) {
    x[i].style.display = 'none';
  }
  document.getElementById(tabName).style.display = 'block';
}



void main() async {

  await initializeTimeZone();
  var client = Client();

  var allNodesApp = AllNodesApp(querySelector('#wrapper-all-nodes'));
  _onClickAllNodesViewer(e) {
    openTab('all-nodes');
    allNodesApp.show();
  }
  querySelector('#btn-all-nodes')..onClick.listen(_onClickAllNodesViewer);



}
