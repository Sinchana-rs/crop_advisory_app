import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/language_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final nameController = TextEditingController(text: "Farmer");
  final locationController =
      TextEditingController(text: "Karnataka, India");
  final cropController = TextEditingController(text: "Tomato");
  final farmController = TextEditingController(text: "2 Acres");

  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: const Color(0xffEEF6E8),

          appBar: AppBar(
            title: Text(
              LanguageService.t("profile"),
            ),
            backgroundColor: Colors.green,

            actions: [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                ),
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? LanguageService.t("editModeEnabled")
                            : LanguageService.t("profileSaved"),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Center(
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(25),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 15,
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    // PROFILE ICON
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.green.shade100,

                      child: const Icon(
                        Icons.person,
                        size: 65,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FARMER NAME
                    Text(
                      nameController.text,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // EMAIL
                    Text(
                      user?.email ??
                          LanguageService.t("noEmail"),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // FARMER NAME
                    profileField(
                      LanguageService.t("farmerName"),
                      nameController,
                    ),

                    const SizedBox(height: 15),

                    // LOCATION
                    profileField(
                      LanguageService.t("location"),
                      locationController,
                    ),

                    const SizedBox(height: 15),

                    // MAIN CROP
                    profileField(
                      LanguageService.t("mainCrop"),
                      cropController,
                    ),

                    const SizedBox(height: 15),

                    // FARM SIZE
                    profileField(
                      LanguageService.t("farmSize"),
                      farmController,
                    ),

                    const SizedBox(height: 25),

                    // INFORMATION BOX
                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: const Color(0xffDDF5D3),
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.agriculture,
                            color: Colors.green,
                            size: 35,
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Text(
                              LanguageService.t(
                                "profileDescription",
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget profileField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      enabled: isEditing,

      decoration: InputDecoration(
        labelText: label,

        filled: true,

        fillColor: isEditing
            ? Colors.white
            : const Color(0xffF4F8F3),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}