import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'dart:async';

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
  StreamSubscription? _complaintUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _subscribeToComplaintUpdates();
  }

  @override
  void dispose() {
    _complaintUpdateSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToComplaintUpdates() async {
    await ApiService.connectPassengerWebSocket(widget.passengerId);
    
    _complaintUpdateSubscription = ApiService.getWebSocketStream()?.listen((message) {
      debugPrint('🔔 Complaint update received via WebSocket: ${message['event']}');
      if (message['event'] == 'complaint_updated') {
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
      backgroundColor: nagcarlanWhite,
      appBar: AppBar(
        title: const Text(
          'My Complaints',
          style: TextStyle(
            color: nagcarlanGreen,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: nagcarlanWhite,
        iconTheme: const IconThemeData(color: nagcarlanGreen),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black.withOpacity(0.05)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        color: nagcarlanGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: nagcarlanGreen))
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
                            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
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
                                    size: 80, color: nagcarlanGreen.withOpacity(0.2)),
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
                                const Text(
                                  'Your report history will appear here.',
                                  style: TextStyle(color: Colors.black54),
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
                              border: Border.all(color: Colors.black.withOpacity(0.05)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
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
                                          color: Colors.black.withOpacity(0.02),
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
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
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
          Icon(icon, size: 16, color: Colors.black38),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
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
