// import 'package:flutter/material.dart';
// import 'package:miitti_app/constants/app_style.dart';

// class MyElevatedButton extends StatelessWidget {
//   final double? width;
//   final double height;
//   final Gradient gradient;
//   final VoidCallback? onPressed;
//   final Widget child;
//   final EdgeInsetsGeometry? margin;

//   const MyElevatedButton({
//     super.key,
//     required this.onPressed,
//     required this.child,
//     this.margin = EdgeInsets.zero,
//     this.width = 380,
//     this.height = 65,
//     this.gradient = AppStyle.pinkGradient,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width!, // Use .w to make width responsive
//       height: height, // Use .h to make height responsive
//       margin: margin,
//       decoration: BoxDecoration(
//         gradient: gradient,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30.0),
//           ),
//         ),
//         child: child,
//       ),
//     );
//   }
// }
