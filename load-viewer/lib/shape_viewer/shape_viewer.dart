library shape_viewer.shape_viewer;

import 'dart:async';
import 'dart:html' as html;
import 'package:http/browser_client.dart';
import 'package:timezone/browser.dart';
import 'package:plotly/plotly.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:load_viewer/src/lib_data.dart';
import 'package:load_viewer/lib_shape_analysis.dart';
import 'package:load_viewer/shape.dart';

class ShapeViewer {
  BrowserClient client;
  Location location;
  Plot plot;

  int month;
  html.InputElement monthInput;

  // a cache of the rt load history
  TimeSeries _ts;
  NercCalendar _calendar;

  ShapeViewer() {
    location = getLocation('US/Eastern');
    client = new BrowserClient();

//    monthInput = html.querySelector('#month-input');
//    monthInput.onChange.listen(_onMonthInputChange);
//    monthInput.value = 'Jul';

    month = 6;

    _calendar = new NercCalendar();
  }

  show() async {
    var data = await _getHistoricalData();

    Map layout = {
      'title': 'Historical Load Shape',
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

    List traces = _makeTraces(data);
    plot = new Plot.id('chart-hourly-shape', traces, layout);
  }

  List<Map> _makeTraces(Map<int,HourlyShape> data) {
    List<Map> traces = [];
    data.keys.forEach((int year) {
      var trace = {
        'x': new List.generate(24, (i) => i),
        'y': data[year].weights,
        'text': year,
        'name': year,
        'mode': 'lines',
      };
      traces.add(trace);
    });
    return traces;
  }

  _onMonthInputChange(e) {
    var month = _mthIndex[monthInput.value.toLowerCase()];
    print(month);
    show();
  }

  /// Return an hourly time series corresponding to this month for each
  /// historical year.
  Future<Map<int,HourlyShape>> _getHistoricalData() async {
    var interval = new Interval(new TZDateTime(location, 2014),
        new TZDateTime(location, new DateTime.now().year + 1));
    // this is cached after the first call
    _ts ??= await getHourlyRtSystemDemand(interval, client: client);

    // filter for the month of interest only
    var ts = new TimeSeries.fromIterable(
        _ts.where((obs) => obs.interval.start.month == month));

    // calculate the hourly shape by day
    var shapeByDay = hourlyShapeByDay(ts);

    // keep only the non-holiday weekdays
    List daysOut = [];
    shapeByDay.keys.forEach((Date day) {
      if (day.isWeekend() || _calendar.isHoliday(day))
        daysOut.add(day);
    });
    daysOut.forEach((day) => shapeByDay.remove(day));


    // find the average shape of this year/month combination
    var byYear = groupBy(shapeByDay.keys, (Date day) => day.year);
    var avgShape = <int,HourlyShape>{};
    byYear.forEach((year,days) {
      avgShape[year] = averageShape(days.map((day) => shapeByDay[day]).toList());
    });


    return avgShape;
  }

}

Map _mthIndex = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12
};

