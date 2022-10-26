import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import 'package:teragate_v3/config/env.dart';
import 'package:teragate_v3/models/result_model.dart';
import 'package:teragate_v3/models/storage_model.dart';
import 'package:teragate_v3/services/server_service.dart';
import 'package:teragate_v3/state/widgets/bottom_navbar.dart';
import 'package:teragate_v3/state/widgets/coustom_businesscard.dart';
import 'package:teragate_v3/state/widgets/custom_text.dart';
import 'package:teragate_v3/state/widgets/synchonization_dialog.dart';
import 'package:teragate_v3/utils/alarm_util.dart';
import 'package:teragate_v3/utils/time_util.dart';

import 'package:image_picker/image_picker.dart';

class ThemeMain extends StatefulWidget {
  final StreamController eventStreamController;
  final StreamController beaconStreamController;

  const ThemeMain({required this.eventStreamController, required this.beaconStreamController, Key? key}) : super(key: key);

  @override
  State<ThemeMain> createState() => _ThemeState();
}

class _ThemeState extends State<ThemeMain> {
  late SimpleFontelicoProgressDialog dialog;
  late bool _isCheckedTheme;
  late bool _isCheckedBackground;
  bool isImage = false;

  //임시 변수들
  late File _image = File("assets/background1.png");

  List<int> indexImage = [];
  List backgrounListItems = [
    {
      "value": false,
      "image": "background1",
    },
    {
      "value": false,
      "image": "background2",
    },
    {
      "value": false,
      "image": "background3",
    },
    {
      "value": false,
      "image": "background4",
    }
  ];
  late List themeListItmes;

  late SecureStorage secureStorage;
  late BeaconInfoData beaconInfoData;
  WorkInfo? workInfo;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    workInfo = Env.INIT_STATE_WORK_INFO;
    secureStorage = SecureStorage();

    //배열초기화
    _initArray();

    Env.EVENT_FUNCTION = _setUI;
    Env.BEACON_FUNCTION = _setBeaconUI;
    _isCheckedBackground = Env.CHECKED_BACKGOURND;
    _isCheckedTheme = Env.CHECKED_THEME;
    _checkSelectedBackground();
  }

  @override
  Widget build(BuildContext context) {
    dialog = SimpleFontelicoProgressDialog(context: context, barrierDimisable: false, duration: const Duration(milliseconds: 3000));
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return WillPopScope(
      onWillPop: () {
        MoveToBackground.moveTaskToBack();
        return Future(() => false);
      },
      child: Container(
        padding: EdgeInsets.only(top: statusBarHeight),
        decoration: const BoxDecoration(color: Color(0xffF5F5F5)),
        child: Scaffold(
            body: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 40.0,
                      width: 40.0,
                      margin: const EdgeInsets.only(top: 20.0, right: 20.0),
                      // padding: const EdgeInsets.all(1.0),
                      decoration: const BoxDecoration(),
                      child: Material(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6.0),
                        ),
                        child: InkWell(
                          onTap: () {
                            showLogoutDialog(context);
                            // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6.0),
                          ),
                          child: const Icon(
                            Icons.logout,
                            size: 18.0,
                            color: Color(0xff3450FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // 헤더
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              padding: const EdgeInsets.only(top: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CustomText(
                                    text: "메인 테마 설정",
                                    size: 18,
                                    weight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 테마 변경
                      Expanded(
                        flex: 7,
                        child: createContainer(
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const CustomText(
                                    text: "테마 배경 사용",
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  Switch(
                                      value: true, // 항상 켜짐(기능은 비활성화)
                                      activeColor: Colors.white,
                                      activeTrackColor: const Color(0xff26C145),
                                      inactiveTrackColor: const Color(0xff444653),
                                      onChanged: (value) {})
                                ],
                              ),

                              //스크롤뷰로 감싸야 하는 곳
                              Expanded(
                                child: Column(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                                activeColor: const Color(0xffF5F5F5),
                                                checkColor: Colors.black,
                                                value: _isCheckedBackground,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _isCheckedBackground = value!;
                                                  });
                                                  Env.CHECKED_BACKGOURND = value!;
                                                }),
                                            const CustomText(
                                              text: "배경색 사용",
                                              size: 14,
                                              weight: FontWeight.w400,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        AnimatedOpacity(
                                          opacity: _isCheckedBackground ? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 500),
                                          child: Visibility(
                                            maintainAnimation: true,
                                            maintainState: true,
                                            visible: _isCheckedBackground,
                                            child: Row(
                                              children: List.generate(backgrounListItems.length, (index) => initContainerByImageBox(list: backgrounListItems, index: index)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                                activeColor: const Color(0xffF5F5F5),
                                                checkColor: Colors.black,
                                                value: _isCheckedTheme,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _isCheckedTheme = value!;
                                                  });
                                                  Env.CHECKED_THEME = value!;
                                                }),
                                            const CustomText(
                                              text: "테마 사용",
                                              size: 14,
                                              weight: FontWeight.w400,
                                              color: Colors.black,
                                            ),
                                            //조건부 넣어야하는지 물어보기.
                                            SizedBox(width: 50, child: TextButton(onPressed: _addCustomBackground, child: Text(" + ", style: TextStyle(fontSize: 20)))),
                                            SizedBox(width: 40, child: TextButton(onPressed: _deleteCustomBackground, child: Text(" - ", style: TextStyle(fontSize: 20, color: Colors.red)))),

                                            //이미지버튼 추가(리스트에 삽입해야함. )
                                          ],
                                        ),
                                        AnimatedOpacity(
                                            opacity: _isCheckedTheme ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 500),

                                            //저장된 테마값이 5개 이상일때는 스크롤뷰로 넣고, 아니면 기존 컬럼으로 넣기.
                                            child: themeListItmes.length > 5
                                                ? SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Column(
                                                      children: [
                                                        Visibility(
                                                          maintainAnimation: true,
                                                          maintainState: true,
                                                          visible: _isCheckedTheme,
                                                          child: Row(
                                                            //스크롤뷰로 감싸기.
                                                            children: List.generate(themeListItmes.length, (index) => initContainerByImageBox(list: themeListItmes, index: index)),
                                                          ),
                                                        ),
                                                      ],
                                                    ))
                                                : Column(
                                                    children: [
                                                      Visibility(
                                                        maintainAnimation: true,
                                                        maintainState: true,
                                                        visible: _isCheckedTheme,
                                                        child: Row(
                                                          //스크롤뷰로 감싸기.
                                                          children: List.generate(themeListItmes.length, (index) => initContainerByImageBox(list: themeListItmes, index: index)),
                                                        ),
                                                      ),
                                                    ],
                                                  ))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 프로필
                      Expanded(
                          flex: 2,
                          child: Container(
                              padding: const EdgeInsets.only(top: 8),
                              child: createContainerwhite(CustomBusinessCard(Env.WORK_COMPANY_NAME, Env.WORK_KR_NAME, Env.WORK_POSITION_NAME, Env.WORK_PHOTO_PATH, workInfo)))),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavBar(currentLocation: Env.CURRENT_PLACE, currentTime: getPickerTime(getNow()), function: _synchonizationThemeUI)),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Container createContainer(Widget widget) {
    return Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: widget);
  }

  Container createContainerwhite(Widget widget) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: widget);
  }

  //이미지 박스

  Container initContainerByImageBox({required int index, required list}) {
    return Container(
        margin: const EdgeInsets.all(8),
        height: 100,
        width: 50,
        decoration: list[index]["value"] ? BoxDecoration(border: Border.all(color: const Color(0xff26C145), width: 5)) : null,
        child: GestureDetector(
            onTap: () {
              setState(() {
                print("인덱스 클릭 : " + index.toString() + ' , ' + list[index]["image"]);

                //바로 홈화면으로 가게

                _initListReset();
                list[index]["value"] = true;

                //탭하면 포인터 유지될수 있도록 변경
                var jsonVar = json.encode(themeListItmes);

                print("LOG jsonVar : " + jsonVar);

                secureStorage.write("tempListVar", jsonVar);
              });

              // _setBackgroundPath("${list[index]["image"]}.png");

              if (list[index]["image"].toString().startsWith("/data")) {
                //커스텀 이미지

                _setBackgroundPath(list[index]["image"]);

                print("넘기는 값 : " + list[index]["image"]);
              } else {
                //기본 이미지
                _setBackgroundPath("${list[index]["image"]}.png");

                print("넘기는 값 : " + "${list[index]["image"]}.png");
              }
            },
            //커스텀 이미지일때만 특정 UI를 사용.

            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: list[index]["image"].toString().startsWith('/data')
                          ?
                          //data 시작이 맞으면
                          FileImage(File(list[index]["image"]))
                          :
                          //기존 이미지면
                          AssetImage("assets/${list[index]["image"]}.png") as ImageProvider,
                      fit: BoxFit.fill
                      // Image.asset("assets/${list[index]["image"]}.png", fit: BoxFit.fitHeight) as ImageProvider,
                      )),
            )));
  }

  void _setUI(WorkInfo workInfo) {
    setState(() {
      this.workInfo = workInfo;
    });
  }

  void _synchonizationThemeUI(WorkInfo? workInfo) {
    dialog.show(message: "🍄로딩중...🍄");
    sendMessageByWork(context, secureStorage).then((workInfo) {
      if (workInfo!.success) {
        setState(() {});
        dialog.hide();
        showSyncDialog(context,
            widget: SyncDialog(
              warning: true,
            ));
      } else {
        dialog.hide();
        showSyncDialog(context,
            widget: SyncDialog(
              warning: false,
            ));
      }
    });
  }

  void _setBeaconUI(BeaconInfoData beaconInfoData) {
    this.beaconInfoData = beaconInfoData;
    setState(() {});
  }

  void sendToBroadcast(WorkInfo workInfo) {
    widget.eventStreamController.add(workInfo.toString());
  }

  void _setBackgroundPath(String path) {
    secureStorage.write(Env.KEY_BACKGROUND_PATH, path);
    Env.BACKGROUND_PATH = path;
  }

  void _initListReset() {
    for (var el in backgrounListItems) {
      el["value"] = false;
    }
    for (var el in themeListItmes) {
      el["value"] = false;
    }
  }

  void _checkSelectedBackground() {
    for (var el in backgrounListItems) {
      if (Env.BACKGROUND_PATH?.replaceAll(".png", "") == el["image"]) {
        el["value"] = true;
        _isCheckedBackground = true;
      }
    }
    for (var el in themeListItmes) {
      if (Env.BACKGROUND_PATH?.replaceAll(".png", "") == el["image"]) {
        el["value"] = true;
        _isCheckedTheme = true;
      }
    }
  }

  //2022.10.11 커스텀 배경화면 선택기능

  void _addCustomBackground() async {
    ImagePicker _picker = ImagePicker();
    //이미지 선택 후 해당 이미지를 특정 해상도로 불러오기.

    _initListReset();

    try {
      //이미지 저장 한 8개정도로...
      if (themeListItmes.length > 7) {
        print("8개 이상이라 안들어감, 팝업추가할 예정");

        FlutterDialog(context, "이미지 개수 제한", "8개 이상으로는 추가할 수 없습니다.");
      } else {
        XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          // maxWidth: 621,
          // maxHeight: 1344,
        );

        //NULL 체크
        if (pickedFile != null) {
          _image = File(pickedFile.path);

          //배열초기화.
          _initListReset();

          //배열에 파일 추가.

          String jsonString = '{"value" : false , "image" : "' + _image.path + '"}';

          print("sampleJSON : " + jsonString);

          themeListItmes.add(jsonDecode(jsonString));

          setState(() {
            //이미지 삽입 준비하기(메인)
            print("LOG : Image Path : " + _image.path);

            //선택된 이미지파일을 메인으로 넘기기. (_image.path 를 넘기기.)
            _setBackgroundPath(_image.path);

            var jsonVar = json.encode(themeListItmes);

            print("LOG jsonVar : " + jsonVar);

            secureStorage.write("tempListVar", jsonVar);

            // secureStorage.write("savedValue", jsonString);

            //하이라이트 되는 부분 변경
            themeListItmes.last["value"] = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        //이미지 선택 취소나 오류발생시...
        print("LOG : 임시, 오류발생 혹은 선택취소");
      });
    }
  }

  void _deleteCustomBackground() {
    //조건 : 기존 테마 3개는 고정으로 놔두고 4개째인 커스텀 이미지부터 추가 / 제거작업 하기. 이미지 맥스치 5개(기존 3개 포함.)

    _initListReset();

    print("리스트 개수 : " + themeListItmes.length.toString());

    if (themeListItmes.length > 3) {
      print("이미지 개수 4부터 : " + themeListItmes.length.toString());
      themeListItmes.removeLast();

      //배열 저장 후, 현재 마지막으로 되어있는 이미지를 배경으로 설정.

      var jsonVar = json.encode(themeListItmes);

      print("LOG jsonVar : " + jsonVar);

      secureStorage.write("tempListVar", jsonVar);

      print("마지막 이미지 : " + themeListItmes.last["image"]);

      if (themeListItmes.last["image"] == "theme3") {
        _setBackgroundPath(themeListItmes.last["image"] + ".png");
        //마지막 배열 지우고 다시 배열 생성해서 저장해줘야함...

        // secureStorage.delete("savedValue");
        secureStorage.delete("tempListVar");
      } else {
        _setBackgroundPath(themeListItmes.last["image"]);
      }
      setState(() {});
    } else {
      print("이미지 개수 3부터 : " + themeListItmes.length.toString());

      FlutterDialog(context, "오류", "삭제할 이미지가 없습니다.");

      //마지막 커스텀이미지 삭제시 3번 이미지를 전달
      _setBackgroundPath(themeListItmes.last["image"] + ".png");
      setState(() {});

      // secureStorage.delete("savedValue");
      secureStorage.delete("tempListVar");
    }
    //하이라이트 되는 부분 변경

    themeListItmes.last["value"] = true;
  }

  void _initArray() async {
    themeListItmes = [
      {"value": false, "image": "theme1"},
      {"value": false, "image": "theme2"},
      {"value": false, "image": "theme3"},
    ];

    // secureStorage.delete("savedValue");

    // String? savedValue = await secureStorage.read("savedValue");

    var tempListVar = await secureStorage.read("tempListVar");

    print("LOG : JSONDECODE " + tempListVar!);

    // print("임시 저장값 : " + savedValue.toString());

    if (tempListVar!.isNotEmpty) {
      //널값이 아니면 값이 저장되있다는 의미임. 해당값을 배열에 넣어주기.

      // themeListItmes.clear();

      print("값이 차있을때");

      //배열 전체를 그냥 가져다 박아버림.

      themeListItmes = jsonDecode(tempListVar!);

      // themeListItmes.add(jsonDecode(savedValue.toString()));

      print("마지막 배열 : " + themeListItmes.last.toString() + " / 전체 배열 : " + themeListItmes.toString());

      //UI갱신
    } else {
      //저장된 값이 없으니까 배열저장이 안되있어야함.

      print("값이 없을때");
    }

    setState(() {});
  }
}

//팝업메세지 리스트들...

void FlutterDialog(BuildContext context, String titleText, String bodyText) {
  showDialog(
      context: context,
      //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          //Dialog Main Title
          title: Column(
            children: <Widget>[
              new Text(titleText),
            ],
          ),
          //
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                bodyText,
              ),
            ],
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("확인"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}
