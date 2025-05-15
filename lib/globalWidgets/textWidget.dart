import 'package:flutter/material.dart';

import '../constants/fontConstants.dart';


class ReusableTextWidget extends StatelessWidget {
  final String text;
  final double? fontSize;
  final double? textHeight;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextDecoration? isUnderText;

  const ReusableTextWidget({
    super.key,
    required this.text,
    this.fontSize,
    this.textHeight,
    this.fontFamily,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.textAlign,
    this.maxLines,
    this.isUnderText,
  });


  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: TextStyle(
        fontSize: fontSize ??  13,
        decoration: isUnderText,
        fontFamily: FontConstants.fontFamily,
        decorationColor: color,
        fontWeight: fontWeight ?? FontWeight.normal,
        fontStyle: fontStyle ?? FontStyle.normal,
        color: color ?? Colors.grey.shade900,
        overflow: TextOverflow.ellipsis,
        height: textHeight,
      ),
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}