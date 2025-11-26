import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/good_receipt_model.dart';
import '../services/api_service.dart';
import 'qr_scanner_screen.dart';

class GoodReceiptSuccessScreen extends StatelessWidget {
  final GoodReceipt goodReceipt;
  final ApiService _apiService = ApiService();

  GoodReceiptSuccessScreen({
    super.key,
    required this.goodReceipt,
  });

  Future<void> _postToSAP(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Posting ke SAP...'),
            ],
          ),
        );
      },
    );

    try {
      final result = await _apiService.postGoodReceiptToSAP(goodReceipt.id);
      
      Navigator.of(context).pop();
      
      if (result.type == 'success') {
        _showSuccessDialog(context, 'Good Receipt berhasil diposting ke SAP');
      } else {
        _showErrorDialog(context, result.message ?? 'Gagal posting ke SAP');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Berhasil'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _copyReceiptNumber(BuildContext context) {
    Clipboard.setData(ClipboardData(text: goodReceipt.receiptNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt Number berhasil disalin'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Good Receipt Berhasil',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Good Receipt Berhasil Dibuat!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Outgoing Request telah diarsipkan dan Good Receipt siap untuk diproses ke SAP',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Receipt Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Informasi Good Receipt',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    _buildInfoRow('Receipt Number:', goodReceipt.receiptNumber, hasAction: true),
                    _buildInfoRow('Outgoing Number:', goodReceipt.outgoingNumber),
                    _buildInfoRow('PO Number:', goodReceipt.poNumber),
                    _buildInfoRow('Supplier:', goodReceipt.supplierName),
                    _buildInfoRow('Diterima Oleh:', goodReceipt.receivedBy),
                    _buildInfoRow(
                      'Tanggal Receipt:', 
                      '${goodReceipt.receiptDate.day.toString().padLeft(2, '0')}/${goodReceipt.receiptDate.month.toString().padLeft(2, '0')}/${goodReceipt.receiptDate.year}'
                    ),
                    _buildInfoRow('Status:', goodReceipt.status),
                    _buildInfoRow('SAP Status:', goodReceipt.sapStatus),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Items Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Items Diterima (${goodReceipt.items.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    ...goodReceipt.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.materialName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Code: ${item.materialCode}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Qty Diterima:'),
                                  Text(
                                    '${item.quantityReceived} ${item.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: goodReceipt.sapStatus == 'Not Posted' 
                        ? () => _postToSAP(context)
                        : null,
                    icon: Icon(
                      goodReceipt.sapStatus == 'Posted' 
                          ? Icons.check_circle 
                          : Icons.cloud_upload,
                    ),
                    label: Text(
                      goodReceipt.sapStatus == 'Posted' 
                          ? 'SUDAH DIPOST KE SAP'
                          : 'POST KE SAP',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goodReceipt.sapStatus == 'Posted' 
                          ? Colors.grey 
                          : Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('SCAN QR CODE LAINNYA'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('KEMBALI KE HOME'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool hasAction = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: hasAction
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyReceiptNumber(null as BuildContext),
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy Receipt Number',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: hasAction ? const TextStyle(fontWeight: FontWeight.bold) : null,
                  ),
          ),
        ],
      ),
    );
  }
}