import 'package:flutter/material.dart';
import '../state/app_state.dart';

class AdvancedSearchDialog extends StatefulWidget {
  const AdvancedSearchDialog({super.key});

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  late Set<String> localTags;
  late String status;
  late String sort;
  final authorCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = globalAppState;
    authorCtrl.text = state.filterAuthor;
    yearCtrl.text = state.filterYear != null ? state.filterYear.toString() : '';
    localTags = Set.from(state.selectedTags);
    status = state.filterStatus;
    sort = state.sortBy;
  }

  @override
  void dispose() {
    authorCtrl.dispose();
    yearCtrl.dispose();
    super.dispose();
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
                state.t('adv_search_title'),
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
        width: screenWidth < 500 ? screenWidth * 0.9 : 450,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LỌC THEO TÁC GIẢ & NĂM PHÁT HÀNH
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: authorCtrl,
                      decoration: InputDecoration(
                        labelText: state.t('author'),
                        prefixIcon: const Icon(Icons.person_search),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Năm phát hành',
                        prefixIcon: Icon(Icons.calendar_today, size: 16),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. CHỌN NHIỀU THỂ LOẠI (TAGS) CÙNG LÚC
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.t('genre')} (${localTags.isEmpty ? state.t('all') : '${localTags.length} đã chọn'}):',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (localTags.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () => setState(() => localTags.clear()),
                      child: const Text('Bỏ chọn tất cả', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: state.masterTags.map((tag) {
                  final isSelected = localTags.contains(tag);
                  return FilterChip(
                    label: Text(state.tGenre(tag), style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          localTags.add(tag);
                        } else {
                          localTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 3. TÌNH TRẠNG
              Text(state.t('status'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem(value: 'Tất cả', child: Text(state.t('all_status'))),
                  DropdownMenuItem(value: 'Đang tiến hành', child: Text(state.t('ongoing'))),
                  DropdownMenuItem(value: 'Đã hoàn thành', child: Text(state.t('completed'))),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Tất cả'),
              ),
              const SizedBox(height: 16),

              // 4. SẮP XẾP
              Text(state.t('sort_by'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: sort,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
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
              yearCtrl.clear();
              localTags.clear();
              status = 'Tất cả';
              sort = 'Mới nhất';
            });
          },
          child: Text(state.t('reset_default'), style: const TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          onPressed: () {
            final parsedYear = int.tryParse(yearCtrl.text.trim());
            state.setAdvancedFilter(
              author: authorCtrl.text.trim(),
              tags: localTags,
              status: status,
              sort: sort,
              year: parsedYear,
            );
            Navigator.pop(context);
          },
          child: Text(state.t('apply_filter')),
        ),
      ],
    );
  }
}