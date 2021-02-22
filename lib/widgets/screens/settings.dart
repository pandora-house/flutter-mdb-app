import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:test_app/modules/settings_json.dart';
import 'dart:convert';
import 'package:validators/validators.dart';
import 'package:regexed_validator/regexed_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsWidget extends StatefulWidget {
  SettingsWidget({Key key}) : super(key: key);

  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  String _jsonStr = new SettingsJson().settingsJson;

  TextEditingController _controllerTextEdit = TextEditingController();

  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  Map<String, dynamic> _settingsMap;
  Future<Map<String, dynamic>> _futureSettingsMap;

  @override
  void initState() {
    super.initState();
    _futureSettingsMap = _getSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
        future: _futureSettingsMap,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            default:
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 20.0),
                );
              } else {
                _settingsMap = snapshot.data;
                return ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: _settingsMap.length,
                  itemBuilder: (BuildContext context, int index) {
                    String settKey = _settingsMap.keys.toList()[index];
                    String settValue = _settingsMap[settKey]['value'];

                    return Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey, width: 0.5))),
                      child: InkWell(
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          _popUpDialog(settKey);
                        },
                        child: ListTile(
                          title: Text(
                            '$settKey',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          subtitle: Text(
                            '$settValue',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 0.0, horizontal: 16.0),
                          dense: true,
                        ),
                      ),
                    );
                  },
                );
              }
          }
        });
  }

  Future<Map<String, dynamic>> _getSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _jsonSettStr = (prefs.getString('settings') ?? _jsonStr);
    Map<String, dynamic> _jsonSettMap = jsonDecode(_jsonSettStr);
    return _jsonSettMap;
  }

  _updateState(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _settingsMap[key]['value'] = value;
    prefs.setString('settings', jsonEncode(_settingsMap));
  }

  _validators(String key, String value) {
    if (key == 'IP') {
      return !validator.ip(value) ? 'Invalid' : null;
    } else if (key == 'Slave ID') {
      if (!isNumeric(value)) {
        return 'Invalid';
      } else if (int.parse(value) > 255) {
        return 'ID greater than 255';
      } else {
        return null;
      }
    }
    return !isNumeric(value) ? 'Invalid' : null;
  }

  Future<void> _popUpDialog(String key) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '$key',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          content: _popUpDialogWidget(key),
          actions: <Widget>[
            FlatButton(
              child: Text(
                "SUBMIT",
                style: Theme.of(context).textTheme.subtitle2,
              ),
              onPressed: () {
                if (!_formKey.currentState.validate()) {
                  return;
                }
                _formKey.currentState.save();
                setState(() {
                  _updateState(key, _controllerTextEdit.text);
                });
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  _popUpDialogWidget(String key) {
    if (_settingsMap[key]['widget'] == 'radio') {
      List<String> listVal = List<String>.from(_settingsMap[key]['radioArr']);
      int _currIndex = listVal.indexOf(_settingsMap[key]['value']);
      return Form(
        key: _formKey,
        child: Container(
          width: double.maxFinite,
          height: 222,
          child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: listVal.length,
              itemBuilder: (BuildContext context, int index) {
                return RadioListTile(
                  value: index,
                  groupValue: _currIndex,
                  title: Text(
                    listVal.elementAt(index),
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currIndex = value;
                      _controllerTextEdit.text = listVal[_currIndex];
                    });
                  },
                );
              },
            );
          }),
        ),
      );
    } else if (_settingsMap[key]['widget'] == 'slider') {
      double _sliderValue = double.parse(_settingsMap[key]['value']);
      _controllerTextEdit.text = _settingsMap[key]['value'];
      return Form(
        key: _formKey,
        child: Container(
          width: double.maxFinite,
          height: 90,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(_controllerTextEdit.text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Slider(
                      activeColor: Theme.of(context).accentColor,
                      inactiveColor: Colors.grey[300],
                      value: _sliderValue,
                      min: double.parse(_settingsMap[key]['sliderMin']),
                      max: double.parse(_settingsMap[key]['sliderMax']),
                      divisions: int.parse(_settingsMap[key]['sliderDiv']),
                      onChanged: (double value) {
                        setState(() {
                          _sliderValue = value;
                          _controllerTextEdit.text = value.toInt().toString();
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } else {
      _controllerTextEdit.text = _settingsMap[key]['value'];
      return Form(
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
            validator: (value) => _validators(key, value),
          ),
        ),
      );
    }
  }
}
