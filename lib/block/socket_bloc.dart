import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/block/socket_event.dart';
import 'package:test_app/modules/mdb_tcp.dart';
import 'package:test_app/modules/settings_json.dart';
import 'package:test_app/modules/utils.dart';

class SocketBloc {
  bool _connect = false;
  int _txCounter = 0;
  int _mdbErrCounter = 0;

  Socket _socketConnected;
  Timer _timer;

  Modbus mdb;
  Utils utils = Utils();

  Map<String, dynamic> _data;
  Map<String, dynamic> _settings;

  final _socketStateController = StreamController<String>.broadcast();

  StreamSink<String> get _socketSink => _socketStateController.sink;
  Stream<String> get socketStream => _socketStateController.stream;

  final _socketEventController = StreamController<SocketEvent>();
  Sink<SocketEvent> get socketEventSink => _socketEventController.sink;

  SocketBloc() {
    _socketEventController.stream.listen(_mapEventToState);
  }

  bool get getConnect => _connect;
  Map<String, dynamic> get getSettings => _settings;

  void _mapEventToState(SocketEvent event) {
    if (event is InitEvent) {
      init();
    } else if (event is ConnectEvent) {
      connect();
    } else if (event is DisconnectEvent) {
      close();
    }
  }

  void connect() async {
    _txCounter = 0;
    _mdbErrCounter = 0;
    _connect = true;

    await Socket.connect(mdb.getIp(), mdb.getPort(),
            timeout: Duration(milliseconds: mdb.getTimeOut()))
        .then((socket) {
      socket.listen((data) {
        _data = {
          "tx": utils.getHexStr(mdb.getRequestRead()),
          "rx": utils.getHexStr(data),
          "value": mdb.getData(data),
          "error": mdb.getError(data),
          "counters": [_txCounter, _mdbErrCounter]
        };

        if (_data['error'].isNotEmpty) {
          _mdbErrCounter++;
        }

        _socketSink.add(jsonEncode(_data));
      }).onError((e) {
        close();
        _socketSink.addError(e);
      });

      _socketConnected = socket;
      return socket;
    }).then((socket) {
      _timer =
          Timer.periodic(Duration(milliseconds: mdb.getPollTime()), (timer) {
        socket.add(mdb.getRequestRead());
        _txCounter++;
      });
    }).catchError((e) {
      close();
      _socketSink.addError(e);
    });
  }

  void sockWrite(int addr, int value) {
    _socketConnected.add(mdb.getRequestWrite(addr, value));
  }

  void close() {
    _timer?.cancel();
    _socketConnected?.close();
    _connect = false;
  }

  init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _settSharedPref =
        (prefs.getString('settings') ?? new SettingsJson().getSettings());
    _settings = jsonDecode(_settSharedPref);
    mdb = Modbus(_settings);
  }

  void dispose() {
    close();
    _socketStateController.close();
    _socketEventController.close();
  }
}
