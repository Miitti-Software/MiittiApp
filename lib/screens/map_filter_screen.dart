import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';

import '../functions/filter_settings.dart';

//TODO: New UI
class MapFilter extends StatefulWidget {
  const MapFilter({super.key});

  @override
  State<MapFilter> createState() => _MapFilterState();
}

class _MapFilterState extends State<MapFilter> {
  bool searchSameGender = false;
  bool searchMultiplePeople = true;

  FilterSettings filterSettings = FilterSettings();

  RangeValues _values = const RangeValues(18, 60);

  @override
  void initState() {
    super.initState();
    filterSettings.loadPreferences().then((_) {
      setState(() {
        searchSameGender = filterSettings.sameGender;
        searchMultiplePeople = filterSettings.multiplePeople;
        _values = RangeValues(filterSettings.minAge, filterSettings.maxAge);
      });
    });
  }

  @override
  void dispose() {
    saveValues();
    super.dispose();
  }

  void saveValues() {
    filterSettings.sameGender = searchSameGender;
    filterSettings.multiplePeople = searchMultiplePeople;
    filterSettings.minAge = _values.start;
    filterSettings.maxAge = _values.end;
    filterSettings.savePreferences();
  }

  void toggleSwitch(String target) {
    setState(() {
      if (target == 'sameGender') {
        searchSameGender = !searchSameGender;
      } else if (target == 'multiplePeople') {
        searchMultiplePeople = !searchMultiplePeople;
      }
    });
  }

  Widget makeToggleSwitch(String textValue, bool value, String target) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.0.w),
      child: Row(
        children: [
          Text(
            textValue,
            style: TextStyle(
              fontSize: 19.sp,
              color: Colors.white,
              fontFamily: 'Rubik',
            ),
          ),
          const Expanded(child: SizedBox()),
          Switch(
            value: value,
            onChanged: (comingValue) {
              toggleSwitch(target);
            },
            activeColor: AppStyle.purpleColor,
            activeTrackColor: AppStyle.lightPurpleColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.0.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      saveValues();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 60.w,
                      width: 60.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: const LinearGradient(
                          colors: [
                            AppStyle.lightRedColor,
                            AppStyle.orangeColor,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30.r,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 8,
                  ),
                  Text(
                    'Suodata miittejä',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30.h,
            ),
            makeToggleSwitch(
              'Hae vain samaa sukupuolta',
              searchSameGender,
              'sameGender',
            ),
            SizedBox(
              height: 10.h,
            ),
            makeToggleSwitch(
              'Hae useamman ihmisen miittejä',
              searchMultiplePeople,
              'multiplePeople',
            ),
            SizedBox(
              height: 80.h,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.0.w),
              child: Row(
                children: [
                  Text(
                    'Ikähaarukka',
                    style: TextStyle(
                      fontSize: 19.sp,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Text(
                    "${_values.start.toStringAsFixed(0)} - ${_values.end.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 19.sp,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
            RangeSlider(
              values: _values,
              min: 18,
              max: 80,
              activeColor: AppStyle.purpleColor,
              inactiveColor: AppStyle.lightPurpleColor,
              onChanged: (RangeValues newValues) {
                setState(() {
                  _values = newValues;
                });
              },
              labels: RangeLabels(
                _values.start.toStringAsFixed(0),
                _values.end.toStringAsFixed(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
