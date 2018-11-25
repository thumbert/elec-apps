library asset_offers;

import 'dart:async';
import 'dart:html' as html;
import 'package:date/date.dart';
import 'package:date/src/term_parse.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
//import 'package:elec_server/src/utils/html_table.dart';
import 'package:elec_server/src/ui/controller.dart';
import 'package:elec_server/src/ui/categorical_dropdown_checkbox_filter.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';

class AssetOffersApp {

  Map<String,dynamic> layout;

  DaEnergyOffers api;
  Location location;

  var cache = <int,List<Map<String,dynamic>>>{};

  html.Element wrapper;
  html.InputElement termInput;
  CategoricalDropdownCheckboxFilter assetFilter;
  //html.InputElement assetIdInput;
  html.Element tableWrapper;
  Map<String, dynamic> _tableOptions;

  AssetOffersApp(this.wrapper,
      {String rootUrl = 'http://localhost:8080/', BrowserClient client}) {
    location = getLocation('US/Eastern');

    _addHtmlControls();

    api = DaEnergyOffers(client, rootUrl: rootUrl);

    layout = _getPlotLayout();
  }

  show() async {
    var controller = _makeController();

    var interval = parseTerm( controller.filters['term'] );
    var start = Date.fromTZDateTime(interval.start);
    var end = Date.fromTZDateTime(interval.end.subtract(Duration(minutes: 1)));

    for (var maskedAssetId in maskedAssetIds.values) {
      if (!cache.containsKey(maskedAssetId)) {
        print('getting $maskedAssetId');
        var eoData = await api.getDaEnergyOffersForAsset(
            maskedAssetId, start, end);
        cache[maskedAssetId] = eoData;
      }
    }

    var traces;
    if (controller.filters['maskedAssetId'] == 'All') {
      var eoData;
      traces = _makeTracesAllUnits();
    } else {
      var id = maskedAssetIds[controller.filters['maskedAssetId']];
      traces = _makeTracesOneUnit(cache[id]);
    }

    Plot.id('chart-prices', traces, layout);
  }

  Controller _makeController() {
    var filters = <String,dynamic>{
      'term': termInput.value,       // 'Jul18'
      'maskedAssetId': assetFilter.value,   // 'All' or 'Salem 5'
    };
    return Controller(filters: filters);
  }

  _addHtmlControls() {
    wrapper.setAttribute('style', 'margin-left: 15px');

    /// the term selector
    wrapper.children.add(html.LabelElement()..text = 'Term');
    termInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px');
    termInput.value = 'Jul18';
    termInput.onChange.listen(_onTermInputChange);
    wrapper.children.add(termInput);
    wrapper.children.add(html.Element.br());

    /// a bit of vertical space
    wrapper.children.add(html.DivElement()..setAttribute('style', 'margin-top: 8px'));

    /// the asset selector
    assetFilter = CategoricalDropdownCheckboxFilter(wrapper,
        ['All']..addAll(maskedAssetIds.keys), 'Masked Asset ID');
    assetFilter.setOnChange((e) => show());

    wrapper.children.add(html.Element.br());

    /// the price offer chart
    wrapper.children.add(html.DivElement()..setAttribute('id', 'chart-prices'));

  }

  void _onTermInputChange(e) {
    // clear the cache on a term change
    cache.clear();
    show();
  }
  void _onAssetIdInputChange(e) => show();


  List<Map<String, dynamic>> _makeTracesAllUnits() {

    var series = [];
    for (int id in cache.keys) {
      var aux = priceQuantityOffers(cache[id]);
      series.add(averageOfferPrice(aux));
    }
    var names = cache.keys.toList();
    // TODO: FIX ME

    var out = <Map<String,dynamic>>[];
    for (var i = 0; i < series.length; i++) {
      var x = [];
      var price = [];
      var text = [];
      series[i].forEach((e) {
        x.add(e.interval.start);
        price.add(e.value['price']);
        text.add('MW: ${e.value['quantity']}');
      });
      out.add({
        'x': x,
        'y': price,
        'text': text,
        'name': '',
        'mode': 'lines',
        'line': {
          'width': 2,
        },
      });
    }
    return out;
  }


}

var maskedAssetIds = <String,int> {
  'Granite Ridge': 13547,
  'Kleen': 77459,
  'Salem 5': 54465,
  'Salem 6': 83798,
  'Towantic 1A': 86083,
  'Towantic 1B': 25645,
};




List<Map<String, dynamic>> _makeTracesOneUnit(List<Map<String, dynamic>> hData) {
  var series = priceQuantityOffers(hData);

  var out = <Map<String,dynamic>>[];
  for (var i = 0; i < series.length; i++) {
    var x = [];
    var price = [];
    var text = [];
    series[i].forEach((e) {
      x.add(e.interval.start);
      price.add(e.value['price']);
      text.add('MW: ${e.value['quantity']}');
    });
    out.add({
      'x': x,
      'y': price,
      'text': text,
      'name': 'price $i',
      'mode': 'lines',
      'line': {
        'width': 2,
      },
    });
  }
  return out;
}




Map<String,dynamic> _getPlotLayout() {
  return <String,dynamic>{
    'title': 'Energy offer prices',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
      'zeroline': false,
      'title': '\$/Mwh',
    },
    'hovermode': 'closest',
    'width': 950,
    'height': 600,
  };
}

//int findKey(String value) {
//  int res;
//  for (var key in maskedAssetIds.keys) {
//    if (maskedAssetIds[key] != value) continue;
//    else return ke;
//  }
//}