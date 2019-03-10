

import 'dart:html';
import 'package:http/http.dart' as http;
import 'package:timezone/browser.dart';
import 'package:grpc/grpc.dart';
import 'package:cong_viewer/all_nodes_app/all_nodes_app.dart';


void openTab(String tabName) {
  var x = document.getElementsByClassName('tab-content').cast<HtmlElement>();
  for (int i = 0; i < x.length; i++) {
    x[i].style.display = 'none';
  }
  document.getElementById(tabName).style.display = 'block';
}



void main() async {

  await initializeTimeZone();
  var client = http.Client();

  final channel = ClientChannel('localhost',
      port: 50051,
      options: const ChannelOptions(
          credentials: const ChannelCredentials.insecure()));


  var allNodesApp = AllNodesApp(querySelector('#wrapper-all-nodes'));
  _onClickAllNodesViewer(e) {
    openTab('all-nodes');
    allNodesApp.show();
  }
  querySelector('#btn-all-nodes')..onClick.listen(_onClickAllNodesViewer);



}
