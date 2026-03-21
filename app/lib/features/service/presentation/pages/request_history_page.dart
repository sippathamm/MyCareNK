import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'request_history_detail_page.dart';

import '../../data/models/condom_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  RequestStatus? _selectedFilter;
  String _searchQuery = '';

  List<CondomRequestModel> _requests = [];
  bool _isLoading = true;
  bool _isLoggedIn = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('condom_requests')
          .select()
          .eq('user_id', session.user.id)
          .order('created_at', ascending: false);

      final List<CondomRequestModel> loadedRequests = (response as List)
          .map((item) => CondomRequestModel.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _requests = loadedRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _requests.where((req) {
      if (_selectedFilter != null && req.status != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !req.referenceNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8A50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ประวัติการขอ',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A50)))
                  : !_isLoggedIn
                  ? Center(
                      child: Text(
                        'กรุณาเข้าสู่ระบบ',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : _requests.isEmpty
                  ? Center(
                      child: Text(
                        'ยังไม่มีรายการ',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : filteredRequests.isEmpty
                  ? Center(
                      child: Text(
                        'ไม่พบรายการ',
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ListView.builder(
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(filteredRequests[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.orange[50], // Light orange theme
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'ค้นหาประวัติการขอ',
          hintStyle: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 14),
          suffixIcon: const Icon(Icons.search, color: Color(0xFFFF8A50)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildFilterChip('ทั้งหมด', null),
          const SizedBox(width: 8),
          _buildFilterChip('ส่งคำขอ', RequestStatus.submitted),
          const SizedBox(width: 8),
          _buildFilterChip('กำลังเตรียม', RequestStatus.preparing),
          const SizedBox(width: 8),
          _buildFilterChip('เสร็จสิ้น', RequestStatus.completed),
          const SizedBox(width: 8),
          _buildFilterChip('ยกเลิก', RequestStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RequestStatus? status) {
    final bool isSelected = _selectedFilter == status;
    Color primaryColor;

    switch (status) {
      case null:
        primaryColor = const Color(0xFFFF8A50);
        break;
      case RequestStatus.submitted:
        primaryColor = const Color(0xFFFF8A50); // Orange
        break;
      case RequestStatus.preparing:
        primaryColor = const Color(0xFF1F77C3); // Blue
        break;
      case RequestStatus.completed:
        primaryColor = const Color(0xFF26A69A); // Green
        break;
      case RequestStatus.cancelled:
        primaryColor = Colors.grey[600]!;
        break;
    }

    return Material(
      color: isSelected ? primaryColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryColor),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = status;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.prompt(
              color: isSelected ? Colors.white : primaryColor,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(CondomRequestModel data) {
    Color iconBgColor;
    Color iconColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;
    IconData statusIcon;

    switch (data.status) {
      case RequestStatus.submitted:
        iconBgColor = const Color(0xFFFBE9E7); // Lighter orange
        iconColor = const Color(0xFFFF8A50);
        statusBgColor = const Color(0xFFFF8A50);
        statusTextColor = Colors.white;
        statusText = 'ส่งคำขอ';
        statusIcon = Icons.assignment_outlined;
        break;
      case RequestStatus.preparing:
        iconBgColor = const Color(0xFFE3F2FD); // Light blue
        iconColor = const Color(0xFF4A9FE8); // Blue
        statusBgColor = const Color(0xFF4A9FE8); // Blue
        statusTextColor = Colors.white;
        statusText = 'กำลังเตรียม';
        statusIcon = Icons.inventory_2_outlined; // Preparing package
        break;
      case RequestStatus.completed:
        iconBgColor = const Color(0xFFE0F2F1); // Lighter teal/green
        iconColor = const Color(0xFF26A69A);
        statusBgColor = const Color(0xFF64FFDA); // Bright mint green
        statusTextColor = const Color(0xFF333333);
        statusText = 'เสร็จสิ้น';
        statusIcon = Icons.check_circle_outline; // Completed check
        break;
      case RequestStatus.cancelled:
        iconBgColor = Colors.grey[200]!;
        iconColor = Colors.grey[600]!;
        statusBgColor = Colors.grey[300]!;
        statusTextColor = const Color(0xFF333333);
        statusText = 'ยกเลิก';
        statusIcon = Icons.cancel_outlined; // Cancelled
        break;
    }

    // Format selectedDate and selectedTime
    String outputDate = data.selectedDate ?? '-';
    if (data.selectedDate != null && data.selectedDate!.contains('-')) {
      try {
        DateTime parsedDate = DateTime.parse(data.selectedDate!);
        outputDate = '${parsedDate.day} ${formatMonthTH(parsedDate.month)} ${parsedDate.year + 543}';
      } catch (e) {
        outputDate = data.selectedDate!;
      }
    }

    String outputTime = data.selectedTime ?? '-';
    if (data.selectedTime != null && data.selectedTime!.contains(':')) {
       final splitted = data.selectedTime!.split(':');
       if(splitted.length >= 2) {
          outputTime = '${splitted[0]}:${splitted[1]} น.';
       }
    }
    String dateStr = '$outputDate, $outputTime';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'หมายเลขอ้างอิง',
                        style: GoogleFonts.prompt(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        data.referenceNumber,
                        style: GoogleFonts.prompt(
                          color: const Color(0xFF333333),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.prompt(
                      color: statusTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.prompt(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  data.selectedLocation ?? '-',
                  style: GoogleFonts.prompt(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RequestHistoryDetailPage(data: data),
                    ),
                  );
                  // Refresh history after return to get updated statuses (like cancelled)
                  _fetchHistory();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ดูข้อมูล',
                      style: TextStyle(
                        color: Color(0xFFFF8A50),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFFFF8A50),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatMonthTH(int month) {
    switch (month) {
      case 1: return 'มกราคม';
      case 2: return 'กุมภาพันธ์';
      case 3: return 'มีนาคม';
      case 4: return 'เมษายน';
      case 5: return 'พฤษภาคม';
      case 6: return 'มิถุนายน';
      case 7: return 'กรกฎาคม';
      case 8: return 'สิงหาคม';
      case 9: return 'กันยายน';
      case 10: return 'ตุลาคม';
      case 11: return 'พฤศจิกายน';
      case 12: return 'ธันวาคม';
      default: return '';
    }
  }
}
