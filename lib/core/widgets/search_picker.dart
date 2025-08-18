import 'package:flutter/material.dart';

class SearchPicker {
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    String Function(T item)? itemToString,
    T? initiallySelected,
  }) async {
    final toStr = itemToString ?? (T v) => v.toString();
    final TextEditingController controller = TextEditingController();
    List<T> filtered = List<T>.from(items);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            void applyFilter(String q) {
              final query = q.toLowerCase();
              setSt(() {
                filtered = items
                    .where((e) => toStr(e).toLowerCase().contains(query))
                    .toList();
              });
            }

            final view = MediaQuery.of(ctx);
            final sheetHeight = view.size.height * 0.75;
            return SizedBox(
              height: sheetHeight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: view.viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: applyFilter,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final label = toStr(item);
                          final isSelected =
                              initiallySelected != null &&
                              toStr(initiallySelected!) == label;
                          return ListTile(
                            title: Text(label),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () => Navigator.pop(ctx, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
