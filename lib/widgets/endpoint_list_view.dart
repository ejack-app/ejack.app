import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import 'detail_sheet.dart';

/// Generic list view that GETs a Django REST endpoint and renders the results.
/// Handles DRF's `PageNumberPagination` shape (`count`/`next`/`results`) and
/// falls back to a plain list or a single object.
class EndpointListView extends StatefulWidget {
  const EndpointListView({
    super.key,
    required this.title,
    required this.endpoint,
    this.detailActions = const [],
    this.actionEndpointBuilder,
  });

  final String title;
  final String endpoint;
  final List<DetailAction> detailActions;
  final String Function(Map<String, dynamic> record, String action)?
      actionEndpointBuilder;

  @override
  State<EndpointListView> createState() => _EndpointListViewState();
}

class _EndpointListViewState extends State<EndpointListView> {
  final _dio = ApiClient.instance.dio;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final r = await _dio.get<dynamic>(widget.endpoint);
    final data = r.data;
    if (data is Map<String, dynamic> && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic>) return [data];
    return const [];
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openDetail(Map<String, dynamic> record) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetailSheet(
        record: record,
        actions: widget.detailActions,
        actionEndpointBuilder: widget.actionEndpointBuilder,
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return _ErrorView(error: snap.error!, onRetry: _refresh);
          final items = snap.data ?? const [];
          if (items.isEmpty) return const _EmptyView();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RecordCard(
              record: items[i],
              onTap: () => _openDetail(items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});
  final Map<String, dynamic> record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = record['title'] ??
        record['name'] ??
        record['full_name'] ??
        record['id']?.toString() ??
        'سجل';
    final subtitle = record['status'] ??
        record['email'] ??
        record['phone'] ??
        record['description'];
    final status = record['status']?.toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        title: Text(title.toString()),
        subtitle: subtitle == null ? null : Text(subtitle.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null) _StatusChip(status: status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(_translate(status),
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  (Color, Color) _colors(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
      case 'done':
      case 'active':
        return (cs.primaryContainer, cs.onPrimaryContainer);
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return (cs.errorContainer, cs.onErrorContainer);
      case 'pending':
      case 'assigned':
      case 'in_progress':
      case 'on_the_way':
        return (cs.tertiaryContainer, cs.onTertiaryContainer);
      default:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }

  String _translate(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'assigned':
        return 'مُسنَد';
      case 'in_progress':
        return 'جارٍ';
      case 'on_the_way':
        return 'في الطريق';
      case 'completed':
      case 'done':
        return 'مكتمل';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return s;
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Center(child: Text('لا توجد بيانات')),
            ],
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is DioException
        ? _dioMsg(error as DioException)
        : error.toString();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      ],
    );
  }

  String _dioMsg(DioException e) {
    final s = e.response?.statusCode;
    if (s == 404) return 'المسار غير موجود على السيرفر';
    if (s == 403) return 'ليس لديك صلاحية لهذا القسم';
    if (s == 500) return 'خطأ في السيرفر — راجع سجلات Django';
    return 'تعذر تحميل البيانات (${s ?? "لا اتصال"})';
  }
}
