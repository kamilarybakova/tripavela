import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/remote_places.dart';
import 'components.dart';

class RemotePlacesScreen extends StatefulWidget {
  const RemotePlacesScreen({super.key, required this.catalog});

  final RemotePlaces catalog;

  @override
  State<RemotePlacesScreen> createState() => _RemotePlacesScreenState();
}

class _RemotePlacesScreenState extends State<RemotePlacesScreen> {
  List<RemotePlace>? _places;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cached = await widget.catalog.readCache();
      if (!mounted) return;
      setState(() => _places = cached);
    } on Exception {
      // A local read failure should not prevent a fresh download.
    }
    if (mounted) await _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final places = await widget.catalog.refresh();
      if (mounted) setState(() => _places = places);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _places ?? const <RemotePlace>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог мест'),
        actions: [
          IconButton(
            tooltip: 'Обновить каталог',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_failed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                places.isEmpty
                    ? 'Не удалось загрузить каталог. Попробуйте обновить.'
                    : 'Не удалось обновить каталог. Показана сохранённая версия.',
              ),
            ),
          if (!_loading && !_failed && places.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('В каталоге пока нет опубликованных мест.'),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _card(places[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(RemotePlace place) {
    final cover = Uri.tryParse(place.coverUrl);
    final latitude = place.latitude;
    final longitude = place.longitude;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cover != null && cover.scheme == 'https' && cover.hasAuthority)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Photo(place.coverUrl, height: 160),
            ),
          Text(place.name, style: Theme.of(context).textTheme.titleLarge),
          if (place.description.isNotEmpty) Text(place.description),
          if (latitude != null && longitude != null)
            TextButton(
              onPressed: () async {
                final opened = await launchUrl(
                  Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': '$latitude,$longitude',
                  }),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Не удалось открыть карту.')),
                  );
                }
              },
              child: const Text('Открыть на карте'),
            ),
        ],
      ),
    );
  }
}
