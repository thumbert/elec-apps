library draws_viewer_app;

import 'dart:html' as html;

import 'package:daily_draws_viewer/src/lib_contracts.dart';
import 'package:date/date.dart';
import 'package:plotly/plotly.dart';
import 'package:elec_server/ui.dart';

class DrawsViewerApp {
  html.Element wrapper;
  List<Contract> contracts;
  List<Map<String, dynamic>> data;

  CategoricalDropdownCheckboxFilter _pipelineFilter;
  CategoricalDropdownCheckboxFilter _utilityFilter;
  CheckboxLabel _cumulative;

  DrawsViewerApp(this.wrapper) {
    var asOfDate = Date(2020,2, 5);
    contracts = getContracts();
    for (var contract in contracts) {
      contract.calls = simulateCalls(contract, asOfDate);
    }
    data = expandContracts(contracts);
    _addHtml();
  }

  void show() async {
    var controller = _makeController();
    var aggData = aggregateData(data, controller);

    var traces = <Map<String, dynamic>>[];
    for (var key in aggData.keys) {
      var x = <String>[];
      var y = <num>[];
      for (var date in aggData[key].keys) {
        x.add(date);
        y.add(aggData[key][date]);
      }
      traces.add({
        'x': x,
        'y': y,
        'mode': 'line',
        'name': key,
      });
    }


    Plot.id('chart', traces, _getPlotLayout());
  }

  /// Make the controller
  Controller _makeController() {
    return Controller()
      ..checkboxes = <String>[
        if (_cumulative.checked) 'cumulative',
        if (_pipelineFilter.checked) 'pipeline',
        if (_utilityFilter.checked) 'utility',
      ]
      ..filters = {
        'pipeline': _pipelineFilter.value,
        'utility': _utilityFilter.value,
      };
  }

  void _addHtml() {
    var _uPipelines = contracts.map((e) => e.pipeline).toSet();
    _pipelineFilter = CategoricalDropdownCheckboxFilter(
        wrapper, ['All', ..._uPipelines], 'Pipeline')
      ..onChange((e) => show());

    var _uUtility = contracts.map((e) => e.utility).toSet();
    _utilityFilter = CategoricalDropdownCheckboxFilter(
        wrapper, ['All', ..._uUtility], 'Utility')
      ..onChange((e) => show());

    _cumulative = CheckboxLabel(wrapper, 'Show cummulative')
      ..checked = true
      ..onChange((e) => show());

    wrapper.children.add(html.DivElement()..setAttribute('id', 'chart'));
  }

  Map<String, dynamic> _getPlotLayout() {
    return <String, dynamic>{
      'title': 'Pipeline Daily Draws',
      'xaxis': {
        'showgrid': true,
        'gridcolor': '#bdbdbd',
      },
      'yaxis': {
        'showgrid': true,
        'gridcolor': '#bdbdbd',
        'zeroline': false,
        'title': 'Volume, MMBTU',
      },
      'hovermode': 'closest',
      'width': 950,
      'height': 600,
    };
  }
}
