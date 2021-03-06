//library international_phone_input;

import 'dart:async';
import 'dart:convert';
import 'package:international_phone_input/src/phone_service.dart';
import 'country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InternationalPhoneInput extends StatefulWidget {
  final void Function(String phoneNumber,
      String internationalizedPhoneNumber,
      String isoCode) onPhoneNumberChange;
  final String initialPhoneNumber;
  final String initialSelection;
  final String errorText;
  final String hintText;
  final TextStyle errorStyle;
  final TextStyle hintStyle;
  final int errorMaxLines;
  final TextEditingController controller;

  InternationalPhoneInput(
      {this.onPhoneNumberChange,
      this.initialPhoneNumber,
      this.initialSelection,
      this.errorText,
      this.hintText,
      this.errorStyle,
      this.hintStyle,
      this.errorMaxLines,
      this.controller});

  static Future<String> internationalizeNumber(String number, String iso) {
    return PhoneService.getNormalizedPhoneNumber(number, iso);
  }

  static Future<bool> isPhoneValid(String number, String iso) {
    return PhoneService.parsePhoneNumber(number, iso);
  }

  @override
  _InternationalPhoneInputState createState() =>
      _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {
  Country selectedItem;
  List<Country> itemList = [];

  String errorText;
  String hintText;

  TextStyle errorStyle;
  TextStyle hintStyle;

  int errorMaxLines;



  _InternationalPhoneInputState();

   TextEditingController phoneTextController = TextEditingController();

  @override
  void initState() {
    errorText = widget.errorText ?? '';
    hintText = widget.hintText ?? '';
    errorStyle = widget.errorStyle;
    hintStyle = widget.hintStyle;
    errorMaxLines = widget.errorMaxLines;
    phoneTextController = widget.controller;
    phoneTextController.addListener(_validatePhoneNumber);
    phoneTextController.text = widget.initialPhoneNumber;


    _fetchCountryData().then((list) {
      Country preSelectedItem;

      if (widget.initialSelection != null) {
        preSelectedItem = list.firstWhere(
            (e) =>
                (e.code.toUpperCase() ==
                    widget.initialSelection.toUpperCase()) ||
                (e.dialCode == widget.initialSelection.toString()),
            orElse: () => list[0]);
      } else {
        preSelectedItem = list[0];
      }

      setState(() {
        itemList = list;
        selectedItem = preSelectedItem;
      });
    });

    super.initState();
  }

  _validatePhoneNumber() {
    String phoneText = phoneTextController.text;
    if (phoneText != null && phoneText.isNotEmpty) {
      PhoneService.parsePhoneNumber(phoneText, selectedItem.code)
          .then((isValid) {
        setState(() {
        });
        if (widget.onPhoneNumberChange != null) {
          if (isValid) {
            PhoneService.getNormalizedPhoneNumber(phoneText, selectedItem.code)
                .then((number) {
              widget.onPhoneNumberChange(phoneText, number, selectedItem.code);
            });
          } else {
            widget.onPhoneNumberChange('', '', selectedItem.code);
          }
        }
      });
    }
  }

  Future<List<Country>> _fetchCountryData() async {
    var list = await DefaultAssetBundle.of(context)
        .loadString('packages/international_phone_input/assets/countries.json');
    var jsonList = json.decode(list);
    List<Country> elements = [];
    jsonList.forEach((s) {
      Map elem = Map.from(s);
      elements.add(Country(
          name: elem['en_short_name'],
          code: elem['alpha_2_code'],
          dialCode: elem['dial_code'],
          flagUri: 'assets/flags/${elem['alpha_2_code'].toLowerCase()}.png'));
    });
    return elements;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          DropdownButtonHideUnderline(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: DropdownButton<Country>(
                value: selectedItem,
                onChanged: (Country newValue) {
                  setState(() {
                    selectedItem = newValue;
                  });
                  _validatePhoneNumber();
                },
                items: itemList.map<DropdownMenuItem<Country>>((Country value) {
                  return DropdownMenuItem<Country>(
                    value: value,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Image.asset(
                            value.flagUri,
                            width: 32.0,
                            package: 'international_phone_input',
                          ),
                          SizedBox(width: 4),
                          Text(value.dialCode)
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Flexible(
              child: TextField(
            keyboardType: TextInputType.number,
            controller: phoneTextController,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: hintStyle ?? null,
            ),
          ))
        ],
      ),
    );
  }
}
