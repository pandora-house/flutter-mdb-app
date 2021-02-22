import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test_app/block/socket_bloc.dart';
import 'package:test_app/block/socket_event.dart';
import 'package:validators/validators.dart';

class ReadWidgetWidget extends StatefulWidget {
  final bloc;
  ReadWidgetWidget({Key key, this.bloc}) : super(key: key);

  @override
  _ReadWidgetWidgetState createState() => _ReadWidgetWidgetState();
}

class _ReadWidgetWidgetState extends State<ReadWidgetWidget>
    with TickerProviderStateMixin {
  Map<String, dynamic> _data;

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  Animation _arrowAnimation;
  AnimationController _arrowAnimationController;

  @override
  void initState() {
    super.initState();

    widget.bloc.socketEventSink.add(InitEvent());

    _arrowAnimationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 3000));
    _arrowAnimation = Tween(begin: 50.0, end: 70.0).animate(CurvedAnimation(
        curve: Curves.linearToEaseOut, parent: _arrowAnimationController));

    _arrowAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _arrowAnimationController.repeat();
      }
    });

    _arrowAnimationController.forward();
  }

  @override
  void dispose() {
    widget.bloc.socketEventSink.add(DisconnectEvent());
    _arrowAnimationController?.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    var _socketBloc = widget.bloc;

    return StreamBuilder<String>(
        stream: _socketBloc.socketStream,
        builder: (context, AsyncSnapshot<String> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              if (_socketBloc.getConnect == true) {
                return CircularProgressIndicator();
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('press', style: Theme.of(context).textTheme.headline4),
                    _arrowDown(),
                  ],
                );
              }
              break;
            default:
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline3,
                  ),
                );
              } else {
                _data = jsonDecode(snapshot.data);
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        physics: _data['error'].toString().isNotEmpty
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        children: [
                          _cardTransaction(_data),
                          if (_data['error'].toString().isEmpty)
                            _gridviewData(_data, _socketBloc),
                        ],
                      ),
                    ),
                    if (_data['error'].toString().isNotEmpty)
                      Expanded(
                        child: Container(
                          child: Text(
                            'Error: ${_data['error']}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headline3,
                          ),
                        ),
                      ),
                    if (_data['value'].isEmpty &&
                        _data['error'].toString().isEmpty)
                      Expanded(
                          child: Column(
                        children: [
                          CircularProgressIndicator(),
                        ],
                      )),
                  ],
                );
              }
          }
        });
  }

  Widget _arrowDown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          height: 70,
          child: AnimatedBuilder(
            animation: _arrowAnimationController,
            builder: (BuildContext context, Widget child) {
              return ImageIcon(
                AssetImage('assets/down-arrow.png'),
                color: Theme.of(context).colorScheme.secondary,
                size: _arrowAnimation.value,
              );
            },
          )),
    );
  }

  Widget _gridviewData(Map<String, dynamic> data, SocketBloc bloc) {
    const CROSS_AXIS_SPACING = 8;
    double _screenWidth = MediaQuery.of(context).size.width;
    const CROSS_AXIS_COUNT = 2;
    double _width =
        (_screenWidth - ((CROSS_AXIS_COUNT - 1) * CROSS_AXIS_SPACING)) /
            CROSS_AXIS_COUNT;
    const CELL_HEIGHT = 140;
    double _aspectRatio = _width / CELL_HEIGHT;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 0, bottom: 5),
      shrinkWrap: true,
      itemCount: _data['value'].length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: CROSS_AXIS_COUNT, childAspectRatio: _aspectRatio),
      itemBuilder: (context, index) {
        final item = _data['value'][index].split('_');
        String addr = item[0];
        String hex = item[2];
        String value = item[1];

        return GestureDetector(
          onTap: () {
            bool showPopup = (bloc.getSettings['Function']['value'] ==
                        'F01 coil status (0x)' ||
                    bloc.getSettings['Function']['value'] ==
                        'F03 holding register (4x)') &&
                bloc.getConnect;
            if (showPopup) {
              _popUpDialog(bloc, item);
            }
          },
          child: Card(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[500],
                    spreadRadius: 0.7,
                    blurRadius: 0.7,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                      child: Container(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$addr',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ),
                  )),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$value',
                        style: Theme.of(context).textTheme.headline2,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Container(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '$hex',
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            elevation: 1.5,
          ),
        );
      },
    );
  }

  Widget _cardTransaction(Map<String, dynamic> data) {
    const COUNTER_TX = 0;
    const COUNTER_ERR = 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: Card(
        child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[500],
                  spreadRadius: 0.7,
                  blurRadius: 0.7,
                  offset: Offset(1, 1), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Container(
                        width: 80,
                        child: Text('Tx-${data['counters'][COUNTER_TX]}',
                            style: Theme.of(context).textTheme.subtitle1),
                      ),
                    ),
                    Expanded(
                        child: Text('${data['tx']}',
                            style: Theme.of(context).textTheme.bodyText1)),
                  ],
                ),
                const Divider(
                  color: Colors.black,
                  height: 4,
                  thickness: 0.5,
                  indent: 85,
                  endIndent: 5,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Container(
                        width: 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          children: [
                            Text('Rx',
                                style: Theme.of(context).textTheme.subtitle1),
                            if (_data['error'].toString().length > 0)
                              Text('-${data['counters'][COUNTER_ERR]}',
                                  style:
                                      Theme.of(context).textTheme.headline3),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                        child: Text('${data['rx']}',
                            style: Theme.of(context).textTheme.bodyText1)),
                  ],
                ),
              ],
            )),
      ),
    );
  }

  Future<void> _popUpDialog(bloc, item) async {
    TextEditingController _controllerTextEdit = TextEditingController();
    String addr = item[0];
    String value = item[1];
    _controllerTextEdit.text = value;

    int byteOnOf = 0;
    int val;

    const BYTE_OF = 0;
    const BYTE_ON = 255;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '$addr',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          content: bloc.getSettings['Function']['value'] ==
                  'F01 coil status (0x)'
              ? Form(
                  key: _formKey,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: RadioListTile<int>(
                              title: Text('OFF',
                                  style: Theme.of(context).textTheme.bodyText1),
                              value: BYTE_OF,
                              groupValue: byteOnOf,
                              onChanged: (value) {
                                setState(() {
                                  byteOnOf = value;
                                });
                              },
                            ),
                          ),
                          Flexible(
                            child: RadioListTile<int>(
                              title: Text(
                                'ON',
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                              value: BYTE_ON,
                              groupValue: byteOnOf,
                              onChanged: (value) {
                                setState(() {
                                  byteOnOf = value;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Container(
                    child: TextFormField(
                      controller: _controllerTextEdit,
                      style: Theme.of(context).textTheme.bodyText1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        fillColor: Colors.grey[200],
                        filled: true,
                        contentPadding: EdgeInsets.only(left: 14.0),
                        suffixIcon: IconButton(
                          onPressed: () => _controllerTextEdit.clear(),
                          icon: Icon(
                            Icons.clear,
                            size: 18,
                          ),
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          !isNumeric(value) ? 'Invalid' : null,
                    ),
                  ),
                ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                "WRITE",
                style: Theme.of(context).textTheme.subtitle2,
              ),
              onPressed: () {
                if (!_formKey.currentState.validate()) {
                  return;
                }
                int add = int.parse(addr);

                bloc.getSettings['Function']['value'] == 'F01 coil status (0x)'
                    ? val = byteOnOf
                    : val = int.parse(_controllerTextEdit.text);
                bloc.sockWrite(add, val);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
}
