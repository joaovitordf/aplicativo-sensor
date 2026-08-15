import 'package:flutter/material.dart';
import 'package:sensortech/core/constants.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final T? value;
  final List<SearchableDropdownItem<T>> items;
  final void Function(T?)? onChanged;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    this.onChanged,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _SearchDialog<T>(
          title: widget.label,
          items: widget.items,
          selectedValue: widget.value,
          onSelected: (val) {
            if (widget.onChanged != null) {
              widget.onChanged!(val);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem =
        widget.items.where((i) => i.value == widget.value).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kPalettePrimaryDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.onChanged != null ? _openSearchDialog : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  widget.onChanged != null ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPaletteLightGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedItem?.label ?? widget.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          selectedItem != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    color: kPalettePrimaryDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SearchableDropdownItem<T> {
  final T value;
  final String label;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
  });
}

class _SearchDialog<T> extends StatefulWidget {
  final String title;
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;
  final void Function(T) onSelected;

  const _SearchDialog({
    required this.title,
    required this.items,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  String _searchQuery = '';
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      return item.label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPaletteLightGray),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item.value == widget.selectedValue;
                  return ListTile(
                    title: Text(item.label),
                    selected: isSelected,
                    selectedColor: kPalettePrimaryDark,
                    selectedTileColor:
                        kPalettePrimaryDark.withValues(alpha: 0.1),
                    onTap: () {
                      widget.onSelected(item.value);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
