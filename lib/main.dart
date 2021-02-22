
import 'package:flutter/material.dart';
import 'package:test_app/block/socket_bloc.dart';
import 'package:test_app/block/socket_event.dart';
import 'package:test_app/widgets/screens/read.dart';

import 'widgets/screens/settings.dart';
import 'widgets/screens/read.dart';
import 'widgets/bottomappbar.dart';

void main() => runApp(MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  static const String _title = 'Modbus Viewer';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.indigo[800],
        accentColor: Colors.purple,

        fontFamily: 'Inter',

        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 25.0, fontWeight: FontWeight.normal, color: Colors.white),
          headline2: TextStyle(fontSize: 40.0, fontWeight: FontWeight.normal, color: Colors.black),
          headline3: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: Colors.red[700]),
          headline4: TextStyle(fontSize: 30.0, fontWeight: FontWeight.normal, color: Colors.black),
          bodyText1: TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal),
          subtitle1: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800),
          subtitle2: TextStyle(fontSize: 18.0, color: Colors.indigo[800]),
        ),
      ),
      home: MyStatefulWidget(),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  static const INDEX_ITEM_READ = 0;
  static const INDEX_ITEM_SETT = 1;
  int _selectedIndex = 0;
  bool _connect = false;

  SocketBloc _socketBloc = SocketBloc();

  void _itemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Modbus Viewer',
          style: Theme.of(context).textTheme.headline1,
        ),
        actions: [],
      ),
      body: 
      Center(child: Builder(
        builder: (BuildContext context) {
          switch (_selectedIndex) {
            case INDEX_ITEM_READ:
              return ReadWidgetWidget(
                bloc: _socketBloc,
              );
            case INDEX_ITEM_SETT:
              _connect = false;
              return SettingsWidget();
            default:
              return Text(
                'Error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0),
              );
          }
        },
      )),
      bottomNavigationBar: BottomAppBarWidget(parentAction: _itemTapped),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedOpacity(
        duration: Duration(milliseconds: 500),
        opacity: _selectedIndex != INDEX_ITEM_SETT ? 1.0 : 0.0,
        child:
            // bool _connect = _socketBloc.getConnect;
            StreamBuilder<String>(
                stream: _socketBloc.socketStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    _connect = false;
                  }

                  return Container(
                    child: FloatingActionButton(
                      onPressed: () {
                        if (!_connect) {
                          _socketBloc.socketEventSink.add(ConnectEvent());
                          _connect = true;
                        } else {
                          _socketBloc.socketEventSink.add(DisconnectEvent());
                          _connect = false;
                        }
                        setState(() {
                          setState(() => _connect);
                        });
                      },
                      child: Icon(
                        _connect ? Icons.stop : Icons.play_arrow,
                      ),
                    ),
                  );
                }),
      ),
    );
  }
}
