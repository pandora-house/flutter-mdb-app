import 'package:flutter/material.dart';

class BottomAppBarWidget extends StatefulWidget {
  final ValueChanged<int> parentAction;
  BottomAppBarWidget({Key key, this.parentAction}) : super(key: key);

  @override
  _BottomAppBarWidgetState createState() => _BottomAppBarWidgetState();
}

class _BottomAppBarWidgetState extends State<BottomAppBarWidget> {
  int _selectedIndex = 0;

  final int _indexItem1 = 0;
  final int _indexItem2 = 1;

  void _itemTapped(int index) {
    widget.parentAction(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget build(BuildContext context) {
    return BottomAppBar(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: _selectedIndex != _indexItem2 ? CircularNotchedRectangle() : null,
      child: Container(
        height: 60.0,
        color: Colors.white,
        child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                  child: Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.list_alt,
                      color: _selectedIndex == _indexItem1
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    onPressed: () {
                      _itemTapped(_indexItem1);
                    },
                  ),
                  Text(
                    'read',
                    style: TextStyle(
                      height: 0,
                      color: _selectedIndex == _indexItem1
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                ],
              )),
              Expanded(
                  child: Column(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.settings_applications,
                      color: _selectedIndex == _indexItem2
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    onPressed: () {
                      _itemTapped(_indexItem2);
                    },
                  ),
                  Text(
                    'settings',
                    style: TextStyle(
                      height: 0,
                      color: _selectedIndex == _indexItem2
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                ],
              )),
            ]),
      ),
    );
  }
}
