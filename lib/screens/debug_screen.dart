import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ApiService _apiService = ApiService();
  String _currentBaseUrl = '';
  String _testResult = '';
  bool _isLoading = false;
  final TextEditingController _qrCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBaseUrl = _apiService.baseUrl;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing connection...';
    });

    try {
      // First test health check endpoint
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      String workingUrl = '';
      List<String> testResults = [];
      
      // Test possible endpoints
      final endpoints = [
        'http://10.0.2.2:8000/api',
        'http://localhost:8000/api',
        'http://127.0.0.1:8000/api',
        'http://10.23.184.86:8000/api',
        'http://192.168.1.100:8000/api',
      ];
      
      for (String endpoint in endpoints) {
        try {
          testResults.add('Testing: $endpoint');
          final response = await dio.get('$endpoint/health-check');
          if (response.statusCode == 200) {
            workingUrl = endpoint;
            testResults.add('✅ SUCCESS: $endpoint');
            testResults.add('Response: ${response.data}');
            break;
          }
        } catch (e) {
          testResults.add('❌ FAILED: $endpoint - $e');
        }
      }
      
      if (workingUrl.isNotEmpty) {
        testResults.add('\n🎯 Working endpoint found: $workingUrl');
      } else {
        testResults.add('\n⚠️ No working endpoints found');
      }
      
      // Test current API service
      testResults.add('\n--- Testing Current API Service ---');
      final result = await _apiService.checkToken();
      testResults.add('Current Base URL: ${_apiService.baseUrl}');
      testResults.add('Check Token Result: ${result.type}');
      testResults.add('Message: ${result.message}');
      
      setState(() {
        _testResult = testResults.join('\n');
      });
      
    } catch (e) {
      setState(() {
        _testResult = 'Connection test failed:\n'
            'Error: $e\n'
            'Status: ❌ Failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testQRScan() async {
    if (_qrCodeController.text.trim().isEmpty) {
      setState(() {
        _testResult = 'Please enter a QR code to test';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Testing QR scan...';
    });

    try {
      final result = await _apiService.scanOutgoingQR(_qrCodeController.text.trim());
      setState(() {
        _testResult = 'QR Scan test result:\n'
            'Type: ${result.type}\n'
            'Message: ${result.message}\n'
            'Data: ${result.data?.toString() ?? 'null'}\n'
            'Status: ${result.type == 'success' ? '✅ Success' : '❌ Failed'}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'QR Scan test failed:\n'
            'Error: $e\n'
            'Status: ❌ Failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Debug & Connection Test',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: $_currentBaseUrl'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Connection Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testConnection,
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing...'),
                                ],
                              )
                            : const Text('Test Connection'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // QR Code Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qrCodeController,
                      decoration: const InputDecoration(
                        labelText: 'QR Code / Outgoing Number',
                        hintText: 'Enter QR code to test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testQRScan,
                        child: const Text('Test QR Scan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResult.isEmpty 
                                  ? 'No test results yet. Run a test to see results here.'
                                  : _testResult,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: _testResult.contains('✅') 
                                    ? Colors.green[700]
                                    : _testResult.contains('❌') 
                                        ? Colors.red[700]
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}