class SettingsJson {
  SettingsJson();
  final String settingsJson = '''{
      "IP":{
        "value":"127.0.0.1"
      },
      "Port":{
        "value":"502"
      },
      "Slave ID":{
        "value":"1"
      },
      "Function":{
        "value":"F01 coil status (0x)",
        "widget":"radio",
        "radioArr":[
          "F01 coil status (0x)",
          "F02 input status (1x)",
          "F03 holding register (4x)",
          "F04 input register (3x)"
          ],
        "submitBtn":"hide"
      },
      "Start Address":{
        "value":"1"
      },
      "Quantity":{
        "value":"1"
      },
      "Data Type":{
        "value":"Int16AB",
        "widget":"radio",
        "radioArr":[
          "Int16AB",
          "Int16BA",
          "UInt16AB",
          "UInt16BA",
          "Float32ABCD",
          "Float32CDAB",
          "Float32DCBA",
          "Float32BADC"
          ]
      },
      "Poll Time, ms":{
        "value":"500",
        "widget":"slider",
        "sliderMin":"500",
        "sliderMax":"5000",
        "sliderDiv":"15"
      },
      "Time out, ms":{
        "value":"500",
        "widget":"slider",
        "sliderMin":"500",
        "sliderMax":"10000",
        "sliderDiv":"10"
      }
    }''';

}