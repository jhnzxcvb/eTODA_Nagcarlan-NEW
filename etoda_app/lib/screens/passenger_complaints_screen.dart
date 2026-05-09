import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/services/api_service.dart'; // Assuming this path
import 'package:etoda_nagcarlan/main.dart'; // For nagcarlanGreen, nagcarlanYellow, etc.
import 'dart:async'; // Import for StreamSubscription

class PassengerComplaintsScreen extends StatefulWidget {
  final String passengerId;

  const PassengerComplaintsScreen({super.key, required this.passengerId});

  @override
  State<PassengerComplaintsScreen> createState() => _PassengerComplaintsScreenState();
}

class _PassengerComplaintsScreenState extends State<PassengerComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _complaintUpdateSubscription; // NEW

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _subscribeToComplaintUpdates(); // NEW
  }

  @override
  void dispose() {
    _complaintUpdateSubscription?.cancel(); // NEW
    super.dispose();
  }

  /// Subscribe to WebSocket updates for complaints
  void _subscribeToComplaintUpdates() async {
    // Wait for the connection to be established before getting the stream
    await ApiService.connectPassengerWebSocket(widget.passengerId);
    
    _complaintUpdateSubscription = ApiService.getWebSocketStream()?.listen((message) {
      debugPrint('🔔 Complaint update received via WebSocket: ${message['event']}');
      if (message['event'] == 'complaint_updated') {
        // Perform a "silent" refresh (without showing the main loading indicator)
        _fetchComplaints(isSilent: true);
      }
    });
  }

  Future<void> _fetchComplaints({bool isSilent = false}) async {
    if (!mounted) return;
    
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final complaints = await ApiService().fetchPassengerComplaints(widget.passengerId);
      if (!mounted) return;

      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load complaints: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Complaints',
          style: TextStyle(
            color: nagcarlanWhite,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: nagcarlanGreen,
        iconTheme: const IconThemeData(color: nagcarlanWhite),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        color: nagcarlanGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nagcarlanYellow))
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : _complaints.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 80, color: nagcarlanGreen.withValues(alpha: 0.6)),
                                const SizedBox(height: 16),
                                const Text(
                                  'No complaints filed yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your report history will appear here.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _complaints.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: _getStatusColor(complaint['status']),
                                      width: 6,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Report #${complaint['report_code']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: nagcarlanGreen,
                                          ),
                                        ),
                                        _buildStatusBadge(complaint['status']),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    _buildDetailRow(Icons.warning_amber_rounded, 'Violation',
                                        complaint['violation_type']),
                                    _buildDetailRow(
                                        Icons.description_outlined, 'Details', complaint['details']),
                                    _buildDetailRow(Icons.calendar_today_outlined, 'Reported On',
                                        complaint['reported_at']),
                                    if (complaint['admin_notes'] != null &&
                                        complaint['admin_notes'].isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Admin Response:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              complaint['admin_notes'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value ?? 'N/A'}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Open':
        return Colors.orange.shade800;
      case 'In Progress':
        return Colors.blue.shade800;
      case 'Resolved':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}