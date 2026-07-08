import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:duitly/core/services/custom_ai_service.dart';

class SttService {
  static String get _whisperUrl {
    final envUrl = dotenv.env['WHISPER_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback if not configured in .env
    return 'https://api.groq.com/openai/v1/audio/transcriptions';
  }

  /// 1. Transcribe Audio to Text using Whisper API
  static Future<String> transcribeAudio(File audioFile) async {
    final apiKey = CustomAIService.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('API Key tidak ditemukan');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = 'groq/whisper-large-v3';
    
    // Attach audio file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      ),
    );

    final responseStream = await request.send();
    final response = await http.Response.fromStream(responseStream);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['text'] ?? '';
    } else {
      throw Exception('Gagal transkripsi audio: ${response.statusCode} - ${response.body}');
    }
  }

  /// 2. Parse transcribed text into transaction JSON using AI
  static Future<List<Map<String, dynamic>>> parseTransactionFromText(String text) async {
    const systemPrompt = '''
Anda adalah lexical parser teks. Tugas Anda adalah menerjemahkan kalimat deskriptif penambahan atau pengurangan nilai objek menjadi JSON array terstruktur.
Setiap objek dalam array harus memiliki properti berikut:
- "judul": (String) Nama objek atau aktivitas
- "nominal": (Number) Nilai numerik kuantitatif (hanya angka saja)
- "jenis": (String) Arah aliran ("IN" jika bertambah/masuk seperti mendapat/gaji, "OUT" jika berkurang/keluar seperti membeli/membayar)
- "kategori": (String) Pengelompokan objek (contoh: "Makanan/Minuman", "Transportasi", "Pemasukan", "Lainnya")

Contoh Kalimat: "beli bensin 20000 terus dapet gaji 50000"
Contoh Output JSON:
[
  {
    "judul": "Beli Bensin",
    "nominal": 20000,
    "jenis": "OUT",
    "kategori": "Transportasi"
  },
  {
    "judul": "Gaji",
    "nominal": 50000,
    "jenis": "IN",
    "kategori": "Pemasukan"
  }
]
Keluarkan HANYA JSON array murni tanpa ada penjelasan teks apa pun sebelum atau sesudahnya!
''';

    final resultStr = await CustomAIService.getChatCompletion(
      [{
        'role': 'user', 
        'content': '$systemPrompt\n\nEkstrak kalimat berikut ini menjadi JSON:\n"$text"'
      }],
      temperature: 0.1,
    );

    final cleanedResponse = _cleanAndExtractJsonArray(resultStr);

    try {
      final jsonArray = jsonDecode(cleanedResponse);
      if (jsonArray is List) {
        return List<Map<String, dynamic>>.from(jsonArray);
      } else {
        throw Exception("Hasil analisis AI bukan berupa List.");
      }
    } catch (e) {
      throw Exception("Gagal mem-parsing hasil AI: $e\nResponse Asli: $resultStr\nResponse Bersih: $cleanedResponse");
    }
  }

  static String _cleanAndExtractJsonArray(String text) {
    var cleaned = text.trim();
    
    // 1. Ekstrak dari blok markdown ```json ... ``` atau ``` ... ```
    if (cleaned.contains('```json')) {
      final startIndex = cleaned.indexOf('```json') + 7;
      final endIndex = cleaned.indexOf('```', startIndex);
      if (endIndex != -1) {
        cleaned = cleaned.substring(startIndex, endIndex).trim();
      }
    } else if (cleaned.contains('```')) {
      final startIndex = cleaned.indexOf('```') + 3;
      final endIndex = cleaned.indexOf('```', startIndex);
      if (endIndex != -1) {
        cleaned = cleaned.substring(startIndex, endIndex).trim();
      }
    }

    // 2. Cari kurung siku pertama '[' dan kurung siku terakhir ']'
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start != -1 && end != -1 && start < end) {
      cleaned = cleaned.substring(start, end + 1);
    }

    return cleaned;
  }
}
