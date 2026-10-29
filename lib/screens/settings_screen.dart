import 'package:flutter/material.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,

      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: const Color(0xffEEF6E8),

          appBar: AppBar(
            title: Text(
              LanguageService.t("settings"),
            ),
            backgroundColor: Colors.green,
          ),

          body: Padding(
            padding: const EdgeInsets.all(20),

            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: DropdownButtonFormField<String>(
                  value: LanguageService.lang.value,

                  decoration: InputDecoration(
                    labelText: LanguageService.t(
                      "changeLanguage",
                    ),
                    border: const OutlineInputBorder(),
                  ),

                  items: [

                    // ENGLISH
                    DropdownMenuItem(
                      value: "en",
                      child: Text(
                        LanguageService.t("english"),
                      ),
                    ),

                    // KANNADA
                    DropdownMenuItem(
                      value: "kn",
                      child: Text(
                        LanguageService.t("kannada"),
                      ),
                    ),

                    // HINDI
                    DropdownMenuItem(
                      value: "hi",
                      child: Text(
                        LanguageService.t("hindi"),
                      ),
                    ),
                  ],

                  onChanged: (v) {
                    if (v != null) {
                      LanguageService.lang.value = v;
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}