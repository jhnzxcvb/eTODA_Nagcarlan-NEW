import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/widgets/trip_card_widget.dart'; // Import the new shared widget
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  final String driverId;
  const DriverTripHistoryScreen({super.key, required this.driverId});

  @override
  State<DriverTripHistoryScreen> createState() => _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;
  final ApiService _apiService = ApiService();

  String _searchQuery = "";
  String _selectedFilter = "All";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  // ── Design tokens ──────────────────────────────────────────────
  static const Color _headerGreen  = nagcarlanGreen;
  static const Color _accentGreen  = nagcarlanGreen;
  static const Color _accentYellow = nagcarlanYellow;
  static const Color _bgPage = nagcarlanWhite;
  static const Color _cardBorder = Color(0xFFE2E8F0); // More defined border against white bg
  static const Color _textPrimary  = Color(0xFF1A202C); // Darker, sharper primary text
  static const Color _textMuted    = Color(0xFF4A5568); // Significant contrast increase for secondary text
  static const Color _textFaint    = Color(0xFF718096); // Clearer faint text for metadata

  TextStyle get _monoStyle => GoogleFonts.dmMono();
  TextStyle get _sansStyle => GoogleFonts.dmSans();

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchDriverTrips(widget.driverId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _historyFuture = _apiService.fetchDriverTrips(widget.driverId);
    });
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat("MMM dd, yyyy, hh:mm a").parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  List<dynamic> _getFilteredTrips(List<dynamic> trips) {
    final now = DateTime.now();
    return trips.where((trip) {
      final name  = (trip['passenger_name'] ?? '').toString().toLowerCase();
      final route = (trip['route'] ?? '').toString().toLowerCase();
      if (!name.contains(_searchQuery.toLowerCase()) &&
          !route.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_selectedFilter == "All") return true;
      final tripDate = _parseDate(trip['ended_at'] ?? '');
      if (tripDate == null) return true;

      if (_selectedFilter == "Today") {
        return tripDate.year == now.year &&
            tripDate.month == now.month &&
            tripDate.day == now.day;
      } else if (_selectedFilter == "This Week") {
        return tripDate.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_selectedFilter == "This Month") {
        return tripDate.year == now.year && tripDate.month == now.month;
      }
      return true;
    }).toList();
  }

  // ── Header (green zone) ────────────────────────────────────────
  Widget _buildGreenHeader(List<dynamic> filteredTrips) {
    double totalEarnings = filteredTrips.fold(
        0, (sum, t) => sum + ((t['fare_amount'] as num?)?.toDouble() ?? 0));

    return Container(
      color: _headerGreen,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  _circleBtn(
                    Icons.chevron_left,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: _sansStyle.copyWith(
                                color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Search name or route…",
                              hintStyle:
                                  _sansStyle.copyWith(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            onChanged: (v) => setState(() {
                              _searchQuery = v;
                              _currentPage = 0;
                            }),
                          )
                        : Text(
                            "Trip History",
                            textAlign: TextAlign.center,
                            style: _sansStyle.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                  ),
                  _circleBtn(
                    _isSearching ? Icons.close : Icons.search,
                    onTap: () => setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = "";
                        _searchController.clear();
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.refresh, onTap: _handleRefresh),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard(
                    label: "EARNINGS",
                    value: "₱${totalEarnings.toStringAsFixed(2)}",
                      icon: Icons.account_balance_wallet_outlined, // Consistent with passenger screen
                    valueColor: _accentYellow,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard(
                    label: "TRIPS",
                    value: "${filteredTrips.length}",
                      icon: Icons.route_outlined, // Consistent with passenger screen
                    valueColor: Colors.white,
                  )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filter pills
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ["All", "Today", "This Week", "This Month"]
                      .map(_buildFilterPill)
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: _sansStyle.copyWith(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: _monoStyle.copyWith(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = filter;
        _currentPage = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _accentYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all( // Consistent with passenger screen
            color: isSelected ? _accentYellow : Colors.white30,
          ),
        ),
        child: Text(
          filter,
          style: _sansStyle.copyWith(
            color: isSelected ? _headerGreen : Colors.white70,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Section date label ─────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: _sansStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: _textMuted,
        ),
      ),
    );
  }

  // ── Trip card (now uses the shared widget) ─────────────────────
  Widget _buildTripCard(dynamic trip) {
    return TripCardWidget(
      trip: trip,
      monoStyle: _monoStyle,
      sansStyle: _sansStyle,
      accentGreen: _accentGreen,
      accentYellow: nagcarlanYellow, // Use global constant
      cardBorder: _cardBorder,
      textPrimary: _textPrimary,
      textMuted: _textMuted,
      textFaint: _textFaint,
    );
  }

  // ── Pagination ─────────────────────────────────────────────────
  Widget _buildPagination(int currentPage, int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageArrow(Icons.chevron_left,
              onTap: currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null),
          const SizedBox(width: 14),
          Text.rich(
            TextSpan(
              style: _sansStyle.copyWith(
                  fontSize: 13, color: _textMuted),
              children: [
                const TextSpan(text: "Page "),
                TextSpan(
                  text: "${currentPage + 1}",
                  style: _sansStyle.copyWith(
                      color: _textPrimary, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: " of "),
                TextSpan(
                  text: "$totalPages",
                  style: _sansStyle.copyWith(
                      color: _textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _pageArrow(Icons.chevron_right,
              onTap: currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null),
        ],
      ),
    );
  }

  Widget _pageArrow(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE3E5E3)),
        ),
        child: Icon(icon,
            color: onTap != null ? const Color(0xFF6B7280) : _textFaint,
            size: 20),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 64, color: _textMuted),
          const SizedBox(height: 16),
          Text("No results found.",
              style: _sansStyle.copyWith(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Try adjusting your filters or search.",
              style: _sansStyle.copyWith(color: _textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: _headerGreen,
              child: const Center(
                child: CircularProgressIndicator(color: _accentYellow),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error loading trip history",
                  style:
                      _sansStyle.copyWith(color: _textPrimary, fontSize: 16)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No trips found.",
                  style:
                      _sansStyle.copyWith(color: _textPrimary, fontSize: 16)),
            );
          }

          final filteredTrips = _getFilteredTrips(snapshot.data!);
          final totalPages =
              (filteredTrips.length / _itemsPerPage).ceil().clamp(1, 9999);
          final paginatedTrips = filteredTrips
              .skip(_currentPage * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

          // Group paginatedTrips by date label
          final Map<String, List<dynamic>> grouped = {};
          for (final trip in paginatedTrips) {
            final dt = _parseDate(trip['ended_at'] ?? '');
            final label = dt != null
                ? DateFormat("MMMM d, yyyy").format(dt)
                : "Unknown Date";
            grouped.putIfAbsent(label, () => []).add(trip);
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: _accentGreen,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Sticky green header
                SliverToBoxAdapter(
                  child: _buildGreenHeader(filteredTrips),
                ),

                // ── Trip cards grouped by date
                if (paginatedTrips.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entries = grouped.entries.toList();
                        final widgets = <Widget>[];
                        for (final entry in entries) {
                          widgets.add(_buildSectionLabel(entry.key));
                          for (final trip in entry.value) {
                            widgets.add(_buildTripCard(trip));
                          }
                        }
                        // pagination + footer after last item
                        if (totalPages > 1) {
                          widgets.add(_buildPagination(_currentPage, totalPages));
                        }
                        widgets.add(const BrandingFooter());
                        widgets.add(const SizedBox(height: 24));
                        return widgets[index];
                      },
                      childCount: () {
                        int count = 0;
                        for (final e in grouped.entries) {
                          count += 1 + e.value.length; // label + cards
                        }
                        if (totalPages > 1) count++;
                        count += 2; // BrandingFooter + SizedBox
                        return count;
                      }(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}