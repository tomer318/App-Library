import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AdvancedSearchDialog extends StatefulWidget {
  const AdvancedSearchDialog({super.key});

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  late String author;
  late String genre;
  late String status;
  late String sort;
  final authorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    author = globalAppState.filterAuthor;
    genre = globalAppState.selectedGenre;
    status = globalAppState.filterStatus;
    sort = globalAppState.sortBy;
    authorCtrl.text = author;
  }

  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.deepPurpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                globalAppState.t('adv_search_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth < 500 ? screenWidth * 0.9 : 420,
        height: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: authorCtrl,
                decoration: InputDecoration(
                  labelText: state.t('author'),
                  prefixIcon: const Icon(Icons.person_search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(state.t('genre'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: genre,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: state.genres.map((g) => DropdownMenuItem(value: g, child: Text(state.tGenre(g)))).toList(),
                onChanged: (v) => setState(() => genre = v ?? 'Tất cả'),
              ),
              const SizedBox(height: 16),
              Text(state.t('status'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'Tất cả', child: Text(state.t('all_status'))),
                  DropdownMenuItem(value: 'Đang tiến hành', child: Text(state.t('ongoing'))),
                  DropdownMenuItem(value: 'Đã hoàn thành', child: Text(state.t('completed'))),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Tất cả'),
              ),
              const SizedBox(height: 16),
              Text(state.t('sort_by'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: sort,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 'Mới nhất', child: Text(state.t('sort_newest'))),
                  DropdownMenuItem(value: 'Lượt xem', child: Text(state.t('sort_views'))),
                  DropdownMenuItem(value: 'Điểm đánh giá', child: Text(state.t('sort_rating'))),
                ],
                onChanged: (v) => setState(() => sort = v ?? 'Mới nhất'),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      actions: [
        TextButton(
          onPressed: () {
            state.resetFilters();
            setState(() {
              authorCtrl.clear();
              genre = 'Tất cả';
              status = 'Tất cả';
              sort = 'Mới nhất';
            });
          },
          child: Text(state.t('reset_default'), style: const TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          onPressed: () {
            state.setAdvancedFilter(
              author: authorCtrl.text.trim(),
              genre: genre,
              status: status,
              sort: sort,
            );
            Navigator.pop(context);
          },
          child: Text(state.t('apply_filter')),
        ),
      ],
    );
  }
}