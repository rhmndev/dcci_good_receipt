import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'good_receipt_form_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back, 
  );
  bool _isProcessing = false;
  String? _lastScannedCode;
  bool _isFrontCamera = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    await cameraController.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _handleQRCodeScanned(String code) async {
    if (_isProcessing || code == _lastScannedCode) return;
    
    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      print('🔍 Scanned QR Code: $code');
      
      _showLoadingDialog();

      final result = await _apiService.scanOutgoingQR(code);
      
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (result.type == 'success' && result.data != null) {
        final scannedData = result.data!;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GoodReceiptFormScreen(
              scannedOutgoingRequest: scannedData,
            ),
          ),
        );
      } else {
        if (result.message.contains('sudah pernah di-scan') || 
            result.message.contains('ALREADY_SCANNED') ||
            result.message.contains('already archived')) {
          _showAlreadyScannedDialog(result.message);
        } else {
          _showErrorDialog(result.message.isNotEmpty ? result.message : 'QR Code tidak valid atau sudah diproses');
        }
      }
    } catch (e) {
      print('Error in _handleQRCodeScanned: $e');
      
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      String errorMessage = 'Terjadi kesalahan sistem';
      
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed to connect')) {
        errorMessage = 'Tidak dapat terhubung ke server. Pastikan koneksi internet aktif dan server API berjalan.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Koneksi timeout. Coba lagi dalam beberapa saat.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'QR Code tidak ditemukan dalam sistem.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Terjadi kesalahan pada server. Silakan hubungi administrator.';
      }
      
      _showErrorDialog(errorMessage);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Memproses QR Code...'),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _lastScannedCode = null;
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAlreadyScannedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Surat Jalan Sudah Diproses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Setiap Surat Jalan hanya dapat di-scan satu kali',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _lastScannedCode = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Scan QR Code Lain',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  void _resetScanner() {
    setState(() {
      _lastScannedCode = null;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code Surat Jalan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Scanner',
          ),
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            tooltip: _isFrontCamera ? 'Kamera Belakang' : 'Kamera Depan',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                      size: 32,
                      color: Colors.blue[700],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera ke QR code pada surat jalan untuk memindai Outgoing Number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFrontCamera ? '📷 Kamera Depan' : '📷 Kamera Belakang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _handleQRCodeScanned(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.green : Colors.red,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isProcessing
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isProcessing ? Icons.check_circle : Icons.info,
                      color: _isProcessing ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isProcessing 
                          ? 'QR Code terdeteksi, sedang diproses...'
                          : 'Pastikan QR Code jelas dan ruangan cukup terang',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isProcessing ? Colors.green : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () {
                      _showManualInputDialog();
                    },
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Input Manual Outgoing Number'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input Manual'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan Outgoing Number secara manual:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Outgoing Number',
                  hintText: 'Contoh: OUT-2024102701',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (controller.text.trim().isNotEmpty) {
                  _handleQRCodeScanned(controller.text.trim());
                }
              },
              child: const Text('Proses'),
            ),
          ],
        );
      },
    );
  }
}