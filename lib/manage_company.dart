import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class ViewCompaniesPage extends StatefulWidget {
  const ViewCompaniesPage({super.key});

  @override
  _ViewCompaniesPageState createState() => _ViewCompaniesPageState();
}

class _ViewCompaniesPageState extends State<ViewCompaniesPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  String _sortColumn = 'company_name';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalCompanies = 0;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Calculate pagination
      final from = (_currentPage - 1) * _itemsPerPage;
      final to = from + _itemsPerPage - 1;

      // Build query
      var query = supabase.from('tbl_company').select('*');

      // Add search filter if search text is provided
      if (_searchController.text.isNotEmpty) {
        query = query.or(
            'company_name.ilike.%${_searchController.text}%,company_email.ilike.%${_searchController.text}%');
      }

      // Execute query with pagination
      final response = await query.range(from, to);
      // Fetch total count for pagination
      final totalResponse = await supabase.from('tbl_company').select(
            '*',
          );

      setState(() {
        _companies = List<Map<String, dynamic>>.from(response);
        _totalCompanies = totalResponse.length ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching companies: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch companies')),
      );
    }
  }

  Future<void> _updateCompanyStatus(String id, int status) async {
    final action = status == 1 ? 'Verify' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text(
            'Are you sure you want to $action this company? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: status == 1 ? Colors.green : Colors.red),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await supabase
          .from('tbl_company')
          .update({'company_status': status}).eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Company ${status == 1 ? 'verified' : 'rejected'} successfully')),
      );
      _fetchCompanies();
    } catch (e) {
      print("Error updating company status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update company status')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
    _fetchCompanies();
  }

  void _changeSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
    _fetchCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Companies',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCompaniesTable(),
            ),
            const SizedBox(height: 16),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search companies by name or email...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _fetchCompanies();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetchCompanies(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _fetchCompanies,
        ),
      ],
    );
  }

  Widget _buildCompaniesTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _companies.isEmpty
          ? const Center(child: Text('No companies found'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 16,
                      dataRowHeight: 56,
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.grey.shade100),
                      columns: [
                        DataColumn(
                          label: const Text(
                            'Name',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onSort: (columnIndex, _) =>
                              _changeSort('company_name'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Email',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onSort: (columnIndex, _) =>
                              _changeSort('company_email'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Phone',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onSort: (columnIndex, _) =>
                              _changeSort('company_phone'),
                        ),
                        DataColumn(
                          label: const Text(
                            'Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onSort: (columnIndex, _) =>
                              _changeSort('company_status'),
                        ),
                        const DataColumn(
                          label: Text(
                            'Actions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                      rows: _companies.map((company) {
                        final status = company['company_status'] ?? 0;
                        final statusText = status == 1
                            ? 'Verified'
                            : status == 2
                                ? 'Rejected'
                                : 'Pending';
                        final statusColor = status == 1
                            ? Colors.green
                            : status == 2
                                ? Colors.red
                                : Colors.orange;

                        return DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: company['company_name'] ?? '',
                                child: Container(
                                  constraints: const BoxConstraints(
                                      maxWidth: 150), // Adjust as needed
                                  child: Text(
                                    company['company_name'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Tooltip(
                                message: company['company_email'] ?? '',
                                child: Container(
                                  constraints: const BoxConstraints(
                                      maxWidth: 200), // Adjust as needed
                                  child: Text(
                                    company['company_email'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Tooltip(
                                message: company['company_phone'] ?? '',
                                child: Container(
                                  constraints: const BoxConstraints(
                                      maxWidth: 120), // Adjust as needed
                                  child: Text(
                                    company['company_phone'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status == 0)
                                    IconButton(
                                      icon: const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                      onPressed: () => _updateCompanyStatus(
                                          company['id'], 1),
                                      tooltip: 'Verify',
                                    ),
                                  if (status == 0)
                                    IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _updateCompanyStatus(
                                          company['id'], 2),
                                      tooltip: 'Reject',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_totalCompanies / _itemsPerPage).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _totalCompanies ? _totalCompanies : _currentPage * _itemsPerPage} of $_totalCompanies entries',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey),
              onPressed:
                  _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
            ),
            ...List.generate(
              totalPages > 5 ? 5 : totalPages,
              (index) {
                int pageNumber;
                if (totalPages <= 5) {
                  pageNumber = index + 1;
                } else if (_currentPage <= 3) {
                  pageNumber = index + 1;
                } else if (_currentPage >= totalPages - 2) {
                  pageNumber = totalPages - 4 + index;
                } else {
                  pageNumber = _currentPage - 2 + index;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pageNumber == _currentPage
                          ? Colors.blue
                          : Colors.white,
                      foregroundColor: pageNumber == _currentPage
                          ? Colors.white
                          : Colors.black,
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: pageNumber == _currentPage
                                ? Colors.blue
                                : Colors.grey.shade300),
                      ),
                    ),
                    onPressed: pageNumber == _currentPage
                        ? null
                        : () => _changePage(pageNumber),
                    child: Text('$pageNumber'),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: _currentPage < totalPages
                  ? () => _changePage(_currentPage + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
