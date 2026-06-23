import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:duitly/core/services/custom_ai_service.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/features/transaction/data/models/category_model.dart';

class ParsedReceipt {
  final String merchant;
  final double total;
  final String categorySuggested;
  final int? categoryId;
  final String itemsSummary;

  ParsedReceipt({
    required this.merchant,
    required this.total,
    required this.categorySuggested,
    this.categoryId,
    required this.itemsSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'total': total,
      'category': categorySuggested,
      'category_id': categoryId,
      'items_summary': itemsSummary,
    };
  }
}

class ReceiptParserState {
  final bool isLoading;
  final String? errorMessage;
  final File? pickedImage;
  final ParsedReceipt? parsedReceipt;

  ReceiptParserState({
    this.isLoading = false,
    this.errorMessage,
    this.pickedImage,
    this.parsedReceipt,
  });

  ReceiptParserState copyWith({
    bool? isLoading,
    String? errorMessage,
    File? pickedImage,
    ParsedReceipt? parsedReceipt,
  }) {
    return ReceiptParserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pickedImage: pickedImage ?? this.pickedImage,
      parsedReceipt: parsedReceipt ?? this.parsedReceipt,
    );
  }
}

class ReceiptParserNotifier extends Notifier<ReceiptParserState> {
  final _picker = ImagePicker();

  @override
  ReceiptParserState build() {
    return ReceiptParserState();
  }

  /// Slices the raw OCR text to only keep the first 6 lines and last 10 lines
  /// and removes repetitive symbols to optimize token usage.
  String _sliceOcrText(String rawText) {
    final lines = rawText.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
        
    if (lines.isEmpty) return '';
    
    final cleanedLines = lines.map((line) {
      // Remove lines that are just divider symbols
      final cleaned = line.replaceAll(RegExp(r'[-=*#_]{3,}'), '').trim();
      return cleaned;
    }).where((line) => line.isNotEmpty).toList();

    if (cleanedLines.length <= 16) {
      return cleanedLines.join('\n');
    }

    final firstPart = cleanedLines.take(6).toList();
    final lastPart = cleanedLines.sublist(cleanedLines.length - 10).toList();
    
    return [
      ...firstPart,
      '... [SLICED FOR EFFICIENCY] ...',
      ...lastPart
    ].join('\n');
  }

  /// Attempts to clean markdown code blocks (```json ... ```) from response.
  String _cleanJsonString(String response) {
    var clean = response.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }

  /// Fuzzy matches AI category string to SQLite category list.
  int? _findMatchingCategoryId(List<CategoryModel> categories, String aiCategory, String jenisArusKas) {
    final cleanAi = aiCategory.trim().toLowerCase();
    
    // Keyword mappings for standard Indonesian financial categories
    final Map<String, List<String>> keywordMappings = {
      'makanan': ['food', 'makanan', 'minuman', 'kuliner', 'jajanan', 'resto', 'cafe', 'makan', 'minum', 'warung', 'restaurant', 'coffee', 'bakso', 'mie'],
      'transportasi': ['transport', 'transportasi', 'bensin', 'ojek', 'gojek', 'grab', 'taxi', 'taksi', 'parkir', 'tol', 'bbm', 'kendaraan', 'service motor', 'mobil'],
      'belanja': ['shopping', 'belanja', 'supermarket', 'minimarket', 'mart', 'pakaian', 'baju', 'celana', 'sepatu', 'mall', 'kebutuhan harian', 'groceries', 'indomaret', 'alfamart', 'toko'],
      'hiburan': ['entertainment', 'hiburan', 'nonton', 'bioskop', 'game', 'wisata', 'rekreasi', 'liburan', 'konser', 'netflix', 'spotify'],
      'tagihan': ['bills', 'tagihan', 'listrik', 'air', 'internet', 'pulsa', 'wifi', 'pdam', 'pln', 'telepon', 'subscription', 'langganan'],
      'kesehatan': ['health', 'kesehatan', 'obat', 'apotek', 'dokter', 'rs', 'rumah sakit', 'klinik', 'vitamin'],
      'pendidikan': ['education', 'pendidikan', 'buku', 'sekolah', 'kuliah', 'kursus', 'spp', 'atk'],
      'gaji': ['salary', 'gaji', 'upah', 'income', 'pendapatan'],
      'investasi': ['investment', 'investasi', 'saham', 'reksadana', 'crypto', 'emas'],
    };

    String? mappedStandardCategory;
    for (final entry in keywordMappings.entries) {
      if (entry.key == cleanAi || entry.value.any((kw) => cleanAi.contains(kw) || kw.contains(cleanAi))) {
        mappedStandardCategory = entry.key;
        break;
      }
    }

    CategoryModel? bestMatch;
    int highestScore = 0;
    
    int getMatchScore(CategoryModel dbCat) {
      final dbName = dbCat.namaKategori.trim().toLowerCase();
      // Match only for the correct transaction type (OUT for expenses, since receipts are mostly OUT)
      if (dbCat.jenisArusKas != jenisArusKas) return 0;
      
      if (dbName == cleanAi) return 100;
      if (mappedStandardCategory != null && dbName == mappedStandardCategory) return 90;
      if (mappedStandardCategory != null && dbName.contains(mappedStandardCategory)) return 80;
      if (dbName.contains(cleanAi) || cleanAi.contains(dbName)) return 70;
      
      if (mappedStandardCategory != null) {
        final kws = keywordMappings[mappedStandardCategory];
        if (kws != null && kws.any((kw) => dbName.contains(kw))) {
          return 60;
        }
      }
      return 0;
    }

    for (final cat in categories) {
      final score = getMatchScore(cat);
      if (score > highestScore) {
        highestScore = score;
        bestMatch = cat;
      }
    }

    if (bestMatch != null && highestScore > 0) {
      return bestMatch.idKategori;
    }

    // Fallback to the first OUT category
    final sameTypeCats = categories.where((c) => c.jenisArusKas == jenisArusKas).toList();
    if (sameTypeCats.isNotEmpty) {
      return sameTypeCats.first.idKategori;
    }
    
    if (categories.isNotEmpty) {
      return categories.first.idKategori;
    }
    return null;
  }

  /// Triggers image picking and receipt parsing.
  /// [source] can be ImageSource.camera or ImageSource.gallery.
  Future<ParsedReceipt?> parseReceipt(ImageSource source) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final file = File(photo.path);
      state = state.copyWith(pickedImage: file);

      // 1. Process OCR locally using ML Kit
      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: Initializing ML Kit OCR...");
      }
      final inputImage = InputImage.fromFilePath(file.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;
      await textRecognizer.close();

      if (rawText.trim().isEmpty) {
        throw Exception("Gambar tidak mengandung teks yang dapat dibaca. Coba ambil gambar yang lebih jelas.");
      }

      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: OCR raw text length: ${rawText.length}");
      }

      // 2. Slice text for token efficiency
      final slicedText = _sliceOcrText(rawText);
      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: Sliced OCR text:\n$slicedText");
      }

      // 3. Send to OpenRouter AI Parser
      final systemInstruction =
          'Kamu adalah Receipt Parser AI. Tugasmu adalah menganalisis teks hasil OCR dari struk belanja dan mengekstrak informasi transaksi dalam format JSON murni.\n'
          'JSON output harus memiliki kunci berikut:\n'
          '- "merchant" (nama toko/merchant, string)\n'
          '- "total" (total nominal belanja, angka/double, tanpa koma desimal jika bulat, atau angka desimal jika ada)\n'
          '- "category" (kategori transaksi yang paling sesuai dalam bahasa Indonesia/Inggris, contoh: makanan, transportasi, belanja, dll)\n'
          '- "items_summary" (ringkasan barang-barang yang dibeli dalam 1 kalimat singkat, contoh: "Beras 5kg, Telur 10 butir dan Kopi")\n\n'
          'Format output WAJIB berupa JSON valid murni tanpa ada penjelasan lain, tanpa markdown code block (seperti ```json ... ```), langsung mulai dengan { dan diakhiri dengan }.\n'
          'Jika nominal total tidak jelas, cari angka terbesar di bagian bawah struk yang berlabel TOTAL, NETT, AMOUNT, atau BAYAR.\n'
          'Jika nominal total sama sekali tidak ditemukan atau tidak valid, isi "total" dengan 0.0.';

      final prompt = "Teks OCR Struk:\n$slicedText";

      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: Querying OpenRouter Parser...");
      }
      final responseText = await CustomAIService.getChatCompletion(
        [
          {'role': 'user', 'content': prompt}
        ],
        systemInstruction: systemInstruction,
        temperature: 0.1, // Lower temperature for structured output
      );

      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: Response from OpenRouter: $responseText");
      }

      final cleanJson = _cleanJsonString(responseText);
      final Map<String, dynamic> parsedJson = json.decode(cleanJson);

      final merchant = parsedJson['merchant']?.toString() ?? 'Toko Tidak Dikenal';
      final total = double.tryParse(parsedJson['total']?.toString() ?? '0') ?? 0.0;
      final categorySuggested = parsedJson['category']?.toString() ?? 'Belanja';
      final itemsSummary = parsedJson['items_summary']?.toString() ?? '';

      // 4. Fuzzy Match Category to SQLite DB
      final db = ref.read(databaseProvider);
      final categories = await db.readAllKategori();
      
      final categoryId = _findMatchingCategoryId(categories, categorySuggested, 'OUT');

      final parsedReceipt = ParsedReceipt(
        merchant: merchant,
        total: total,
        categorySuggested: categorySuggested,
        categoryId: categoryId,
        itemsSummary: itemsSummary,
      );

      state = state.copyWith(
        isLoading: false,
        parsedReceipt: parsedReceipt,
      );

      return parsedReceipt;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("RECEIPT_PARSER: Error parsing receipt: $e");
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Gagal memproses struk: ${e.toString()}",
      );
      return null;
    }
  }

  void clear() {
    state = ReceiptParserState();
  }
}

final receiptParserProvider = NotifierProvider<ReceiptParserNotifier, ReceiptParserState>(() {
  return ReceiptParserNotifier();
});
