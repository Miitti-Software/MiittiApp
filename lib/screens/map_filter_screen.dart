import 'package:flutter/material.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Text(
            textValue,
            style: const TextStyle(
              fontSize: 19,
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
            activeColor: AppStyle.violet,
            activeTrackColor: AppStyle.lightPurple,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    saveValues();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: AppStyle.pinkGradient),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 8,
                ),
                const Text(
                  'Suodata miittejä',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          makeToggleSwitch(
            'Hae vain samaa sukupuolta',
            searchSameGender,
            'sameGender',
          ),
          const SizedBox(
            height: 10,
          ),
          makeToggleSwitch(
            'Hae useamman ihmisen miittejä',
            searchMultiplePeople,
            'multiplePeople',
          ),
          const SizedBox(
            height: 80,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                const Text(
                  'Ikähaarukka',
                  style: TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                    fontFamily: 'Rubik',
                  ),
                ),
                const Expanded(child: SizedBox()),
                Text(
                  "${_values.start.toStringAsFixed(0)} - ${_values.end.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 19,
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
            activeColor: AppStyle.violet,
            inactiveColor: AppStyle.lightPurple,
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
    );
  }
}
