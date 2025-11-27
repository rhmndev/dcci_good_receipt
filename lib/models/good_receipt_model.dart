class GoodReceipt {
  final String id;
  final String receiptNumber;
  final String outgoingNumber;
  final String poNumber;
  final String supplierName;
  final String supplierCode;
  final String userName;
  final String phone;
  final String fax;
  final String address;
  final DateTime receiptDate;
  final String receivedBy;
  final String status;
  final String sapStatus;
  final DateTime? sapLastAttempt;
  final String? sapErrorMessage;
  final List<GoodReceiptItem> items;
  final DateTime createdDate;
  final DateTime updatedDate;

  GoodReceipt({
    required this.id,
    required this.receiptNumber,
    required this.outgoingNumber,
    required this.poNumber,
    required this.supplierName,
    required this.supplierCode,
    required this.userName,
    required this.phone,
    required this.fax,
    required this.address,
    required this.receiptDate,
    required this.receivedBy,
    required this.status,
    required this.sapStatus,
    this.sapLastAttempt,
    this.sapErrorMessage,
    required this.items,
    required this.createdDate,
    required this.updatedDate,
  });

  factory GoodReceipt.fromJson(Map<String, dynamic> json) {
    return GoodReceipt(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
      outgoingNumber: json['outgoingNumber'] ?? '',
      poNumber: json['poNumber'] ?? '',
      supplierName: json['supplierName'] ?? '',
      supplierCode: json['supplierCode'] ?? '',
      userName: json['userName'] ?? '',
      phone: json['phone'] ?? '',
      fax: json['fax'] ?? '',
      address: json['address'] ?? '',
      receiptDate: DateTime.tryParse(json['receiptDate'] ?? '') ?? DateTime.now(),
      receivedBy: json['receivedBy'] ?? '',
      status: json['status'] ?? 'Pending',
      sapStatus: json['sapStatus'] ?? 'Not Posted',
      sapLastAttempt: json['sapLastAttempt'] != null 
          ? DateTime.tryParse(json['sapLastAttempt']) 
          : null,
      sapErrorMessage: json['sapErrorMessage'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => GoodReceiptItem.fromJson(item))
          .toList() ?? [],
      createdDate: DateTime.tryParse(json['createdDate'] ?? '') ?? DateTime.now(),
      updatedDate: DateTime.tryParse(json['updatedDate'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptNumber': receiptNumber,
      'outgoingNumber': outgoingNumber,
      'poNumber': poNumber,
      'supplierName': supplierName,
      'supplierCode': supplierCode,
      'userName': userName,
      'phone': phone,
      'fax': fax,
      'address': address,
      'receiptDate': receiptDate.toIso8601String(),
      'receivedBy': receivedBy,
      'status': status,
      'sapStatus': sapStatus,
      'sapLastAttempt': sapLastAttempt?.toIso8601String(),
      'sapErrorMessage': sapErrorMessage,
      'items': items.map((item) => item.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
    };
  }
}

class GoodReceiptItem {
  final String id;
  final String materialCode;
  final String materialName;
  final int quantityPO;
  final int quantityDelivery;
  final int quantityReceived;
  final String unit;
  final String? notes;
  final String? lotNumber;
  final DateTime? expiryDate;

  GoodReceiptItem({
    required this.id,
    required this.materialCode,
    required this.materialName,
    required this.quantityPO,
    required this.quantityDelivery,
    required this.quantityReceived,
    required this.unit,
    this.notes,
    this.lotNumber,
    this.expiryDate,
  });

  factory GoodReceiptItem.fromJson(Map<String, dynamic> json) {
    int quantityReceived = 0;
    
    if (json['quantityReceived'] != null) {
      quantityReceived = int.tryParse(json['quantityReceived']?.toString() ?? '0') ?? 0;
    } else if (json['quantity_received'] != null) {
      quantityReceived = int.tryParse(json['quantity_received']?.toString() ?? '0') ?? 0;
    } else if (json['quantityDelivery'] != null) {
      quantityReceived = int.tryParse(json['quantityDelivery']?.toString() ?? '0') ?? 0;
    } else if (json['quantity_gr'] != null) {
      quantityReceived = int.tryParse(json['quantity_gr']?.toString() ?? '0') ?? 0;
    }
    
    return GoodReceiptItem(
      id: json['id']?.toString() ?? '',
      materialCode: json['materialCode'] ?? json['material_code'] ?? '',
      materialName: json['materialName'] ?? json['material_name'] ?? json['name'] ?? '',
      quantityPO: int.tryParse(json['quantityPO']?.toString() ?? json['quantity_po']?.toString() ?? '0') ?? 0,
      quantityDelivery: int.tryParse(json['quantityDelivery']?.toString() ?? json['quantity_delivery']?.toString() ?? json['quantity_gr']?.toString() ?? '0') ?? 0,
      quantityReceived: quantityReceived,
      unit: json['unit'] ?? json['uom_needed'] ?? '',
      notes: json['notes'],
      lotNumber: json['lotNumber'] ?? json['lot_number'],
      expiryDate: json['expiryDate'] != null || json['expiry_date'] != null
          ? DateTime.tryParse(json['expiryDate'] ?? json['expiry_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // CamelCase untuk mobile
      'materialCode': materialCode,
      'materialName': materialName,
      'quantityPO': quantityPO,
      'quantityDelivery': quantityDelivery,
      'quantityReceived': quantityReceived,
      'unit': unit,
      'notes': notes,
      'lotNumber': lotNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      // Snake_case untuk web compatibility
      'material_code': materialCode,
      'material_name': materialName,
      'quantity_po': quantityPO,
      'quantity_delivery': quantityDelivery,
      'quantity_gr': quantityReceived,
      'quantity_needed': quantityPO,
      'uom_needed': unit,
      'uom_out': unit,
      'uom': unit,
      'lot_number': lotNumber,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}

// Model untuk Outgoing Request yang di-scan
class ScannedOutgoingRequest {
  final String outgoingNumber;
  final String poNumber;
  final String supplierName;
  final String supplierCode;
  final String customerName;
  final DateTime deliveryDate;
  final DateTime deliveryTime;
  final String driverName;
  final List<OutgoingItem> items;
  final String status;

  ScannedOutgoingRequest({
    required this.outgoingNumber,
    required this.poNumber,
    required this.supplierName,
    required this.supplierCode,
    required this.customerName,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.driverName,
    required this.items,
    required this.status,
  });

  static DateTime _combineDateAndTime(dynamic date, dynamic time) {
    if (date == null || date.toString().isEmpty) {
      return DateTime.now();
    }

    final parsedDate = DateTime.tryParse(date.toString());
    if (parsedDate == null) {
      return DateTime.now();
    }

    if (time == null || time.toString().isEmpty) {
      return parsedDate;
    }

    final parts = time.toString().split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }

  factory ScannedOutgoingRequest.fromJson(Map<String, dynamic> json) {
    final deliveryDateStr = json['delivery_date'] ?? json['deliveryDate'];
    final deliveryTimeStr = json['delivery_time'] ?? json['deliveryTime'];

    return ScannedOutgoingRequest(
      outgoingNumber: json['outgoing_no'] ?? json['outgoingNumber'] ?? '',
      poNumber: json['po_number'] ?? json['poNumber'] ?? '',
      supplierName: json['supplier_name'] ?? json['supplierName'] ?? '',
      supplierCode: json['supplier_code'] ?? json['supplierCode'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      deliveryDate: _combineDateAndTime(deliveryDateStr, deliveryTimeStr),
      deliveryTime: DateTime.tryParse(deliveryTimeStr ?? '') ?? DateTime.now(),
      driverName: json['driver_name'] ?? json['driverName'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OutgoingItem.fromJson(item))
          .toList() ?? [],
      status: json['status'] ?? 'Pending',
    );
  }
}

class OutgoingItem {
  final String materialCode;
  final String materialName;
  final int quantityPO;
  final int quantityDelivery;
  final String unit;
  final String? notes;

  OutgoingItem({
    required this.materialCode,
    required this.materialName,
    required this.quantityPO,
    required this.quantityDelivery,
    required this.unit,
    this.notes,
  });

  factory OutgoingItem.fromJson(Map<String, dynamic> json) {
    int qtyPO = int.tryParse(
      json['quantity_po']?.toString() ?? 
      json['quantityPO']?.toString() ?? 
      json['quantity']?.toString() ?? 
      '0'
    ) ?? 0;
    
    int qtyDelivery = int.tryParse(
      json['quantity_gr']?.toString() ?? 
      json['quantity_delivery']?.toString() ?? 
      json['quantity_conv']?.toString() ?? 
      '0'
    ) ?? 0;
    
    if (qtyDelivery == 0 && qtyPO > 0) {
      qtyDelivery = qtyPO;
    }
    
    return OutgoingItem(
      materialCode: json['material_code'] ?? json['materialCode'] ?? json['material_no'] ?? '',
      materialName: json['material_name'] ?? json['materialName'] ?? json['material_desc'] ?? json['name'] ?? '',
      quantityPO: qtyPO,
      quantityDelivery: qtyDelivery,
      unit: json['unit'] ?? json['meins'] ?? json['uom_needed'] ?? '',
      notes: json['notes'],
    );
  }

  // Convert to GoodReceiptItem
  GoodReceiptItem toGoodReceiptItem() {
    return GoodReceiptItem(
      id: DateTime.now().toString(),
      materialCode: materialCode,
      materialName: materialName,
      quantityPO: quantityPO,
      quantityDelivery: quantityDelivery,
      quantityReceived: quantityDelivery,
      unit: unit,
      notes: notes,
    );
  }
}