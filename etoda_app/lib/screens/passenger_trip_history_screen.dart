import 'package:flutter/material.dart';
import 'package:etoda_nagcarlan/main.dart';
import 'package:etoda_nagcarlan/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:etoda_nagcarlan/widgets/trip_card_widget.dart';
import 'package:etoda_nagcarlan/widgets/branding_footer.dart';
import 'package:etoda_nagcarlan/screens/passenger_trip_details_screen.dart';

class PassengerTripHistoryScreen extends StatefulWidget {
  const PassengerTripHistoryScreen({super.key});

  @override
  State<PassengerTripHistoryScreen> createState() => _PassengerTripHistoryScreenState();
}

class _PassengerTripHistoryScreenState extends State<PassengerTripHistoryScreen> {
  late Future<List<dynamic>> _historyFuture;
  final ApiService _apiService = ApiService();

  String _passengerId = '';
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, Today, This Week, This Month
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  // ── Design tokens (copied from driver_trip_history_screen.dart for consistency) ──────────────────────────────────────────────
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
  void didChangeDependencies() {
    super.didChangeDependencies(); // Always call super
    if (_passengerId.isEmpty) { // Only initialize once
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _passengerId = (args?['user_id'] ?? args?['passenger_id'])?.toString() ?? '';
      if (_passengerId.isNotEmpty) {
        _historyFuture = _apiService.fetchTrips(_passengerId);
      } else {
        _historyFuture = Future.value([]); // No passenger ID, no trips
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _historyFuture = _apiService.fetchTrips(_passengerId);
      _currentPage = 0; // Reset pagination on refresh
    });
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateFormat("MMM dd, yyyy, hh:mm a").parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  List<dynamic> _getFilteredTrips(List<dynamic> trips) {
    DateTime now = DateTime.now();
    final filtered = trips.where((trip) {
      final driverName = (trip['driver_name'] ?? "").toString().toLowerCase();
      final route = (trip['route'] ?? "").toString().toLowerCase();
      final matchesSearch = driverName.contains(_searchQuery.toLowerCase()) || 
                           route.contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      if (_selectedFilter == "All") return true; // If "All" is selected, no date filter

      DateTime? tripDate = _parseDate(trip['ended_at']?.toString());
      if (tripDate == null) return true; // If date can't be parsed, include it (or exclude based on desired behavior)

      if (_selectedFilter == "Today") {
        return tripDate.year == now.year && tripDate.month == now.month && tripDate.day == now.day;
      } else if (_selectedFilter == "This Week") {
        final weekAgo = now.subtract(const Duration(days: 7));
        return tripDate.isAfter(weekAgo) && tripDate.isBefore(now.add(const Duration(days: 1))); // Trips within the last 7 days including today
      } else if (_selectedFilter == "This Month") {
        return tripDate.year == now.year && tripDate.month == now.month;
      }
      return false; // Should not reach here if all filters are covered
    }).toList();
    return filtered;
  }

  // ── Header (white & green combination) ─────────────────────────
  Widget _buildHeader(List<dynamic> filteredTrips) {
    double totalSpent = filteredTrips.fold(
        0, (sum, t) => sum + ((t['fare_amount'] as num?)?.toDouble() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 1: White App Bar
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  _circleBtn(
                    Icons.chevron_left,
                    onTap: () => Navigator.pop(context),
                    bgColor: _accentGreen.withOpacity(0.1),
                    iconColor: _accentGreen,
                  ),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: _sansStyle.copyWith(
                                color: _accentGreen, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Search driver or route…",
                              hintStyle:
                                  _sansStyle.copyWith(color: _textFaint),
                              border: InputBorder.none,
                            ),
                            onChanged: (v) => setState(() {
                              _searchQuery = v;
                              _currentPage = 0;
                            }),
                          )
                        : Text(
                            "My Trip History",
                            textAlign: TextAlign.center,
                            style: _sansStyle.copyWith(
                              color: _accentGreen,
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
                    bgColor: _accentGreen.withOpacity(0.1),
                    iconColor: _accentGreen,
                  ),
                  const SizedBox(width: 4),
                  _circleBtn(
                    Icons.refresh,
                    onTap: _handleRefresh,
                    bgColor: _accentGreen.withOpacity(0.1),
                    iconColor: _accentGreen,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Section 2: Green Stats Row
        Container(
          color: _accentGreen,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    label: "TOTAL SPENT",
                    value: "₱${totalSpent.toStringAsFixed(2)}",
                    icon: Icons.account_balance_wallet_outlined,
                    valueColor: _accentYellow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                    label: "TRIPS",
                    value: "${filteredTrips.length}",
                    icon: Icons.route_outlined,
                    valueColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Section 3: Green Filters
        Container(
          color: _accentGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _circleBtn(IconData icon, {required VoidCallback onTap, Color? bgColor, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
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
        color: Colors.white.withValues(alpha: 0.12), // Fix: Deprecated withOpacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)), // Fix: Deprecated withOpacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: _sansStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
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
            style: _sansStyle.copyWith(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
            color: isSelected ? _accentGreen : Colors.white70,
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

  // ── Trip card ──────────────────────────────────────────────────
  Widget _buildTripCard(dynamic trip) {
    return InkWell(
      onTap: () {
        debugPrint("Navigating to PassengerTripDetailsScreen with: $trip");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PassengerTripDetailsScreen(),
            settings: RouteSettings(arguments: trip),
          ),
        );
      },
      child: IgnorePointer(
        child: TripCardWidget(
          trip: trip,
          monoStyle: _monoStyle,
          sansStyle: _sansStyle,
          accentGreen: _accentGreen,
          accentYellow: nagcarlanYellow,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textMuted: _textMuted,
          textFaint: _textFaint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: _bgPage,
              child: const Center(
                child: CircularProgressIndicator(color: _accentGreen),
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
            final dt = _parseDate(trip['ended_at']?.toString());
            final label = dt != null
                ? DateFormat("MMMM d, yyyy").format(dt)
                : "Unknown Date";
            grouped.putIfAbsent(label, () => []).add(trip);
          }

          // Flatten grouped trips into a list of widgets once to avoid expensive rebuilds in the delegate
          final List<Widget> listItems = [];
          for (final entry in grouped.entries) {
            listItems.add(_buildSectionLabel(entry.key));
            for (final trip in entry.value) {
              listItems.add(_buildTripCard(trip));
            }
          }
          if (totalPages > 1) {
            listItems.add(_buildPagination(_currentPage, totalPages));
          }
          listItems.add(const BrandingFooter());
          listItems.add(const SizedBox(height: 24));

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: _accentGreen,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // ── Header
                SliverToBoxAdapter(
                  child: _buildHeader(filteredTrips),
                ),

                // ── Trip cards grouped by date
                if (paginatedTrips.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => listItems[index],
                      childCount: listItems.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
}
