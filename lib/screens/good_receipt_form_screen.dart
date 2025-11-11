import 'package:flutter/material.dart';
import '../models/good_receipt_model.dart';
import '../services/api_service.dart';
import 'good_receipt_success_screen.dart';

class GoodReceiptFormScreen extends StatefulWidget {
  final ScannedOutgoingRequest scannedOutgoingRequest;

  const GoodReceiptFormScreen({
    super.key,
    required this.scannedOutgoingRequest,
  });

  @override
  State<GoodReceiptFormScreen> createState() => _GoodReceiptFormScreenState();
}

class _GoodReceiptFormScreenState extends State<GoodReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _receiptNumberController;
  late TextEditingController _receivedByController;
  late List<GoodReceiptItem> _items;

  bool _isLoading = false;
  DateTime _receiptDate = DateTime.now();
  String _status = 'Approved';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Generate receipt number
    final now = DateTime.now();
    final receiptNumber =
        'RCP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${widget.scannedOutgoingRequest.outgoingNumber.split('-').last}';

    _receiptNumberController = TextEditingController(text: receiptNumber);
    _receivedByController = TextEditingController();

    // Convert outgoing items to good receipt items
    _items = widget.scannedOutgoingRequest.items
        .map((item) => item.toGoodReceiptItem())
        .toList();
  }

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  Future<void> _saveGoodReceipt() async {
    if (_receivedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nama penerima harus diisi!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare good receipt data
      final receiptData = {
        'receiptNumber': _receiptNumberController.text,
        'outgoingNumber': widget.scannedOutgoingRequest.outgoingNumber,
        'poNumber': widget.scannedOutgoingRequest.poNumber,
        'supplierName': widget.scannedOutgoingRequest.supplierName,
        'supplierCode': widget.scannedOutgoingRequest.supplierCode,
        'userName': 'DCCI Admin Mobile',
        'phone': '',
        'fax': '',
        'address': '',
        'receiptDate': _receiptDate.toIso8601String(),
        'receivedBy': _receivedByController.text,
        'status': _status,
        'sapStatus': 'Not Posted',
        'items': _items.map((item) => item.toJson()).toList(),
        'createdDate': DateTime.now().toIso8601String(),
        'updatedDate': DateTime.now().toIso8601String(),
      };

      // Create Good Receipt
      final result = await _apiService.createGoodReceipt(receiptData);

      if (result.type == 'success' && result.data != null) {
        // Archive the outgoing request
        await _apiService.archiveOutgoingRequest(
          widget.scannedOutgoingRequest.outgoingNumber,
        );

        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  GoodReceiptSuccessScreen(goodReceipt: result.data!),
            ),
          );
        }
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Good Receipt Form',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with Outgoing Request Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.green[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Data Surat Jalan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    'Delivery Date:',
                    widget.scannedOutgoingRequest.deliveryDate.toString(),
                  ),
                  _buildInfoRow(
                    'Outgoing No:',
                    widget.scannedOutgoingRequest.outgoingNumber,
                  ),
                  _buildInfoRow(
                    'PO Number:',
                    widget.scannedOutgoingRequest.poNumber,
                  ),
                  _buildInfoRow(
                    'Supplier Code:',
                    widget.scannedOutgoingRequest.supplierCode,
                  ),
                  _buildInfoRow(
                    'Supplier:',
                    widget.scannedOutgoingRequest.supplierName.toUpperCase(),
                  ),
                  _buildInfoRow(
                    'Customer:',
                    widget.scannedOutgoingRequest.customerName.toUpperCase(),
                  ),
                  _buildInfoRow(
                    'Driver:',
                    widget.scannedOutgoingRequest.driverName.toUpperCase(),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Good Receipt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              readOnly: true,
                              controller: _receiptNumberController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.receipt_long),
                                labelText: 'Receipt Number',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4.0),
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Receipt Number tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _receivedByController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                labelText: 'Diterima Oleh *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama penerima tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Receipt Date
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _receiptDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (date != null) {
                                  setState(() {
                                    _receiptDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Tanggal Receipt',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_receiptDate.day.toString().padLeft(2, '0')}/${_receiptDate.month.toString().padLeft(2, '0')}/${_receiptDate.year}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Items List
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items/Barang (${_items.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                
                              ),
                            ),
                            const SizedBox(height: 16),

                            ..._items.asMap().entries.map((entry) {
                              final item = entry.value;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.materialName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Code: ${item.materialCode}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Quantity Information - Read only display
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Qty PO',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${item.quantityPO} ${item.unit}',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 40,
                                                  color: Colors.grey[300],
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Qty Received',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            Icons.check_circle,
                                                            size: 14,
                                                            color: Colors
                                                                .green[600],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '${item.quantityReceived} ${item.unit}',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Quantity Sisa (Remaining)
                                            if (item.quantityPO -
                                                    item.quantityDelivery !=
                                                0) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (item.quantityPO -
                                                              item.quantityDelivery) >
                                                          0
                                                      ? Colors.orange[50]
                                                      : Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color:
                                                        (item.quantityPO -
                                                                item.quantityDelivery) >
                                                            0
                                                        ? Colors.orange[200]!
                                                        : Colors.red[200]!,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      (item.quantityPO -
                                                                  item.quantityDelivery) >
                                                              0
                                                          ? Icons.info_outline
                                                          : Icons
                                                                .warning_amber_rounded,
                                                      size: 16,
                                                      color:
                                                          (item.quantityPO -
                                                                  item.quantityDelivery) >
                                                              0
                                                          ? Colors.orange[700]
                                                          : Colors.red[700],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        (item.quantityPO -
                                                                    item.quantityDelivery) >
                                                                0
                                                            ? 'Sisa: ${item.quantityPO - item.quantityDelivery} ${item.unit} belum diterima'
                                                            : 'Kelebihan: ${(item.quantityDelivery - item.quantityPO).abs()} ${item.unit}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              (item.quantityPO -
                                                                      item.quantityDelivery) >
                                                                  0
                                                              ? Colors
                                                                    .orange[800]
                                                              : Colors.red[800],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
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
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoodReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Menyimpan...'),
                        ],
                      )
                    : const Text(
                        'SIMPAN GOOD RECEIPT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
