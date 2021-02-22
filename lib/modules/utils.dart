class Utils {
  String getHexStr(List<int> data) {
    return data.map((e) {
      if (e.toRadixString(16).length == 1) {
        return '0' + e.toRadixString(16).toUpperCase();
      } else {
        return e.toRadixString(16).toUpperCase();
      }
    }).join(' ');
  }

  String getByteHex(int data) {
    return data.toRadixString(16).length == 1
        ? '0' + data.toRadixString(16).toUpperCase()
        : data.toRadixString(16).toUpperCase();
  }
}
