import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../services/language_service.dart';
import '../services/sensor_service.dart';

// Same Flask server this screen already used for the AI answer.
String get _voiceBaseUrl => apiBaseUrl;

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();
  final AudioPlayer player = AudioPlayer();

  bool isListening = false;
  bool isLoading = false;
  bool isSpeaking = false;

  // The voice language is ALWAYS the app language, so the AI answer,
  // the text on screen and the speech can never disagree.
  String get selectedLang => LanguageService.voiceLang();

  String _lastLang = LanguageService.lang.value;

  String spokenText = "";
  String reply = "";

  // Increases on every language change / new request so late
  // responses from an old language are ignored.
  int _requestId = 0;

  final Map<String, String> languages = {
    "English": "en-IN",
    "ಕನ್ನಡ": "kn-IN",
    "हिंदी": "hi-IN",
  };

  @override
  void initState() {
    super.initState();
    LanguageService.lang.addListener(_onLanguageChanged);
  }

  // A reply generated in the previous language must not stay on
  // screen (or keep playing) after the language changes.
  void _onLanguageChanged() {
    if (LanguageService.lang.value == _lastLang) return;
    _lastLang = LanguageService.lang.value;
    _requestId++;
    tts.stop();
    player.stop();
    speech.stop();
    if (!mounted) return;
    setState(() {
      isListening = false;
      isLoading = false;
      isSpeaking = false;
      spokenText = "";
      reply = "";
    });
  }

  // =========================================================
  // REMOVE MARKDOWN FROM AI RESPONSE
  // =========================================================

  String cleanTextForSpeech(String text) {
    String cleaned = text;

    // Remove **bold**
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (m) => m.group(1) ?? '',
    );

    // Remove __bold__
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__(.*?)__'),
      (m) => m.group(1) ?? '',
    );

    // Remove headings like ###
    cleaned = cleaned.replaceAll(
      RegExp(r'#{1,6}\s*'),
      '',
    );

    // Remove backticks
    cleaned = cleaned.replaceAll('`', '');

    // Remove remaining *
    cleaned = cleaned.replaceAll('*', '');

    // Remove markdown bullet points
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*[-•]\s*', multiLine: true),
      '',
    );

    // Remove numbered list symbols like 1. 2. 3.
    cleaned = cleaned.replaceAll(
      RegExp(r'^\s*\d+[.)]\s*', multiLine: true),
      '',
    );

    // Remove unnecessary extra spaces
    cleaned = cleaned.replaceAll(
      RegExp(r'\n\s*\n'),
      '\n',
    );

    return cleaned.trim();
  }

  // =========================================================
  // START LISTENING
  // =========================================================

  Future<void> startListening() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
      },
      onError: (error) {
        debugPrint("Speech error: $error");
      },
    );

    if (!available) {
      setState(() {
        reply = LanguageService.t("speechNotAvailable");
      });
      return;
    }

    await tts.stop();
    await player.stop();

    setState(() {
      isListening = true;
      isSpeaking = false;
      spokenText = "";
      reply = "";
    });

    await speech.listen(
      localeId: selectedLang,
      onResult: (result) {
        setState(() {
          spokenText = result.recognizedWords;
        });
      },
    );
  }

  // =========================================================
  // STOP LISTENING
  // =========================================================

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      isListening = false;
    });

    if (spokenText.trim().isNotEmpty) {
      await getAIReply();
    }
  }

  // =========================================================
  // GET AI RESPONSE
  // =========================================================

  Future<void> getAIReply() async {
    final int myRequest = ++_requestId;
    final String langCode = LanguageService.lang.value;

    setState(() {
      isLoading = true;
      reply = "";
    });

    try {
      final response = await http
          .post(
            Uri.parse("$_voiceBaseUrl/ai_voice_advisor"),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "question": spokenText,
              // Same code the rest of the app uses ("en"/"kn"/"hi").
              "lang": langCode,
            }),
          )
          .timeout(const Duration(seconds: 90));

      debugPrint("Server status: ${response.statusCode}");
      debugPrint("Server response: ${response.body}");

      // The language changed (or a newer request started) while
      // waiting: drop this answer instead of showing it.
      if (!mounted || myRequest != _requestId) return;

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 && data["success"] == true) {
        String answer =
            cleanTextForSpeech(data["answer"]?.toString() ?? "");

        if (answer.isEmpty) {
          setState(() {
            reply = LanguageService.t("voiceNoAnswer");
            isLoading = false;
          });
          return;
        }

        setState(() {
          reply = answer;
          isLoading = false;
        });

        await speak(answer, myRequest);
      } else {
        // Error text always comes from the app's own translations so
        // an English server message never appears in Kannada/Hindi.
        final type = data["error_type"]?.toString();

        String errorMessage;
        if (type == "quota") {
          errorMessage = LanguageService.t("quotaReached");
        } else if (type == "api_key") {
          errorMessage = LanguageService.t("apiKeyProblem");
        } else {
          errorMessage =
              "${LanguageService.t("serverError")}: ${response.statusCode}";
        }

        setState(() {
          reply = errorMessage;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("VOICE ASSISTANT ERROR: $e");

      if (!mounted || myRequest != _requestId) return;

      setState(() {
        reply = LanguageService.t("connectionError");
        isLoading = false;
      });
    }
  }

  // =========================================================
  // TEXT TO SPEECH
  // =========================================================
  //
  // English / Hindi: unchanged, the device voice (flutter_tts).
  //
  // Kannada: most devices (Windows, Chrome, many phones) have no
  // Kannada voice and flutter_tts then stays silent without any
  // error, so Kannada is synthesised by the Flask /tts endpoint
  // and played with audioplayers. If that fails the device voice
  // is tried as a last resort, and if nothing can speak the user
  // sees a message instead of silence.
  //

  Future<void> speak(String text, [int? requestId]) async {
    if (text.trim().isEmpty) {
      return;
    }

    final int myRequest = requestId ?? _requestId;
    final String langCode = LanguageService.lang.value;
    final cleanText = cleanTextForSpeech(text);

    setState(() {
      isSpeaking = true;
    });

    bool spoken = false;

    try {
      if (langCode == "kn") {
        spoken = await _speakViaServer(cleanText, langCode, myRequest);

        if (!spoken && myRequest == _requestId) {
          spoken = await _speakViaDevice(cleanText);
        }
      } else {
        spoken = await _speakViaDevice(cleanText);

        if (!spoken && myRequest == _requestId) {
          spoken = await _speakViaServer(cleanText, langCode, myRequest);
        }
      }
    } catch (e) {
      debugPrint("TTS ERROR: $e");
    }

    if (!mounted) return;

    setState(() {
      isSpeaking = false;
    });

    if (!spoken && myRequest == _requestId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageService.t("audioUnavailable")),
        ),
      );
    }
  }

  Future<bool> _speakViaDevice(String cleanText) async {
    try {
      await tts.stop();

      final result = await tts.setLanguage(selectedLang);
      debugPrint("TTS setLanguage($selectedLang) -> $result");

      await tts.setSpeechRate(0.65);

      await tts.setPitch(1.0);

      await tts.awaitSpeakCompletion(true);

      final spoke = await tts.speak(cleanText);
      debugPrint("TTS device speak -> $spoke");

      return spoke == 1 || spoke == true;
    } catch (e) {
      debugPrint("Device TTS error: $e");
      return false;
    }
  }

  Future<bool> _speakViaServer(
    String cleanText,
    String langCode,
    int requestId,
  ) async {
    StreamSubscription<void>? completeSub;

    try {
      await tts.stop();
      await player.stop();

      final response = await http
          .post(
            Uri.parse("$_voiceBaseUrl/tts"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": cleanText,
              "lang": langCode,
              "as_url": true,
            }),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint("TTS server status: ${response.statusCode}");

      if (response.statusCode != 200) return false;

      // Language changed while the audio was being prepared.
      if (!mounted || requestId != _requestId) return true;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final path = data["path"]?.toString() ?? "";

      if (path.isEmpty) return false;

      final done = Completer<bool>();

      completeSub = player.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete(true);
      });

      await player.play(UrlSource("$_voiceBaseUrl$path"));

      // Wait until playback finishes (or is stopped / language changes).
      while (!done.isCompleted) {
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted || requestId != _requestId) break;

        if (player.state == PlayerState.stopped ||
            player.state == PlayerState.disposed) {
          break;
        }
      }

      return true;
    } catch (e) {
      debugPrint("Server TTS error: $e");
      return false;
    } finally {
      await completeSub?.cancel();
    }
  }

  // =========================================================
  // STOP VOICE
  // =========================================================

  Future<void> stopSpeaking() async {
    await tts.stop();
    await player.stop();

    setState(() {
      isSpeaking = false;
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    LanguageService.lang.removeListener(_onLanguageChanged);
    _requestId++;
    speech.stop();
    tts.stop();
    player.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,

      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F1),

          // =====================================================
          // APP BAR
          // =====================================================

          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,

            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            title: Row(
              children: [
                const Icon(
                  Icons.agriculture,
                  size: 30,
                ),

                const SizedBox(width: 10),

                Text(
                  LanguageService.t("appName"),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // BODY
          // =====================================================

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // =================================================
                  // TITLE
                  // =================================================

                  Center(
                    child: Column(
                      children: [

                        const SizedBox(height: 10),

                        Text(
                          LanguageService.t("voiceTitle"),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          LanguageService.t(
                            "voiceSubtitle",
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // LANGUAGE SELECTION
                  // =================================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(15),

                      border: Border.all(
                        color: Colors.green.shade200,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLang,

                        isExpanded: true,

                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF2E7D32),
                        ),

                        items: languages.entries.map(
                          (entry) {
                            return DropdownMenuItem<String>(
                              value: entry.value,

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.language,
                                    color:
                                        Color(0xFF2E7D32),
                                  ),

                                  const SizedBox(width: 12),

                                  Text(
                                    entry.key,
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),

                        onChanged: (value) {
                          if (value == null) return;

                          // Changing the language here changes it for the
                          // whole app (and is saved), so text, AI answer
                          // and speech always stay in the same language.
                          LanguageService.changeLanguage(
                            LanguageService.codeFromLocale(value),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // =================================================
                  // MICROPHONE
                  // =================================================

                  Center(
                    child: Column(
                      children: [

                        GestureDetector(
                          onTap: isListening
                              ? stopListening
                              : startListening,

                          child: AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 300,
                            ),

                            width: isListening
                                ? 155
                                : 140,

                            height: isListening
                                ? 155
                                : 140,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              color: isListening
                                  ? Colors.red.shade600
                                  : const Color(
                                      0xFF43A047,
                                    ),

                              boxShadow: [
                                BoxShadow(
                                  color: isListening
                                      ? Colors.red
                                          .withOpacity(0.25)
                                      : Colors.green
                                          .withOpacity(0.30),

                                  blurRadius: 25,

                                  spreadRadius: 5,
                                ),
                              ],
                            ),

                            child: Icon(
                              isListening
                                  ? Icons.stop
                                  : Icons.mic,

                              color: Colors.white,

                              size: 65,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          isListening
                              ? LanguageService.t(
                                  "listening",
                                )
                              : LanguageService.t(
                                  "tapMicrophone",
                                ),

                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isListening
                                ? Colors.red.shade700
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // =================================================
                  // YOU SAID
                  // =================================================

                  _sectionTitle(
                    icon: Icons.person,
                    title: LanguageService.t(
                      "youSaid",
                    ),
                  ),

                  const SizedBox(height: 10),

                  _messageCard(
                    text: spokenText.isEmpty
                        ? LanguageService.t(
                            "questionPlaceholder",
                          )
                        : spokenText,

                    borderColor:
                        Colors.grey.shade300,

                    textColor: spokenText.isEmpty
                        ? Colors.grey
                        : Colors.black87,
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // AI RESPONSE
                  // =================================================

                  _sectionTitle(
                    icon: Icons.auto_awesome,
                    title: LanguageService.t(
                      "assistantReply",
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(18),

                      border: Border.all(
                        color: Colors.green.shade300,
                        width: 1.5,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.green
                              .withOpacity(0.08),

                          blurRadius: 15,

                          offset:
                              const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: isLoading

                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(15),

                              child: Column(
                                children: [

                                  const CircularProgressIndicator(
                                    color:
                                        Color(0xFF43A047),
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Text(
                                    LanguageService.t(
                                      "thinking",
                                    ),

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )

                        : Text(
                            reply.isEmpty
                                ? LanguageService.t(
                                    "answerPlaceholder",
                                  )
                                : reply,

                            style: TextStyle(
                              fontSize: 17,

                              height: 1.6,

                              color: reply.isEmpty
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // SPEAKING STATUS
                  // =================================================

                  if (isSpeaking)
                    Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 18,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.green.shade50,

                        borderRadius:
                            BorderRadius.circular(12),

                        border: Border.all(
                          color:
                              Colors.green.shade200,
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          const Icon(
                            Icons.volume_up,
                            color:
                                Color(0xFF2E7D32),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            LanguageService.t(
                              "aiSpeaking",
                            ),

                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w600,

                              color:
                                  Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 15),

                  // =================================================
                  // STOP VOICE BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,

                    height: 55,

                    child: OutlinedButton.icon(
                      onPressed: isSpeaking
                          ? stopSpeaking
                          : null,

                      icon: const Icon(
                        Icons.volume_off,
                      ),

                      label: Text(
                        LanguageService.t(
                          "stopVoice",
                        ),

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(0xFF2E7D32),

                        side: BorderSide(
                          color:
                              Colors.green.shade700,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // BOTTOM INFORMATION
                  // =================================================

                  Center(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Icon(
                          Icons.eco,
                          size: 18,
                          color:
                              Colors.green.shade700,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          LanguageService.t(
                            "smartFarming",
                          ),

                          style: TextStyle(
                            color:
                                Colors.green.shade700,

                            fontSize: 13,

                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [

        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: 25,
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MESSAGE CARD
  // =========================================================

  Widget _messageCard({
    required String text,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: borderColor,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 17,

          height: 1.5,

          color: textColor,
        ),
      ),
    );
  }
}