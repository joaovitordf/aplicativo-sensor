import 'package:flutter/material.dart';
import 'package:sensortech/core/constants.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String? label;
  final String hint;
  final IconData? prefixIcon;
  final T? value;
  final List<SearchableDropdownItem<T>> items;
  final void Function(T?)? onChanged;

  const SearchableDropdown({
    super.key,
    this.label,
    required this.hint,
    this.prefixIcon,
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
          title: widget.label ?? widget.hint,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPalettePrimaryDark,
            ),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: widget.onChanged != null ? _openSearchDialog : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  widget.onChanged != null ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPaletteLightGray),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: kPalettePrimaryDark,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selectedItem?.label ?? widget.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: selectedItem != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: kPalettePrimaryDark,
                  size: 20,
                ),
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

    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogMaxHeight = (screenHeight * 0.8).clamp(240.0, 520.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: dialogMaxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                controller: _controller,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kPaletteLightGray),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Nenhum item encontrado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.value == widget.selectedValue;
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
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
