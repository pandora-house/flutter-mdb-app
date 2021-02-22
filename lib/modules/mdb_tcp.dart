import 'dart:typed_data';

import 'package:test_app/modules/utils.dart';

class Modbus {
  Map<String, dynamic> _map;
  Utils _utils = Utils();

  Modbus(this._map);

  String getIp() => _map['IP']['value'];
  int getPort() => int.parse(_map['Port']['value']);
  int getPollTime() => int.parse(_map['Poll Time, ms']['value']);
  int getTimeOut() => int.parse(_map['Time out, ms']['value']);
  String getFunc() => _map['Function']['value'];
  int getSlaveId() => int.parse(_map['Slave ID']['value']);
  int getStartAddr() => int.parse(_map['Start Address']['value']);
  int getQuantity() => int.parse(_map['Quantity']['value']);
  String getDataType() => _map['Data Type']['value'];

  List<int> getRequestRead() {
    String _funcSett = getFunc();
    int _function;
    int _slaveId = getSlaveId();
    int _startAddr = getStartAddr();
    int _quantity = getQuantity();

    if (_funcSett == 'F01 coil status (0x)') {
      _function = 1;
    } else if (_funcSett == 'F02 input status (1x)') {
      _function = 2;
    } else if (_funcSett == 'F03 holding register (4x)') {
      _function = 3;
    } else if (_funcSett == 'F04 input register (3x)') {
      _function = 4;
    } else {
      _function = 1;
    }

    var quantityMultiply =
        (_function == 3 || _function == 4) && getDataType().contains('Float');
    if (quantityMultiply) {
      _quantity = _quantity * 2;
    }

    Uint8List _request = Uint8List(12);
    ByteData bytesFrame = ByteData.view(_request.buffer);

    bytesFrame.setUint8(0, 0x00);
    bytesFrame.setUint8(1, 0x01);
    bytesFrame.setUint8(2, 0x00);
    bytesFrame.setUint8(3, 0x00);
    bytesFrame.setUint8(4, 0x00);
    bytesFrame.setUint8(5, 0x06);
    bytesFrame.setUint8(6, _slaveId);
    bytesFrame.setUint8(7, _function);
    bytesFrame.setUint8(8, _startAddr >> 8);
    bytesFrame.setUint8(9, _startAddr);
    bytesFrame.setUint8(10, _quantity >> 8);
    bytesFrame.setUint8(11, _quantity);

    return _request;
  }

  List<int> getRequestWrite(int addr, int value) {
    String _funcSett = getFunc();
    int _function;
    int _slaveId = getSlaveId();

    if (_funcSett == 'F01 coil status (0x)') {
      _function = 5;
    } else if (_funcSett == 'F03 holding register (4x)') {
      _function = 6;
    }

    Uint8List _request = Uint8List(12);
    ByteData bytesFrame = ByteData.view(_request.buffer);

    bytesFrame.setUint8(0, 0x00);
    bytesFrame.setUint8(1, 0x01);
    bytesFrame.setUint8(2, 0x00);
    bytesFrame.setUint8(3, 0x00);
    bytesFrame.setUint8(4, 0x00);
    bytesFrame.setUint8(5, 0x06);
    bytesFrame.setUint8(6, _slaveId);
    bytesFrame.setUint8(7, _function);
    bytesFrame.setUint8(8, addr >> 8);
    bytesFrame.setUint8(9, addr);

    if (_funcSett == 'F01 coil status (0x)') {
      bytesFrame.setUint8(10, value);
      bytesFrame.setUint8(11, 0x00);
    } else if (_funcSett == 'F03 holding register (4x)') {
      bytesFrame.setUint8(10, value >> 8);
      bytesFrame.setUint8(11, value);
    }

    return _request;
  }

  String getError(List<int> response) {
    String err = '';
    const BYTE_ERR = 7;
    const BYTE_ERR_CODE = 8;
    bool error = (response[BYTE_ERR] == 128 ||
                response[BYTE_ERR] == 129 ||
                response[BYTE_ERR] == 130 ||
                response[BYTE_ERR] == 131 ||
                response[BYTE_ERR] == 132) &&
            response.length == 9
        ? true
        : false;
    if (error) {
      switch (response[BYTE_ERR_CODE]) {
        case 0x01:
          err = "Illegal function.";
          break;
        case 0x02:
          err = "Illegal data address.";
          break;
        case 0x03:
          err = "Illegal data value.";
          break;
        case 0x04:
          err = "Slave Device Failure.";
          break;
        case 0x05:
          err = "Acknowledge.";
          break;
        case 0x06:
          err = "Slave device busy.";
          break;
        case 0x07:
          err = "Negative acknowledge.";
          break;
        case 0x08:
          err = "Memory parity error.";
          break;
        case 0x0A:
          err = "Gateway path unavailable.";
          break;
        case 0x0B:
          err = "Gateway target device failed to respond.";
          break;
        default:
          err = 'Unknown exception ';
      }
    }
    return err;
  }

  List<String> reverseList(var list) {
    List<String> listTmp = List();
    for (var i = 0; i < list.length; i++) {
      listTmp.add(list[list.length - 1 - i]);
    }
    return listTmp;
  }

  List<String> asBools(int val, int bits) {
    var list = List<String>(bits);
    var mask = 1 << (bits - 1);
    for (var i = 0; i < bits; i++, mask >>= 1) {
      list[i] = '${(val & mask != 0)}_${_utils.getByteHex(val)}';
    }
    return reverseList(list);
  }

  List<String> getData(List<int> response) {
    if (getError(response).length > 0) {
      return [];
    }

    ByteBuffer buff;

    int byteCount = (response[8] & 0xFF).toInt();
    int arrSize, byteStart, step;
    List<String> data;
    String startAddr, hexData;

    bool isTypeBool = getFunc() == 'F01 coil status (0x)' ||
        getFunc() == 'F02 input status (1x)';

    bool isType16 = getDataType().contains('16') &&
        (getFunc() == 'F03 holding register (4x)' ||
            getFunc() == 'F04 input register (3x)');
    bool isType32 = getDataType().contains('32') &&
        (getFunc() == 'F03 holding register (4x)' ||
            getFunc() == 'F04 input register (3x)');

    if (isTypeBool) {
      byteStart = 9;
      arrSize = (byteCount);
      data = new List();

      const BYTES_QUANT = 8;
      int remainder = (byteCount * BYTES_QUANT) % getQuantity();

      if (byteCount == 1) {
        var listTmp = asBools(response[byteStart], getQuantity());
        data.addAll(listTmp);
      } else {
        for (int i = byteStart; i < (byteStart + byteCount); i++) {
          if (i != (byteStart + byteCount) - 1) {
            var listTmp = asBools(response[i], 8);
            data.addAll(listTmp);
          } else {
            var listTmp = asBools(response[i], 8 - remainder);
            data.addAll(listTmp);
          }
        }
      }

      for (int i = 0; i < data.length; i++) {
        startAddr = (getStartAddr() + i).toString();
        data[i] = '${startAddr}_${data[i]}';
      }
    } else if (isType16) {
      byteStart = 10;
      arrSize = (byteCount ~/ 2);
      data = new List(arrSize);
      step = 2;
      for (int i = byteStart, j = 0;
          i < (byteStart + byteCount);
          i += step, j++) {
        switch (getDataType()) {
          case 'UInt16AB':
            buff = Uint8List.fromList([response[i - 1], response[i]]).buffer;
            data[j] = ByteData.view(buff).getUint16(0).toString();
            break;
          case 'UInt16BA':
            buff = Uint8List.fromList([response[i], response[i - 1]]).buffer;
            data[j] = ByteData.view(buff).getUint16(0).toString();
            break;
          case 'Int16AB':
            buff = Uint8List.fromList([response[i - 1], response[i]]).buffer;
            data[j] = ByteData.view(buff).getInt16(0).toString();
            break;
          case 'Int16BA':
            buff = Uint8List.fromList([response[i], response[i - 1]]).buffer;
            data[j] = ByteData.view(buff).getInt16(0).toString();
            break;
        }

        startAddr = (getStartAddr() + j).toString();

        hexData =
            '${_utils.getByteHex(response[i - 1])}_${_utils.getByteHex(response[i])}';

        data[j] = '${startAddr}_${data[j]}_$hexData';
      }
    } else if (isType32) {
      byteStart = 12;
      arrSize = (byteCount ~/ 4);
      data = new List(arrSize);
      step = 4;
      for (int i = byteStart, j = 0;
          i < (byteStart + byteCount);
          i += step, j++) {
        switch (getDataType()) {
          case 'Float32ABCD':
            buff = Uint8List.fromList([
              response[i - 3],
              response[i - 2],
              response[i - 1],
              response[i]
            ]).buffer;
            data[j] = ByteData.view(buff).getFloat32(0).toString();
            break;
          case 'Float32CDAB':
            buff = Uint8List.fromList([
              response[i - 1],
              response[i],
              response[i - 3],
              response[i - 2]
            ]).buffer;
            data[j] = ByteData.view(buff).getFloat32(0).toString();
            break;
          case 'Float32DCBA':
            buff = Uint8List.fromList([
              response[i],
              response[i - 1],
              response[i - 2],
              response[i - 3]
            ]).buffer;
            data[j] = ByteData.view(buff).getFloat32(0).toString();
            break;
          case 'Float32BADC':
            buff = Uint8List.fromList([
              response[i - 2],
              response[i - 3],
              response[i],
              response[i - 1]
            ]).buffer;
            data[j] = ByteData.view(buff).getFloat32(0).toString();
            break;
        }

        startAddr = (getStartAddr() + j * 2).toString();

        hexData = _utils.getByteHex(response[i - 3]) +
            _utils.getByteHex(response[i - 2]) +
            ' ' +
            _utils.getByteHex(response[i - 1]) +
            _utils.getByteHex(response[i]);

        data[j] = '${startAddr}_${data[j]}_$hexData';
      }
    }

    return data;
  }
}
