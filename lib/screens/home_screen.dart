import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';

class QuoteTemplate {
  final String name;
  final String? assetPath;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final TextStyle fontStyle;
  final Color defaultTextColor;

  QuoteTemplate({
    required this.name,
    this.assetPath,
    this.backgroundColor,
    this.gradientColors,
    required this.fontStyle,
    required this.defaultTextColor,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  File? selectedImage;
  String extractedText = "";
  double fontSize = 24;
  Color textColor = Colors.white;
  GlobalKey globalKey = GlobalKey();
  bool isProcessing = false;
  QuoteTemplate? selectedTemplate;
  
  // Font selection state
  String selectedFontName = "Poppins";
  final List<String> availableFonts = [
    "Poppins",
    "Roboto",
    "Playfair Display",
    "Montserrat",
    "Lora",
    "Oswald",
    "Dancing Script",
    "Pacifico",
    "Caveat",
    "Abril Fatface",
    "Raleway",
    "Merriweather",
  ];

  final List<QuoteTemplate> templates = [
    QuoteTemplate(
      name: "Original",
      fontStyle: GoogleFonts.poppins(),
      defaultTextColor: Colors.white,
    ),
    QuoteTemplate(
      name: "Dark Abstract",
      assetPath: "assets/templates/dark.png",
      fontStyle: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
      defaultTextColor: Colors.white,
    ),
    QuoteTemplate(
      name: "Sunset",
      assetPath: "assets/templates/sunset.png",
      fontStyle: GoogleFonts.dancingScript(fontWeight: FontWeight.bold),
      defaultTextColor: Colors.white,
    ),
    QuoteTemplate(
      name: "Nature",
      assetPath: "assets/templates/nature.png",
      fontStyle: GoogleFonts.montserrat(),
      defaultTextColor: Colors.green[900]!,
    ),
    QuoteTemplate(
      name: "Marble",
      assetPath: "assets/templates/marble.png",
      fontStyle: GoogleFonts.oswald(fontWeight: FontWeight.w300),
      defaultTextColor: Colors.black87,
    ),
    QuoteTemplate(
      name: "Midnight",
      gradientColors: [Colors.black, Colors.blueGrey[900]!],
      fontStyle: GoogleFonts.robotoMono(),
      defaultTextColor: Colors.cyanAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedTemplate = templates[0];
  }

  TextStyle getSelectedTextStyle() {
    return GoogleFonts.getFont(selectedFontName).copyWith(
      color: textColor,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
        extractedText = "";
      });
      await extractText();
    }
  }

  Future<void> extractText() async {
    if (selectedImage == null) return;

    setState(() {
      isProcessing = true;
    });

    final inputImage = InputImage.fromFile(selectedImage!);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      setState(() {
        extractedText = recognizedText.text;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error extracting text: $e")),
        );
      }
    } finally {
      textRecognizer.close();
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> saveImage() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(pngBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image saved to gallery!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving image: $e")),
        );
      }
    }
  }

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick text color'),
        content: BlockPicker(
          pickerColor: textColor,
          onColorChanged: (color) {
            setState(() => textColor = color);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void openFontPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Choose Font", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: availableFonts.length,
                  itemBuilder: (context, index) {
                    final font = availableFonts[index];
                    return ListTile(
                      title: Text(font, style: GoogleFonts.getFont(font, color: Colors.white)),
                      trailing: selectedFontName == font ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                      onTap: () {
                        setState(() {
                          selectedFontName = font;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildPreview() {
    if (selectedImage == null) return const SizedBox.shrink();

    return RepaintBoundary(
      key: globalKey,
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selectedTemplate?.name == "Original")
                Image.file(selectedImage!, width: double.infinity, height: 400, fit: BoxFit.cover)
              else if (selectedTemplate?.assetPath != null)
                Image.asset(selectedTemplate!.assetPath!, width: double.infinity, height: 400, fit: BoxFit.cover)
              else if (selectedTemplate?.gradientColors != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedTemplate!.gradientColors!,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
              else
                Container(color: selectedTemplate?.backgroundColor ?? Colors.grey[800]),

              if (selectedTemplate?.name == "Original")
                Container(color: Colors.black.withOpacity(0.35)),

              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  extractedText.isEmpty
                      ? (isProcessing ? "Extracting..." : "No text found")
                      : extractedText,
                  textAlign: TextAlign.center,
                  style: getSelectedTextStyle().copyWith(
                    shadows: selectedTemplate?.name == "Marble" || selectedTemplate?.name == "Nature"
                        ? null
                        : [
                            const Shadow(
                              blurRadius: 8.0,
                              color: Colors.black54,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("Quote Designer", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (selectedImage != null)
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 28),
              onPressed: saveImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (selectedImage != null) ...[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: buildPreview(),
              ),
              
              _buildSectionTitle("Choose Template"),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isSelected = selectedTemplate == template;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTemplate = template;
                          textColor = template.defaultTextColor;
                        });
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10, width: 2),
                          image: template.assetPath != null ? DecorationImage(image: AssetImage(template.assetPath!), fit: BoxFit.cover) : null,
                          gradient: template.gradientColors != null ? LinearGradient(colors: template.gradientColors!) : null,
                          color: template.backgroundColor ?? Colors.grey[800],
                        ),
                        child: Center(
                          child: Text(template.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
              ),

              _buildSectionTitle("Customize Text"),
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_size, color: Colors.white70),
                        Expanded(
                          child: Slider(
                            min: 12,
                            max: 80,
                            value: fontSize,
                            activeColor: Colors.blueAccent,
                            onChanged: (value) => setState(() => fontSize = value),
                          ),
                        ),
                        Text("${fontSize.toInt()}", style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          onPressed: openFontPicker,
                          icon: Icons.font_download_rounded,
                          label: selectedFontName,
                        ),
                        _buildActionButton(
                          onPressed: openColorPicker,
                          icon: Icons.palette_rounded,
                          label: "Color",
                          iconColor: textColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: TextEditingController(text: extractedText)..selection = TextSelection.collapsed(offset: extractedText.length),
                      onChanged: (value) => extractedText = value,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Edit quote...",
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text("Change Source Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 40),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, Color? iconColor}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? Colors.blueAccent),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 24),
          Text("Quote Designer", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text("Turn any image into a beautiful quote.", style: TextStyle(color: Colors.white38, fontSize: 16)),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: pickImage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Select Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
