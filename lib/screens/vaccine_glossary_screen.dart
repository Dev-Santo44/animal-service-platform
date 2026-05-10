import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/vaccine_type.dart';
import '../theme/app_theme.dart';

class VaccineGlossaryScreen extends StatefulWidget {
  const VaccineGlossaryScreen({super.key});

  @override
  State<VaccineGlossaryScreen> createState() => _VaccineGlossaryScreenState();
}

class _VaccineGlossaryScreenState extends State<VaccineGlossaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VaccineGlossaryTerm> _terms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGlossary();
  }

  Future<void> _loadGlossary({String search = ''}) async {
    setState(() => _isLoading = true);
    final results = await ApiService.getGlossary(search: search);
    if (mounted) {
      setState(() {
        _terms = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccination Glossary'),
        elevation: 0,
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2D6A4F),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _loadGlossary(search: v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search terms (e.g., Zoonotic, Core)',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading && _terms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _terms.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _terms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final term = _terms[index];
                          return _GlossaryCard(term: term);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No terms found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}

class _GlossaryCard extends StatelessWidget {
  final VaccineGlossaryTerm term;
  const _GlossaryCard({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D6A4F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.book_outlined, color: Color(0xFF2D6A4F), size: 20),
        ),
        title: Text(
          term.term,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              term.definition,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
