import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/language_service.dart';

class CropPriceScreen extends StatefulWidget {
  @override
  State<CropPriceScreen> createState() => _CropPriceScreenState();
}

class _CropPriceScreenState extends State<CropPriceScreen> {
  List prices = [];
  bool loading = false;

  final commodityController = TextEditingController(text: "Tomato");
  final stateController = TextEditingController(text: "Karnataka");

  final List<Map<String, String>> fallbackPrices = [
    {
      "commodity": "Tomato",
      "market": "Bengaluru",
      "district": "Bengaluru Urban",
      "arrival_date": "Today",
      "min_price": "40",
      "max_price": "80",
      "modal_price": "60",
    },
    {
      "commodity": "Onion",
      "market": "Mysuru",
      "district": "Mysuru",
      "arrival_date": "Today",
      "min_price": "30",
      "max_price": "70",
      "modal_price": "50",
    },
    {
      "commodity": "Potato",
      "market": "Hubballi",
      "district": "Dharwad",
      "arrival_date": "Today",
      "min_price": "25",
      "max_price": "60",
      "modal_price": "40",
    },
    {
      "commodity": "Rice",
      "market": "Mandya",
      "district": "Mandya",
      "arrival_date": "Today",
      "min_price": "45",
      "max_price": "90",
      "modal_price": "70",
    },
    {
      "commodity": "Wheat",
      "market": "Belagavi",
      "district": "Belagavi",
      "arrival_date": "Today",
      "min_price": "35",
      "max_price": "65",
      "modal_price": "50",
    },
    {
      "commodity": "Maize",
      "market": "Davanagere",
      "district": "Davanagere",
      "arrival_date": "Today",
      "min_price": "28",
      "max_price": "55",
      "modal_price": "42",
    },
    {
      "commodity": "Ragi",
      "market": "Tumakuru",
      "district": "Tumakuru",
      "arrival_date": "Today",
      "min_price": "38",
      "max_price": "68",
      "modal_price": "52",
    },
    {
      "commodity": "Ginger",
      "market": "Hassan",
      "district": "Hassan",
      "arrival_date": "Today",
      "min_price": "80",
      "max_price": "140",
      "modal_price": "110",
    },
    {
      "commodity": "Carrot",
      "market": "Kolar",
      "district": "Kolar",
      "arrival_date": "Today",
      "min_price": "30",
      "max_price": "55",
      "modal_price": "45",
    },
    {
      "commodity": "Beans",
      "market": "Chikkaballapur",
      "district": "Chikkaballapur",
      "arrival_date": "Today",
      "min_price": "35",
      "max_price": "75",
      "modal_price": "55",
    },
    {
      "commodity": "Cabbage",
      "market": "Bengaluru",
      "district": "Bengaluru Rural",
      "arrival_date": "Today",
      "min_price": "20",
      "max_price": "45",
      "modal_price": "30",
    },
    {
      "commodity": "Cauliflower",
      "market": "Mysuru",
      "district": "Mysuru",
      "arrival_date": "Today",
      "min_price": "25",
      "max_price": "50",
      "modal_price": "38",
    },
    {
      "commodity": "Banana",
      "market": "Shivamogga",
      "district": "Shivamogga",
      "arrival_date": "Today",
      "min_price": "40",
      "max_price": "85",
      "modal_price": "65",
    },
    {
      "commodity": "Apple",
      "market": "Bengaluru",
      "district": "Bengaluru Urban",
      "arrival_date": "Today",
      "min_price": "90",
      "max_price": "160",
      "modal_price": "120",
    },
    {
      "commodity": "Mango",
      "market": "Kolar",
      "district": "Kolar",
      "arrival_date": "Today",
      "min_price": "50",
      "max_price": "100",
      "modal_price": "75",
    },
    {
      "commodity": "Coconut",
      "market": "Tumakuru",
      "district": "Tumakuru",
      "arrival_date": "Today",
      "min_price": "20",
      "max_price": "40",
      "modal_price": "30",
    },
    {
      "commodity": "Sugarcane",
      "market": "Mandya",
      "district": "Mandya",
      "arrival_date": "Today",
      "min_price": "25",
      "max_price": "55",
      "modal_price": "40",
    },
    {
      "commodity": "Groundnut",
      "market": "Ballari",
      "district": "Ballari",
      "arrival_date": "Today",
      "min_price": "60",
      "max_price": "110",
      "modal_price": "85",
    },
    {
      "commodity": "Cotton",
      "market": "Raichur",
      "district": "Raichur",
      "arrival_date": "Today",
      "min_price": "70",
      "max_price": "130",
      "modal_price": "100",
    },
    {
      "commodity": "Chilli",
      "market": "Byadgi",
      "district": "Haveri",
      "arrival_date": "Today",
      "min_price": "90",
      "max_price": "180",
      "modal_price": "130",
    },
  ];

  Future<void> fetchCropPrices() async {
    setState(() {
      loading = true;
      prices = [];
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/crop_prices"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "crop": commodityController.text.trim(),
          "state": stateController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      final apiRecords = data["records"] ?? [];

      setState(() {
        prices = apiRecords.isNotEmpty ? apiRecords : fallbackPrices;
        loading = false;
      });
    } catch (e) {
      setState(() {
        prices = fallbackPrices;
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCropPrices();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.lang,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: const Color(0xffEEF6E8),

          appBar: AppBar(
            title: Text(
              LanguageService.t("prices"),
            ),
            backgroundColor: Colors.green,
          ),

          body: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                // COMMODITY / CROP
                TextField(
                  controller: commodityController,
                  decoration: InputDecoration(
                    labelText: LanguageService.t("commodityCrop"),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // STATE
                TextField(
                  controller: stateController,
                  decoration: InputDecoration(
                    labelText: LanguageService.t("state"),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                // GET CURRENT PRICES
                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: fetchCropPrices,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),

                    child: Text(
                      LanguageService.t("getCurrentPrices"),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // PRICE NOTE
                Text(
                  LanguageService.t("livePricesNote"),

                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 15),

                if (loading)
                  const CircularProgressIndicator(
                    color: Colors.green,
                  ),

                Expanded(
                  child: ListView.builder(
                    itemCount: prices.length,

                    itemBuilder: (context, index) {
                      final item = prices[index];

                      return Card(
                        elevation: 4,

                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.all(15),

                          leading: CircleAvatar(
                            radius: 28,

                            backgroundColor:
                                Colors.green.shade100,

                            child: const Icon(
                              Icons.currency_rupee,
                              color: Colors.green,
                            ),
                          ),

                          title: Text(
                            "${item["commodity"]}",

                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          subtitle: Padding(
                            padding:
                                const EdgeInsets.only(top: 8),

                            child: Text(
                              "${LanguageService.t("market")}: ${item["market"]}\n"
                              "${LanguageService.t("district")}: ${item["district"]}\n"
                              "${LanguageService.t("date")}: ${item["arrival_date"]}\n"
                              "${LanguageService.t("minPrice")}: ₹${item["min_price"]} | "
                              "${LanguageService.t("maxPrice")}: ₹${item["max_price"]}",
                            ),
                          ),

                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.green.shade100,

                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: Text(
                              "₹${item["modal_price"]}",

                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}