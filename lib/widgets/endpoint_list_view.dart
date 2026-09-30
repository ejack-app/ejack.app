import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';

/// Generic list view that GETs a Django REST endpoint and renders the results.
/// Handles DRF's `PageNumberPagination` shape (`count`/`next`/`results`) and
/// falls back to a plain list or a single object.
class EndpointListView extends StatefulWidget {
  const EndpointListView({
    super.key,
    required this.title,
    required this.endpoint,
  });

  final String title;
  final String endpoint;

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
            itemBuilder: (_, i) => _RecordCard(record: items[i]),
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final Map<String, dynamic> record;

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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        title: Text(title.toString()),
        subtitle: subtitle == null ? null : Text(subtitle.toString()),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(_pretty(record)),
            ),
          ),
        ),
      ),
    );
  }

  String _pretty(Map<String, dynamic> r) =>
      r.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('لا توجد بيانات', textAlign: TextAlign.center),
            ],
          ),
        ),
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
    return Center(
      child: Padding(
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
