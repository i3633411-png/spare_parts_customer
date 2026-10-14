import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class VinScanPage extends StatefulWidget {
  const VinScanPage({super.key});

  @override
  State<VinScanPage> createState() => _VinScanPageState();
}

class _VinScanPageState extends State<VinScanPage> {
  final TextEditingController _vinController = TextEditingController();
  bool _isScanning = false;

  // دالة التقاط الصورة ومعالجتها عبر ML Kit OCR
  Future<void> _scanVinUsingOCR() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        setState(() {
          _isScanning = false;
        });
        return;
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      String? foundVin;
      final RegExp vinRegex = RegExp(r'[A-HJ-NPR-Z0-9]{17}R');

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String cleanText = line.text.replaceAll(' ', '').toUpperCase();
          final match = vinRegex.firstMatch(cleanText);
          if (match != null) {
            foundVin = match.group(0);
            break;
          }
        }
        if (foundVin != null) break;
      }

      // إذا لم يطابق النمط بدقة 100%، نأخذ أول نص طويل أو نتركه للمستخدم، أو نبحث عن 17 حرف
      if (foundVin == null) {
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            String cleanText = line.text.replaceAll(' ', '').toUpperCase();
            if (cleanText.length >= 15) {
              foundVin = cleanText;
              break;
            }
          }
          if (foundVin != null) break;
        }
      }

      if (foundVin != null) {
        setState(() {
          _vinController.text = foundVin!.length > 17 ? foundVin!.substring(0, 17) : foundVin!;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم استخراج النص بنجاح!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم التعرف على رقم الـ VIN بوضوح، يرجى إدخاله يدوياً.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بحث قطع الغيار برقم الهيكل (VIN)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل رقم الهيكل (VIN) المكون من 17 خانة أو قم بمسحه بالكاميرا:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vinController,
                    maxLength: 17,
                    decoration: InputDecoration(
                      labelText: 'رقم الهيكل VIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanVinUsingOCR,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: const Text('مسح الكاميرا'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                String vin = _vinController.text.trim();
                
                if (vin.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء كتابة أو مسح رقم الهيكل أولاً.')),
                  );
                  return;
                }

                // عرض نافذة نتيجة البحث الفعلي
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('نتيجة البحث برقم الهيكل'),
                    content: Text('تم استلام رقم الهيكل بنجاح:\n$vin\n\nسيتم جلب قطع الغيار المطابقة لهذه المركبة.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('بحث عن القطع', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}