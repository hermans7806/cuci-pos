import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/order_picker_item.dart';

class CustomerPickerModal extends StatefulWidget {
  final Future<List<PickerItem>> Function(int page, String? search) fetchItems;
  final void Function(PickerItem item) onSelected;

  const CustomerPickerModal({
    super.key,
    required this.fetchItems,
    required this.onSelected,
  });

  @override
  State<CustomerPickerModal> createState() => _CustomerPickerModalState();
}

class _CustomerPickerModalState extends State<CustomerPickerModal> {
  final ScrollController scrollCtrl = ScrollController();
  final TextEditingController searchCtrl = TextEditingController();

  List<PickerItem> items = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 0;
  String searchQuery = "";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadNextPage();

    scrollCtrl.addListener(() {
      if (scrollCtrl.position.pixels >=
              scrollCtrl.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        _loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  //──────────────────────────────────────────────────────────
  // LOAD PAGINATED DATA
  //──────────────────────────────────────────────────────────
  Future<void> _loadNextPage() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    final result = await widget.fetchItems(
      page,
      searchQuery.isEmpty ? null : searchQuery,
    );

    if (result.isEmpty) {
      hasMore = false;
    } else {
      items.addAll(result);
      page++;
    }

    setState(() => isLoading = false);
  }

  //──────────────────────────────────────────────────────────
  // SEARCH (DEBOUNCED)
  //──────────────────────────────────────────────────────────
  void _onSearchChanged(String text) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        searchQuery = text;
        items.clear();
        page = 0;
        hasMore = true;
      });

      _loadNextPage();
    });
  }

  //──────────────────────────────────────────────────────────
  // HIGHLIGHT MATCH
  //──────────────────────────────────────────────────────────
  Widget _highlightMatch(String text) {
    if (searchQuery.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = searchQuery.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) return Text(text);

    final end = start + searchQuery.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, start),
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(end),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  //──────────────────────────────────────────────────────────
  // BUILD UI
  //──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SafeArea(
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //───────────────────────────────────────────────
              // SEARCH BOX
              //───────────────────────────────────────────────
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Cari nama…",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),

              const SizedBox(height: 16),

              //───────────────────────────────────────────────
              // LIST VIEW
              //───────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: sortedItems.length + (isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    // Loading indicator row
                    if (i >= sortedItems.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = sortedItems[i];

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            item.name.isNotEmpty
                                ? item.name[0].toUpperCase()
                                : "?",
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        title: _highlightMatch(item.name),
                        subtitle: Text(item.phone),
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
