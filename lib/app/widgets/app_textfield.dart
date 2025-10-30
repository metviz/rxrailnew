import 'package:RXrail/app/extensions/size.extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../utils/app_color.dart';
import '../utils/text_style.dart';


class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? subHintText;
  final String? labelText2;
  // final String? helperText;
  final int? maxLength;
  final Widget? maxLengthHeight;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final Color? labelTextColor;
  final TextAlignVertical? textAlignVertical;
  final bool isPasswordField;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry? contentPadding;

  final double? height;
  final double? labelTextFontSize;
  final Color? subHintTextColor;
  final Color? borderSideColor;
  final bool? isReadOnly;

  final String? helperText;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final double? borderRadius;

  final bool? isEdit;
  final bool? isChange;
  final bool? isAdd;
  final Widget? prefixIcon;
  final Color? hintTextColor;
  final TextInputAction? textInputAction;
  final bool isContentPadding;
  final GestureTapCallback? editOnTap;
  final Color? fillColor;
  AppTextField(
      {Key? key,
      this.editOnTap,
      this.onChanged,
      this.onEditingComplete,
      this.isReadOnly = false,
      required this.controller,
      this.labelText = "",
      this.isContentPadding = false,
      this.height,
      this.labelTextFontSize,
      this.subHintTextColor,
      this.borderSideColor,
      this.maxLengthHeight,
      this.hintText,
      this.subHintText,
      this.helperText,
      this.maxLength,
      this.obscureText = false,
      this.isPasswordField = false,
      this.suffixIcon,
      this.maxLines = 1,
      this.labelTextColor,
      this.borderRadius = 10,
      this.hintTextColor,
      this.isEdit = false,
      this.isAdd = false,
      this.isChange = false,
      this.textAlignVertical,
      this.textInputAction,
      this.prefixIcon,
      this.labelText2,
      this.validator,
      this.fillColor,this.contentPadding})
      : super(key: key);

  @override
  AppTextFieldState createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // @override
  // void dispose() {
  //   _controller.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.labelText.isNotEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.labelText,
                    style: styleW700(
                      size: widget.labelTextFontSize ?? fontSize16,
                      color: widget.labelTextColor ?? AppColors.color444444,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      widget.labelText2 ?? '',
                      style: styleW700(
                        size: fontSize11,
                        color: AppColors.color444444,
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox(),
        9.hp,
        if (widget.hintText != null) ...[
          Text(
            widget.hintText!,
            style: styleW500(
              size: fontSize13,
              color: AppColors.color7C7C7C,
            ),
          ),
          13.hp,
        ],
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          validator: widget.validator,
          controller: _controller,
          obscureText: widget.isPasswordField ? _obscureText : false,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          scrollPadding: EdgeInsets.zero,
          textAlignVertical:
              widget.textAlignVertical ?? TextAlignVertical.center,
          decoration: InputDecoration(
            contentPadding:widget.contentPadding ?? EdgeInsets.symmetric(horizontal: 11.w, vertical: 0),

            hintText: widget.subHintText,
            filled: true,
            // isDense: true,
            fillColor: widget.fillColor ?? AppColors.colorFFFFFF,
            hintStyle: styleW500(
              color: widget.subHintTextColor ?? AppColors.colorCCCCCC,
              size: fontSize14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 10.r),
              borderSide:  BorderSide(
                // color: widget.borderSideColor ?? Colors.transparent,
                style: BorderStyle.none,
                width: 0,
              ),
            ),

            counterText: '',

            suffixIconConstraints:
                BoxConstraints(maxHeight: 35.h, maxWidth: 50),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPasswordField
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: Center(
                      child: Icon(
                        color: AppColors.color8A8A8A,
                        size: fontSize20,
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  )
                : widget.suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: widget.suffixIcon,
                      )
                    : null,
          ),
          style: const TextStyle(fontSize: fontSize14),
        ),
        // if (widget.helperText != null) const SizedBox(height: 5),
        // if (widget.helperText != null)
        //   Text(
        //     widget.helperText!,
        //     style: styleW500(
        //       size: fontSize12,
        //       color: AppColors.lightGrey,
        //     ),
        //   ),

        if (widget.maxLength != null &&
            widget.maxLength != TextField.noMaxLength) ...[
          widget.maxLengthHeight ?? 4.hp,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_controller.text.length}/${widget.maxLength}',
              style: styleW300(
                size: fontSize14,
                color: AppColors.mediumGrey,
              ),
            ),
          ),
        ],
        10.hp
      ],
    );
  }
}

/// The title text section in the form
///
/// String [title] the title of the section
/// String [subTitle] the sub title of the section
/// String? [miniTitle] the optional mini title text
Widget headAndSubText(String title, String subTitle, String? miniTitle,
    {TextStyle? titleStyle}) {
  if (miniTitle != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: titleStyle ??styleW700(
                size: fontSize38,
                color: AppColors.color7C7C7C,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              miniTitle,
              style: styleW700(
                size: fontSize14,
                color: AppColors.colorAAAAAA,
                height: 0.11,
              ),
            )
          ],
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          subTitle,
          style: styleW500(
            color: AppColors.color7C7C7C,
            size: fontSize16,
          ),
        ),
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: titleStyle ??
            styleW700(
              size: fontSize38,
              color: AppColors.color7C7C7C,
            ),
      ),
      const SizedBox(
        height: 4,
      ),
      Text(
        subTitle,
        style: styleW500(
          color: AppColors.color7C7C7C,
          size: fontSize16,
        ),
      ),
    ],
  );
}
