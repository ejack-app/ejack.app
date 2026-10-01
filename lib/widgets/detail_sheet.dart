import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';

/// Bottom sheet that shows a record's full detail and lets the user POST
/// a status change (e.g. driver accepting / starting / completing a trip).
class DetailSheet extends StatefulWidget {
  const DetailSheet({
    super.key,
    required this.record,
    this.actionEndpointBuilder,
    this.actions = const [],
  });

  final Map<String, dynamic> record;

  /// Build the action URL given the record and action key.
  /// e.g. (r, action) => '/trips/${r['id']}/$action/'
  final String Function(Map<String, dynamic> record, String action)?
      actionEndpointBuilder;

  /// Action buttons shown at the bottom.
  final List<DetailAction> actions;

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class DetailAction {
  const DetailAction({
    required this.label,
    required this.actionKey,
    this.icon,
    this.destructive = false,
  });
  final String label;
  final String actionKey;
  final IconData? icon;
  final bool destructive;
}

class _DetailSheetState extends State<DetailSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _run(DetailAction a) async {
    final builder = widget.actionEndpointBuilder;
    if (builder == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient.instance.dio.post(builder(widget.record, a.actionKey));
      if (!mounted) return;
      Navigator.of(context).pop(true); // caller refreshes the list
    } on DioException catch (e) {
      setState(() {
        _busy = false;
        _error = _msg(e);
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  String _msg(DioException e) {
    final s = e.response?.statusCode;
    if (s == 400) return 'الطلب مرفوض — تحقق من البيانات';
    if (s == 403) return 'ليس لديك صلاحية لهذا الإجراء';
    if (s == 404) return 'العنصر لم يعد موجوداً';
    if (s == 500) return 'خطأ في السيرفر — راجع Django logs';
    return 'فشل الإجراء (${s ?? "لا اتصال"})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.record.entries.toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scroll,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return ListTile(
                    dense: true,
                    title: Text(e.key, style: theme.textTheme.bodySmall),
                    subtitle: SelectableText(
                      '${e.value ?? "—"}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            if (widget.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.actions.map((a) {
                  final style = a.destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        )
                      : null;
                  return FilledButton.icon(
                    onPressed: _busy ? null : () => _run(a),
                    style: style,
                    icon: Icon(a.icon ?? Icons.send),
                    label: Text(a.label),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
