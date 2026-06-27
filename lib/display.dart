import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/util/ThemeModel.dart';

class Display extends StatelessWidget {
  Display({Key? key, required this.value}) : super(key: key);

  final String value;

  String get _output => value.toString();

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<ThemeModel>(context, listen: false);

          TextStyle style = Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(color: model.textColor1, fontWeight: FontWeight.w400) ?? TextStyle();

    double inset = 30;
    double size = (MediaQuery.of(context).size.width - 40) / 4;
    if (size > 150) {
      inset = (MediaQuery.of(context).size.width - 600) / 2;
    }

    var bottomInset = 20.0;
    if (MediaQuery.of(context).size.height <= 740) {
      bottomInset = 10.0;
              style = Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: model.textColor1, fontWeight: FontWeight.w400) ?? TextStyle();
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
          // padding: EdgeInsets.only(top: _margin, bottom: _margin),
          padding: EdgeInsets.fromLTRB(inset, 0, inset, bottomInset),
          // decoration: BoxDecoration(gradient: _gradient),
          child: AutoSizeText(
            _output,
            style: style,
            maxLines: 2,
          )),
    );
  }
}
