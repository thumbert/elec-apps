import 'dart:html';

import 'dart:async';
import 'dart:html';
import 'package:http/browser_client.dart';
import 'package:timezone/browser.dart';
import 'package:energyoffers_viewer/stack_viewer/stack_viewer.dart';
import 'package:energyoffers_viewer/stack_viewer/lmp_viewer.dart';
import 'package:energyoffers_viewer/asset_offers/asset_offers_app.dart';

void openTab(String tabName) {
  print(tabName);
  var x = document.getElementsByClassName('tab-content').cast<DivElement>();
  for (int i = 0; i < x.length; i++) {
    x[i].style.display = 'none';
  }
  document.getElementById(tabName).style.display = 'block';
}


main() async {
  print('Hello');

  await initializeTimeZone();
  var client = BrowserClient();

//  var lmpViewer = new LmpViewerApp(querySelector('#wrapper-lmp-estimate'),
//    client: client);
//  _onClickLmpViewer(e) {
//    openTab('lmp-estimate');
//    lmpViewer.show();
//  }
//  querySelector('#btn-lmp-viewer')..onClick.listen(_onClickLmpViewer);


//  var stackViewer = new StackViewer(querySelector('#wrapper-stack-viewer'));
//  _onClickStackViewer(e) {
//    openTab('stack-viewer');
//    stackViewer.show();
//  }
//  querySelector('#btn-stack-viewer')..onClick.listen(_onClickStackViewer);


  var assetOffers = new AssetOffersApp(querySelector('#wrapper-one-asset'),
      client: client);
  _onClickAssetOffers(e) {
    openTab('one-asset');
    assetOffers.show();
  }
  var btnOneAsset = querySelector('#btn-one-asset');
  btnOneAsset.onClick.listen(_onClickAssetOffers);



}
