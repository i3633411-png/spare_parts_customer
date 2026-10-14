import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق العميل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const CustomerHomeScreen(),
    );
  }
}

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with SingleTickerProviderStateMixin {
  final String serverUrl = 'https://spare-parts-customer.onrender.com';
  List<dynamic> orders = [];
  Timer? _timer;
  late TabController _tabController;
  bool isDecodingVin = false;
  String? decodedDetailsText;

  List<dynamic> catalogParts = [];
  bool isLoadingCatalog = false;
  String? selectedCatalogPartKey;

  final List<String> carBrands = [
    'TOYOTA',
    'KIA',
    'HYUNDAI',
    'NISSAN',
    'FORD',
    'CHEVROLET',
    'MERCEDES-BENZ',
    'BMW',
    'LEXUS',
    'HONDA',
    'MAZDA',
    'GMC',
    'أخرى'
  ];

  final Map<String, List<String>> brandModels = {
    'TOYOTA': ['كامري', 'كورولا', 'يارس', 'هايلكس', 'لاندكروزر', 'أفالون', 'فورشنر', 'راف فور'],
    'KIA': ['أوبتيما / K5', 'كادينزا / K8', 'سيراتو', 'ريو', 'سبورتاج', 'سورينتو', 'ستينجر'],
    'HYUNDAI': ['سوناتا', 'إلنترا', 'أكسنت', 'توسان', 'سانتافي', 'آزيرا', 'كريتا'],
    'NISSAN': ['باترول', 'ألتيما', 'ماكسيما', 'صني', 'إكستريل', 'نافارا'],
    'FORD': ['فورد تورس', 'فورد فكتوريا', 'إكسبلورر', 'إكسبديشن', 'F-150'],
    'CHEVROLET': ['أبلاندر / Uplander', 'تاهو', 'سوبربان', 'كابرس', 'ماليبو', 'سلفرادو'],
    'MERCEDES-BENZ': ['S-Class', 'E-Class', 'C-Class', 'G-Class', 'GLE'],
    'BMW': ['الفئة السابعة', 'الفئة الخامسة', 'الفئة الثالثة', 'X5', 'X6'],
    'LEXUS': ['LS', 'ES', 'LX570 / LX600', 'RX', 'GX'],
    'HONDA': ['أكورد', 'سيفيك', 'سي آر في', 'بايوت'],
    'MAZDA': ['مازدا 6', 'مازدا 3', 'CX-5', 'CX-9'],
    'GMC': ['يوكن', 'سييرا', 'تيرين'],
    'أخرى': ['نوع آخر']
  };

  late List<String> modelYears;

  String? selectedBrand = 'غير معروف';
  String? selectedCarModel = 'غير معروف';
  String? selectedYear = 'غير معروف';

  final TextEditingController vinController = TextEditingController();
  final TextEditingController partNameController = TextEditingController();
  final TextEditingController partNumberController = TextEditingController();

  List<String> imageList = [];
  final List<String> selectedPickup = ['حضوري', 'توصيل'];
  final List<String> selectedPayment = ['كاش', 'دفع إلكتروني', 'تابي', 'تمارا'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    modelYears = List.generate(2026 - 1990 + 1, (index) => (2026 - index).toString());
    
    fetchOrders();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchOrders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    vinController.dispose();
    partNameController.dispose();
    partNumberController.dispose();
    super.dispose();
  }

  List<String> getAvailableModels() {
    if (selectedBrand != null && brandModels.containsKey(selectedBrand)) {
      return brandModels[selectedBrand]!;
    }
    return ['نوع آخر'];
  }

  void openPartSouqSearch() {
    String vin = vinController.text.trim();
    
    if (vin.contains('import') || vin.contains('package') || vin.length > 20) {
      vin = ''; 
    }

    String targetUrl = vin.isNotEmpty 
        ? 'https://partsouq.com/ar/search/all?q=$vin' 
        : 'https://partsouq.com/ar/';

    String translatedUrl = 'https://translate.google.com/translate?sl=en&tl=ar&u=${Uri.encodeComponent(targetUrl)}';

    html.window.open(translatedUrl, '_blank');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم فتح الكتالوج! اختر القطعة المطلوبة 🌐'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? detectBrandFromVinPrefix(String vin) {
    String cleanVin = vin.toUpperCase().trim();
    if (cleanVin.startsWith('1G') || cleanVin.startsWith('2G') || cleanVin.startsWith('3G')) {
      return 'CHEVROLET';
    } else if (cleanVin.startsWith('JT') || cleanVin.startsWith('4T') || cleanVin.startsWith('5T')) {
      return 'TOYOTA';
    } else if (cleanVin.startsWith('KM') || cleanVin.startsWith('5N')) {
      return 'HYUNDAI';
    } else if (cleanVin.startsWith('KN') || cleanVin.startsWith('3K')) {
      return 'KIA';
    } else if (cleanVin.startsWith('JN') || cleanVin.startsWith('1N')) {
      return 'NISSAN';
    } else if (cleanVin.startsWith('1F') || cleanVin.startsWith('2F')) {
      return 'FORD';
    } else if (cleanVin.startsWith('WDD') || cleanVin.startsWith('WDB')) {
      return 'MERCEDES-BENZ';
    } else if (cleanVin.startsWith('WBA') || cleanVin.startsWith('WBY')) {
      return 'BMW';
    } else if (cleanVin.startsWith('JTH') || cleanVin.startsWith('JTJ')) {
      return 'LEXUS';
    }
    return null;
  }

  String? decodeYearFromVin10thChar(String vin) {
    String cleanVin = vin.toUpperCase().trim();
    if (cleanVin.length >= 10) {
      String tenth = cleanVin[9];
      Map<String, String> vinYearMap = {
        '1': '2001', '2': '2002', '3': '2003', '4': '2004', '5': '2005',
        '6': '2006', '7': '2007', '8': '2008', '9': '2009', 'A': '2010',
        'B': '2011', 'C': '2012', 'D': '2013', 'E': '2014', 'F': '2015',
        'G': '2016', 'H': '2017', 'J': '2018', 'K': '2019', 'L': '2020',
        'M': '2021', 'N': '2022', 'P': '2023', 'R': '2024', 'S': '2025', 'T': '2026'
      };
      return vinYearMap[tenth];
    }
    return null;
  }

  Future<void> fetchCatalogParts(String brand, String model) async {
    setState(() { 
      isLoadingCatalog = true; 
      selectedCatalogPartKey = null;
    });
    try {
      String queryPart = partNumberController.text.trim().isNotEmpty 
          ? partNumberController.text.trim() 
          : '$brand $model';

      final response = await http.get(
        Uri.parse('$serverUrl/api/proxy-partsouq?partNumber=${Uri.encodeComponent(queryPart)}'),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        setState(() {
          catalogParts = resData['data'] ?? [];
        });
      }
    } catch (e) {
      // Handle error gracefully
    } finally {
      setState(() { isLoadingCatalog = false; });
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/api/orders'));
      if (response.statusCode == 200) {
        final List<dynamic> fetchedOrders = jsonDecode(response.body);
        if (mounted) {
          bool hasNewOffers = fetchedOrders.any((o) => o['status'] == 'تم إرسال العرض');
          setState(() {
            orders = fetchedOrders;
          });
          if (hasNewOffers && _tabController.index == 0) {
            _tabController.animateTo(1);
          }
        }
      }
    } catch (e) {}
  }

  Future<void> decodeVin() async {
    final vin = vinController.text.trim();
    if (vin.isEmpty || vin.contains('import')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الهيكل أولاً')),
      );
      return;
    }

    setState(() {
      isDecodingVin = true;
      decodedDetailsText = null;
    });

    String? localDetectedBrand = detectBrandFromVinPrefix(vin);
    String? localDetectedYear = decodeYearFromVin10thChar(vin);

    try {
      final response = await http.get(Uri.parse('$serverUrl/api/decode-vin/$vin'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final data = result['data'];
          String? fetchedMake = data['make']?.toString().toUpperCase();
          String? fetchedModel = data['model']?.toString();
          String? fetchedYear = data['year']?.toString().trim();

          setState(() {
            if (fetchedMake != null) {
              var matchedBrand = carBrands.firstWhere(
                (b) => b.toUpperCase() == fetchedMake || fetchedMake.contains(b.toUpperCase()),
                orElse: () => localDetectedBrand ?? 'غير معروف',
              );
              selectedBrand = matchedBrand;
            } else {
              selectedBrand = localDetectedBrand ?? 'غير معروف';
            }

            if (selectedBrand != 'غير معروف' && brandModels.containsKey(selectedBrand)) {
              List<String> availableModels = getAvailableModels();
              if (fetchedModel != null) {
                var matchedModel = availableModels.firstWhere(
                  (m) => m.toLowerCase().contains(fetchedModel.toLowerCase()) || fetchedModel.toLowerCase().contains(m.toLowerCase()),
                  orElse: () => availableModels.first,
                );
                selectedCarModel = matchedModel;
              } else {
                selectedCarModel = availableModels.first;
              }
            } else {
              selectedCarModel = 'غير معروف';
            }

            String? finalYear = (fetchedYear != null && modelYears.contains(fetchedYear))
                ? fetchedYear
                : localDetectedYear;

            selectedYear = (finalYear != null && modelYears.contains(finalYear)) ? finalYear : 'غير معروف';

            decodedDetailsText = 'تم الجلب: $selectedBrand $selectedCarModel $selectedYear';
          });

          if (selectedBrand != 'غير معروف' && selectedCarModel != 'غير معروف') {
            fetchCatalogParts(selectedBrand!, selectedCarModel!);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استخراج بيانات المركبة بنجاح!'), backgroundColor: Colors.green),
          );
          return;
        }
      }
      
      setState(() {
        selectedBrand = localDetectedBrand ?? 'غير معروف';
        selectedCarModel = 'غير معروف';
        selectedYear = localDetectedYear ?? 'غير معروف';
        decodedDetailsText = 'تعذر جلب تفاصيل دقيقة، يرجى الاستعانة بالكتالوج المباشر.';
      });
      openPartSouqSearch();
    } catch (e) {
      setState(() {
        selectedBrand = localDetectedBrand ?? 'غير معروف';
        selectedCarModel = 'غير معروف';
        selectedYear = localDetectedYear ?? 'غير معروف';
      });
      openPartSouqSearch();
    } finally {
      setState(() {
        isDecodingVin = false;
      });
    }
  }

  Future<void> sendOrder() async {
    if (partNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد أو كتابة اسم القطعة')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'carBrand': selectedBrand,
          'carName': selectedCarModel ?? '',
          'carModel': selectedYear,
          'vin': vinController.text,
          'partName': partNameController.text,
          'partNumber': partNumberController.text,
          'images': imageList,
          'imageUrl': imageList.isNotEmpty ? imageList.first : '',
          'pickupMethods': selectedPickup,
          'paymentMethods': selectedPayment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        partNameController.clear();
        partNumberController.clear();
        setState(() { 
          imageList.clear(); 
          selectedCatalogPartKey = null;
        });
        await fetchOrders();
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentModels = (selectedBrand != null && brandModels.containsKey(selectedBrand)) 
        ? brandModels[selectedBrand]! 
        : ['غير معروف'];

    if (selectedCarModel == null || !currentModels.contains(selectedCarModel)) {
      selectedCarModel = currentModels.first;
    }

    List<String> yearDropdownItems = ['غير معروف', ...modelYears];
    if (!yearDropdownItems.contains(selectedYear)) {
      selectedYear = 'غير معروف';
    }

    List<String> brandDropdownItems = ['غير معروف', ...carBrands];
    if (!brandDropdownItems.contains(selectedBrand)) {
      selectedBrand = 'غير معروف';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق العميل - قطع الغيار الذكية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFC5CAE9),
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'طلب جديد'),
            Tab(icon: Icon(Icons.receipt_long), text: 'متابعة الطلبات والعروض'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تحديد المركبة (برقم الهيكل أو يدوياً)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: vinController,
                                decoration: InputDecoration(
                                  labelText: 'رقم الهيكل (VIN - 17 خانة)',
                                  prefixIcon: const Icon(Icons.pin),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: isDecodingVin ? null : decodeVin,
                              icon: isDecodingVin ? const CircularProgressIndicator() : const Icon(Icons.search, color: Color(0xFF1A237E), size: 26),
                              tooltip: 'فك رقم الهيكل',
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: openPartSouqSearch,
                              icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
                              label: const Text('بحث بالكتالوج 🔍', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),

                        if (decodedDetailsText != null) ...[
                          const SizedBox(height: 8),
                          Text(decodedDetailsText!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedBrand,
                                decoration: InputDecoration(labelText: 'الماركة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                items: brandDropdownItems.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedBrand = val;
                                    currentModels = getAvailableModels();
                                    selectedCarModel = currentModels.first;
                                  });
                                  if (val != 'غير معروف') {
                                    fetchCatalogParts(val!, selectedCarModel!);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCarModel,
                                decoration: InputDecoration(labelText: 'الموديل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                items: currentModels.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                onChanged: (val) {
                                  setState(() => selectedCarModel = val);
                                  if (selectedBrand != 'غير معروف' && val != 'غير معروف') {
                                    fetchCatalogParts(selectedBrand!, val!);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedYear,
                                decoration: InputDecoration(labelText: 'السنة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                items: yearDropdownItems.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                onChanged: (val) => setState(() => selectedYear = val),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 30),

                        Text(
                          '2. اختيار أو كتابة القطعة الخاصة بـ ($selectedBrand $selectedCarModel)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                        ),
                        const SizedBox(height: 10),

                        isLoadingCatalog
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: selectedCatalogPartKey,
                                decoration: InputDecoration(
                                  labelText: 'اختر من القطع الشائعة',
                                  prefixIcon: const Icon(Icons.format_list_bulleted, color: Color(0xFF1A237E)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: catalogParts.map((p) {
                                  String itemName = p['name'] ?? '';
                                  String partNum = p['partNumber'] ?? '';
                                  String itemKey = "$itemName|$partNum";
                                  return DropdownMenuItem<String>(
                                    value: itemKey,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(itemName, style: const TextStyle(fontSize: 14)),
                                        Text(
                                          '[ $partNum ]',
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final parts = val.split('|');
                                    setState(() {
                                      selectedCatalogPartKey = val;
                                      partNameController.text = parts[0].trim();
                                      partNumberController.text = parts[1].trim();
                                    });
                                  }
                                },
                              ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: partNameController,
                                decoration: InputDecoration(
                                  labelText: 'اسم القطعة المطلوبة',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: partNumberController,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: 'رقم القطعة (Part #)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: sendOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('إرسال الطلب للتاجر', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              String status = order['status'] ?? 'بانتظار العروض';
              dynamic price = order['price'];
              String? partNum = order['partNumber'];
              String? qualityType = order['qualityType'];
              String? qualityGrade = order['qualityGrade'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${order['carBrand']} ${order['carName']} (${order['carModel']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
                          if (price != null) Text('$price ريال', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('القطعة المطلوبة: ${order['partName']}', style: const TextStyle(fontSize: 14)),
                      if (partNum != null && partNum.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('رقم القطعة: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              partNum,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ],
                        ),
                      ],
                      if (qualityType != null || qualityGrade != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text(
                            'جودة القطعة المقدمة: ${qualityType ?? ''} (${qualityGrade ?? ''})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('الحالة: $status', style: TextStyle(fontWeight: FontWeight.bold, color: status.contains('تم') ? Colors.green : Colors.indigo)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}