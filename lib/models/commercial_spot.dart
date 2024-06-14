import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/app_style.dart';

class CommercialSpot {
  double long;
  double lati;
  String name;
  String address;
  String image;
  String admin;

  CommercialSpot({
    required this.lati,
    required this.long,
    required this.name,
    required this.address,
    required this.image,
    required this.admin,
  });

  factory CommercialSpot.fromMap(Map<String, dynamic> map) {
    return CommercialSpot(
      lati: map['lati'] ?? 0,
      long: map['long'] ?? 0,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      image: map['image'] ?? '',
      admin: map['admin'] ?? '',
    );
  }

  Card getWidget(bool highlight) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Container(
        height: highlight ? 90.h : 80.h,
        decoration: BoxDecoration(
          color: AppStyle.black,
          border: Border.all(
            color: AppStyle.pink,
            width: highlight ? 2.0 : 1.0,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                width: double.maxFinite,
                child: Image.network(
                  image,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Container(
                color: const Color.fromARGB(200, 0, 0, 0),
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppStyle.activityName,
                  ),
                  AppStyle.gapH10,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        color: AppStyle.pink,
                      ),
                      AppStyle.gapW10,
                      Text(
                        address,
                        style: AppStyle.activitySubName.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                height: 24.w,
                width: 100.h,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppStyle.pink,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  "Sponsoroitu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
