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
    final receiptNumber = 'RCP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${widget.scannedOutgoingRequest.outgoingNumber.split('-').last}';
    
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
        await _apiService.archiveOutgoingRequest(widget.scannedOutgoingRequest.outgoingNumber);
        
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GoodReceiptSuccessScreen(
              goodReceipt: result.data!,
            ),
          ),
        );
      } else {
        _showErrorDialog(result.message ?? 'Gagal menyimpan Good Receipt');
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

  void _updateItemQuantity(int index, int newQuantity) {
    setState(() {
      _items[index] = GoodReceiptItem(
        id: _items[index].id,
        materialCode: _items[index].materialCode,
        materialName: _items[index].materialName,
        quantityPO: _items[index].quantityPO,
        quantityDelivery: _items[index].quantityDelivery,
        quantityReceived: newQuantity,
        unit: _items[index].unit,
        notes: _items[index].notes,
        lotNumber: _items[index].lotNumber,
        expiryDate: _items[index].expiryDate,
      );
    });
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
                  const SizedBox(height: 12),
                  _buildInfoRow('Outgoing No:', widget.scannedOutgoingRequest.outgoingNumber),
                  _buildInfoRow('PO Number:', widget.scannedOutgoingRequest.poNumber),
                  _buildInfoRow('Supplier:', widget.scannedOutgoingRequest.supplierName),
                  _buildInfoRow('Customer:', widget.scannedOutgoingRequest.customerName),
                  _buildInfoRow('Driver:', widget.scannedOutgoingRequest.driverName),
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
                              controller: _receiptNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Receipt Number *',
                                border: OutlineInputBorder(),
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
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 1)),
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
                                  suffixIcon: Icon(Icons.calendar_today),
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
                              final index = entry.key;
                              final item = entry.value;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.materialName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
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
                                      const SizedBox(height: 8),
                                      
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Qty PO: ${item.quantityPO} ${item.unit}'),
                                                Text('Qty Delivery: ${item.quantityDelivery} ${item.unit}'),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item.quantityReceived.toString(),
                                              decoration: InputDecoration(
                                                labelText: 'Qty Received *',
                                                suffixText: item.unit,
                                                border: const OutlineInputBorder(),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                              keyboardType: TextInputType.number,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Wajib diisi';
                                                }
                                                final qty = int.tryParse(value);
                                                if (qty == null || qty < 0) {
                                                  return 'Quantity tidak valid';
                                                }
                                                return null;
                                              },
                                              onChanged: (value) {
                                                final qty = int.tryParse(value) ?? 0;
                                                _updateItemQuantity(index, qty);
                                              },
                                            ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}