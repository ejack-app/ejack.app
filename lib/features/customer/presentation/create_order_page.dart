import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _form = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _dropoff = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();
  String _service = 'standard';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pickup.dispose();
    _dropoff.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ApiClient.instance.dio.post(
        ApiConstants.orders,
        data: {
          'pickup_address': _pickup.text.trim(),
          'dropoff_address': _dropoff.text.trim(),
          'notes': _notes.text.trim(),
          'contact_phone': _phone.text.trim(),
          'service_type': _service,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء الطلب #${r.data?["id"] ?? ""}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
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
    final body = e.response?.data;
    if (s == 400 && body is Map) {
      // DRF ValidationError returns {field: [msg]}
      final first = body.entries.firstOrNull;
      if (first != null) return '${first.key}: ${(first.value is List) ? (first.value as List).first : first.value}';
    }
    if (s == 401) return 'انتهت الجلسة — سجّل دخول مجدداً';
    if (s == 500) return 'خطأ في السيرفر';
    return 'فشل إنشاء الطلب (${s ?? "لا اتصال"})';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب جديد')),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _pickup,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الاستلام',
                    prefixIcon: Icon(Icons.my_location),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dropoff,
                  decoration: const InputDecoration(
                    labelText: 'عنوان التسليم',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم التواصل',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    if (v.trim().length < 7) return 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'standard', label: Text('عادي'), icon: Icon(Icons.schedule)),
                    ButtonSegment(value: 'express', label: Text('سريع'), icon: Icon(Icons.flash_on)),
                    ButtonSegment(value: 'scheduled', label: Text('مجدول'), icon: Icon(Icons.event)),
                  ],
                  selected: {_service},
                  onSelectionChanged: (s) => setState(() => _service = s.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال الطلب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
