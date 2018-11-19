library asset_offers;

import 'dart:async';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:date/src/term_parse.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec_server/src/utils/html_table.dart';
import 'package:elec_server/client/isoexpress/da_energy_offer.dart';
import 'package:energyoffers_viewer/src/lib_data.dart';

class AssetOffersApp {
  Interval term;
  int maskedAssetId;

  Map layout;

  DaEnergyOffers api;
  Location location;

  List<Map> dataTable;

  html.Element wrapper;
  html.InputElement termInput;
  html.InputElement assetIdInput;
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
    html.querySelector('#output').text = 'Clearing the market ...';

    var start = Date.fromTZDateTime(term.start);
    var end = Date.fromTZDateTime(term.end.subtract(Duration(minutes: 1)));
    var eoData = await api.getDaEnergyOffersForAsset(maskedAssetId, start, end);

    var traces = _makeTraces(eoData);
    var prices =
        traces.where((e) => (e['name'] as String).startsWith('price')).toList();

    Plot.id('chart-lmp', prices, layout);
  }

  _addHtmlControls() {
    wrapper.setAttribute('style', 'margin-left: 15px');

    /// the term selector
    term =
        Interval(TZDateTime(location, 2017, 1), TZDateTime(location, 2018, 8));
    wrapper.children.add(html.LabelElement()..text = 'Term');
    termInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px');
    termInput.value = term.toString();
    termInput.onChange.listen(_onTermInputChange);
    wrapper.children.add(termInput);
    wrapper.children.add(html.Element.br());

    /// the asset selector
    maskedAssetId = 54465;
    wrapper.children.add(html.LabelElement()..text = 'Masked Asset ID');
    assetIdInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px');
    assetIdInput.value = maskedAssetId.toString();
    assetIdInput.onChange.listen(_onAssetIdInputChange);
    wrapper.children.add(assetIdInput);
    wrapper.children.add(html.Element.br());
  }

  void _onTermInputChange(e) {
    term = parseTerm(termInput.value);
    show();
  }

  void _onAssetIdInputChange(e) {
    maskedAssetId = int.parse(assetIdInput.value);
    show();
  }
}

/// variable can be 'price' or 'quantity'
List<Map<String, dynamic>> _makeTraces(List<Map<String, dynamic>> hData) {
  var series = priceQuantityOffers(hData);

  var out = [];
  for (var i = 0; i < series.length; i++) {
    List x = [];
    List price = [];
    List qty = [];
    series[i].forEach((e) {
      x.add(e.interval.start);
      price.add(e.value['price']);
      qty.add(e.value['quantity']);
    });
    out.add({
      'x': x,
      'y': price,
      'name': 'price $i',
      'mode': 'lines',
      'line': {
        'width': 2,
      },
    });
    out.add({
      'x': x,
      'y': qty,
      'name': 'quantity $i',
      'mode': 'lines',
      'line': {
        'width': 2,
      },
    });
  }
  return out;
}

Map _getPlotLayout() {
  return {
    'title': 'LMP estimator',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
      'zeroline': false,
      'title': 'Hub LMP, \$/Mwh',
    },
    'hovermode': 'closest',
    'width': 950,
    'height': 600,
  };
}
