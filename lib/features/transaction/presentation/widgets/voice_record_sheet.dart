import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:duitly/core/services/stt_service.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';
import 'package:duitly/core/providers/database_provider.dart';

class VoiceRecordSheet extends ConsumerStatefulWidget {
  final int userId;
  final int walletId;
  final VoidCallback onSuccess;

  const VoiceRecordSheet({
    super.key,
    required this.userId,
    required this.walletId,
    required this.onSuccess,
  });

  @override
  ConsumerState<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends ConsumerState<VoiceRecordSheet> with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusText = 'Tekan untuk merekam';
  String? _recordedFilePath;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordedFilePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
          ),
          path: _recordedFilePath!,
        );

        setState(() {
          _isRecording = true;
          _statusText = 'Merekam...';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merekam: $e')),
        );
      }
    }
  }

  Future<void> _stopRecordingAndProcess() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _isProcessing = true;
          _statusText = 'Memproses audio...';
        });

        // 1. Transcribe audio
        final file = File(path);
        final transcribedText = await SttService.transcribeAudio(file);

        if (transcribedText.isEmpty) {
          throw Exception('Suara tidak terdengar jelas.');
        }

        setState(() {
          _statusText = 'Menganalisis transaksi...';
        });

        // 2. Parse text with AI
        final transactions = await SttService.parseTransactionFromText(transcribedText);

        if (mounted) {
          _showConfirmationDialog(transactions);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessing = false;
          _statusText = 'Gagal memproses';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showConfirmationDialog(List<Map<String, dynamic>> parsedTransactions) {
    if (parsedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi yang terdeteksi.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Transaksi'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: parsedTransactions.length,
              itemBuilder: (context, index) {
                final tx = parsedTransactions[index];
                return ListTile(
                  title: Text(tx['judul'] ?? 'Tanpa Judul'),
                  subtitle: Text(tx['kategori'] ?? 'Lainnya'),
                  trailing: Text(
                    'Rp ${(tx['nominal'] as num).toInt()}',
                    style: TextStyle(
                      color: tx['jenis'] == 'IN' ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup dialog
                setState(() {
                  _isRecording = false;
                  _isProcessing = false;
                  _statusText = 'Ketuk untuk mulai bicara';
                });
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup dialog dulu
                await _saveTransactions(parsedTransactions); // Proses simpan database
                if (mounted) {
                  Navigator.pop(context); // Tutup VoiceRecordSheet (BottomSheet)
                }
              },
              child: const Text('Simpan Semua'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTransactions(List<Map<String, dynamic>> parsedTransactions) async {
    final dbHelper = ref.read(databaseProvider);
    final categories = await dbHelper.readAllKategori();

    for (final parsed in parsedTransactions) {
      final categoryName = parsed['kategori'] as String? ?? 'Lainnya';
      final jenis = parsed['jenis'] as String? ?? 'OUT';
      
      // Find category ID
      int categoryId = 0; // Default
      final foundCategory = categories.where((c) => 
        c.namaKategori.toLowerCase().contains(categoryName.toLowerCase()) && c.jenisArusKas == jenis
      ).toList();

      if (foundCategory.isNotEmpty) {
        categoryId = foundCategory.first.idKategori!;
      } else {
        // Find generic "Lainnya" or just use first matching type
        final fallback = categories.where((c) => c.jenisArusKas == jenis).toList();
        if (fallback.isNotEmpty) {
          categoryId = fallback.first.idKategori!;
        }
      }

      final transaction = TransactionModel(
        idUser: widget.userId,
        idWallet: widget.walletId,
        idKategori: categoryId,
        judulTransaksi: parsed['judul'] ?? 'Catat Suara',
        nominal: (parsed['nominal'] as num).toDouble(),
        jenisArusKas: jenis,
        metodePembayaran: 'Cash',
        deskripsi: 'Otomatis via Suara',
        timeStamp: DateTime.now(),
      );

      await dbHelper.insertTransactionAndUpdateWallet(transaction);
    }

    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Catat dengan Suara',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sebutkan pengeluaran/pemasukan Anda',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _isProcessing
                ? null
                : () {
                    if (_isRecording) {
                      _stopRecordingAndProcess();
                    } else {
                      _startRecording();
                    }
                  },
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing
                          ? Colors.grey
                          : (_isRecording ? Colors.red : Colors.blue),
                      boxShadow: [
                        BoxShadow(
                          color: (_isProcessing
                                  ? Colors.grey
                                  : (_isRecording ? Colors.red : Colors.blue))
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _statusText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
