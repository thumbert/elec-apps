library shape_viewer.shape_viewer;

import 'dart:async';
import 'dart:html' as html;
import 'package:elec_server/src/utils/custom_client.dart';
import 'package:timezone/browser.dart';
import 'package:plotly/plotly.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/ui/controller.dart';
import 'package:elec_server/src/ui/categorical_dropdown_filter.dart';
import 'package:elec/src/time/calendar/calendars/nerc_calendar.dart';
import 'package:elec_server/client/isoexpress/system_demand.dart';
import 'package:elec/src/time/bucket/hourly_shape.dart';
import 'package:elec/src/time/bucket/hourly_bucket_weights.dart';
import 'package:elec_server/client/utilities/eversource/eversource_load.dart';

class ShapeViewer {
  html.Element wrapper;
  CustomClient client;
  var _location;
  //var api;

  Plot _plot;

  CategoricalDropdownFilter _monthFilter;

  // a cache of the rt load history
  TimeSeries<num> _ts;
  NercCalendar _calendar;

  ShapeViewer(this.wrapper, this.client,
      {String rootUrl: "http://localhost:8080/"}) {
    _location = getLocation('US/Eastern');
    _calendar = NercCalendar();
    //api = SystemDemand(client, rootUrl: rootUrl);
    _makeHtml();
  }

  show() async {
    print('hi');
    var data = await _getData();

    var layout = <String, dynamic>{
      'title': 'Historical hourly shape',
      'xaxis': {
        'showgrid': true,
      },
      'yaxis': {
        'showgrid': true,
        'zeroline': true,
        'title': 'Weight',
      },
      'hovermode': 'closest',
      'width': 950,
      'height': 600,
    };

    var traces = _makeTraces(data);
    _plot = Plot.id('chart-hourly-shape', traces, layout);
  }

  Controller makeController() {
    var filters = <String, dynamic>{'month': _monthFilter.value};
    return Controller(filters: filters);
  }

  _makeHtml() {
    wrapper.children.add(html.HeadElement()
      ..text = 'Historical hourly shape'
      ..setAttribute('style',
          'font-size: 1.5em; font-weight: bold;margin-top: 0.83em; margin-botom: 0.83em;'));

    _monthFilter =
        CategoricalDropdownFilter(wrapper, _mthIndex.keys.toList(), 'Month')
          ..onChange((e) => show());

    wrapper.children.add(html.DivElement()..id = 'chart-hourly-shape');
  }

  List<Map> _makeTraces(Map<int, Iterable<num>> data) {
    var traces = <Map>[];
    data.keys.forEach((int year) {
      var trace = {
        'x': List.generate(24, (i) => i),
        'y': data[year],
        'text': year,
        'name': year,
        'mode': 'lines',
      };
      traces.add(trace);
    });
    return traces;
  }

  /// Get the weekday hourly weights by year.
  Future<Map<int, Iterable<num>>> _getData() async {
    var start = Date(2014, 1, 1, location: _location);
    var end = Date(2018, 12, 31, location: _location);

    var api = EversourceLoad(client);
    var aux = await api.getCtLoad(start, end);
    var x = TimeSeries.fromIterable(aux.map((e) => IntervalTuple(e.interval,
        e.value['SS Total'] + e.value['Competitive Supply'] + e.value['LRS'])));

    var hs = hourlyShapeByYearMonthDayType(x);
    print(hs);

    var controller = makeController();
    print(controller);

    var out = Map.fromEntries(hs
        .where((e) => e.interval.start.month == _mthIndex[controller.filters['month']])
        .map((e) => MapEntry(e.interval.start.year, e.value['Weekday'].weights)));
    print(out);

    return out;
  }

  /// Return an hourly time series corresponding to this month for each
  /// historical year.
//  Future<Map<int,HourlyShape>> _getData() async {
//    var start = Date(2014, 1, 1);
//    var end = Date.today();
//    _ts ??= await api.getSystemDemand(Market.rt, start, end);
//
//    var hs = HourlyShape.fromTimeSeries(_ts);
//
//    var controller = makeController();
//    int month = _mthIndex[controller.filters['month']];
//
//    // filter for the month of interest only
//    var ts = TimeSeries.fromIterable(
//        _ts.where((obs) => obs.interval.start.month == month));
//
//    // calculate the hourly shape by day
//    var shapeByDay = hourlyShapeByDay(ts);
//
//    // keep only the non-holiday weekdays
//    List daysOut = [];
//    shapeByDay.keys.forEach((Date day) {
//      if (day.isWeekend() || _calendar.isHoliday(day))
//        daysOut.add(day);
//    });
//    daysOut.forEach((day) => shapeByDay.remove(day));
//
//
//    // find the average shape of this year/month combination
//    var byYear = groupBy(shapeByDay.keys, (Date day) => day.year);
//    var avgShape = <int,HourlyShape>{};
//    byYear.forEach((year,days) {
//      avgShape[year] = averageShape(days.map((day) => shapeByDay[day]).toList());
//    });
//
//
//    return avgShape;
//  }

}

Map<String, num> _mthIndex = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12
};
