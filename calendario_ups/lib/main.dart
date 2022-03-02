import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:calendario_ups/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// ignore: unused_element
bool _loading = false;
bool _loadingAnucio = false;
List<Anuncio> lista = [];
List<Calendario> listaCalendario = [];
Future<List<Anuncio>> getAnuncio() async {
  String url = 'http://192.168.60.102:8000/api/anuncio/';
  http.Response response = await http.get(url);
  String val = response.body;
  lista = [];
  List<Anuncio> data = jsonDecode(val)
      .cast<Map<String, dynamic>>()
      .map<Anuncio>((json) => Anuncio.fromJson(json))
      .toList();
  data.forEach((element) {
    lista.add(element);
  });

  return lista;
}

Future<List<Calendario>> getCalendario() async {
  String url = 'http://192.168.60.102:8000/api/calendario/';
  http.Response response = await http.get(url);
  String val = response.body;
  listaCalendario = [];
  List<Calendario> data = jsonDecode(val)
      .cast<Map<String, dynamic>>()
      .map<Calendario>((json) => Calendario.fromJson(json))
      .toList();
  data.forEach((element) {
    listaCalendario.add(element);
  });
  return listaCalendario;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Anuncio>> futureAlbum;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static int cantImagen = 0;
  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('codex_logo');
    var initializationSettingsIOs = IOSInitializationSettings();
    var initSetttings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOs);

    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    loadImage();
  }

  Future onSelectNotification(String payload) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return NewScreen(
        payload: payload,
      );
    }));
  }

  Future<void> loadImage() async {
    // urls.add("https://i.pinimg.com/564x/54/e2/ae/54e2aeefa75d031813ec56f6b3efc9ad.jpg");
    await getCalendario();
    setState(() {
      _loading = true;
      DateTime now = DateTime.now();
      print("ahora " + now.toString());

      for (var item in listaCalendario) {
        var fechaI = DateTime.parse(item.fecha_i);

        if (!fechaI.isBefore(now)) {
          print("se crea notificaicon para la fecha" + fechaI.toString());

          scheduleNotification(fechaI, item.titulo);
        }
      }
    });
    await getAnuncio();
    setState(() {
      print("asdasdasdad " + lista.length.toString());
      cantImagen = lista.length;
      _loadingAnucio = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          appBarTheme: AppBarTheme(color: Colors.blueAccent.shade400)),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_today_rounded)),
                Tab(icon: Icon(Icons.image_aspect_ratio)),
              ],
              onTap: (value) {
                _loading = false;
                _loadingAnucio = false;
                loadImage();
              },
            ),
            title: Text('Calendario UPS'),
          ),
          body: TabBarView(
            children: [
              _loading
                  ? SfCalendar(
                      view: CalendarView.month,
                      dataSource: MeetingDataSource(_getDataSource()),
                      monthViewSettings: MonthViewSettings(showAgenda: true),
                      allowViewNavigation: true,
                      allowedViews: <CalendarView>[
                        CalendarView.day,
                        CalendarView.week,
                        // CalendarView.workWeek,
                        CalendarView.month,
                        CalendarView.schedule
                      ],
                    )
                  : SpinKitDualRing(color: Colors.blueGrey),
              RefreshIndicator(
                child: _loadingAnucio
                    ? Swiper(
                        viewportFraction: 0.8,
                        scale: 0.9,
                        itemBuilder: (BuildContext context, int index) {
                          return new Image.network(
                            lista[index].imagen,
                            fit: BoxFit.fill,
                          );
                        },
                        itemCount: lista.length,
                        pagination: new SwiperPagination(),
                        control: new SwiperControl(),
                      )
                    : SpinKitFadingCircle(
                        itemBuilder: (BuildContext context, int index) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: index.isEven ? Colors.red : Colors.green,
                            ),
                          );
                        },
                      ),
                onRefresh: () async {},
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> scheduleNotification(
      DateTime scheduledNotificationDateTime, String titulo) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel id',
      'channel name',
      'channel description',
      icon: 'codex_logo',
      largeIcon: DrawableResourceAndroidBitmap('codex_logo'),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        0,
        titulo,
        'El evento : ' +
            titulo +
            ' se va a realizar el dia ' +
            scheduledNotificationDateTime.day.toString() +
            ' a las ' +
            scheduledNotificationDateTime.hour.toString() +
            ':' +
            scheduledNotificationDateTime.minute.toString(),
        scheduledNotificationDateTime.subtract(Duration(days: 2)),
        platformChannelSpecifics);
  }
}

List<Meeting> _getDataSource() {
  final List<Meeting> meetings = <Meeting>[];
  DateTime fechaI;

  DateTime endTime;
  List dataColor = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.white,
    Colors.amber,
    Colors.brown,
    Colors.cyan,
    Colors.deepPurpleAccent,
    Colors.lightBlue,
    Colors.teal,
    Colors.pink
  ];

  for (var item in listaCalendario) {
    fechaI = DateTime.parse(item.fecha_i);
    endTime = fechaI.add(Duration(hours: item.duracion));

    meetings.add(Meeting(item.titulo.toString(), fechaI, endTime,
        dataColor[new Random().nextInt(dataColor.length)], false));
  }

  return meetings;
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

class Meeting {
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}

class NewScreen extends StatelessWidget {
  String payload;

  NewScreen({
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(payload),
      ),
    );
  }
}
