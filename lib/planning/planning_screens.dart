import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/store.dart';
import '../navigation/navigation_environment.dart';
import '../navigation/walk_navigation_map.dart';
import '../ui/components.dart';
import 'planner.dart';

const _vibes = <(String, String, String, IconData)>[
  (
    'classic',
    'Первый раз в городе',
    'Главные места и время на открытия',
    Icons.account_balance_outlined,
  ),
  (
    'food',
    'Есть и жить как местный',
    'Рынки, районы и вкусные паузы',
    Icons.restaurant_outlined,
  ),
  (
    'art',
    'Искусство и находки',
    'Выставки, книжные и переулки',
    Icons.palette_outlined,
  ),
  (
    'sea',
    'Гулять без спешки',
    'Набережные, парки и меньше переездов',
    Icons.waves_outlined,
  ),
];
String _days(int n) => '$n ${n < 5 ? 'дня' : 'дней'}';
String _places(int n) =>
    '$n ${n == 1
        ? 'место'
        : n < 5
        ? 'места'
        : 'мест'}';
String _date(DateTime d) => DateFormat('d MMM', 'ru').format(d);
String _vibe(String id) => _vibes.firstWhere((v) => v.$1 == id).$2;
Widget _heading(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 14),
  child: EditorialText(text),
);
Widget _action(String text, VoidCallback? onTap) => SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: onTap,
    child: Text(text, textAlign: TextAlign.center),
  ),
);
Future<bool> _save(BuildContext c, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (_) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(
        const SnackBar(
          content: Text('Не получилось сохранить. Попробуйте ещё раз.'),
        ),
      );
    }
    return false;
  }
}

Widget _notFound(BuildContext c) => PageFrame(
  title: 'План поездки',
  leading: BackButton(onPressed: () => c.go('/home')),
  child: Column(
    children: [
      const Text('Этот план недоступен.'),
      TextButton(
        onPressed: () => c.go('/trips'),
        child: const Text('К моим поездкам'),
      ),
    ],
  ),
);

class PlannedTripsScreen extends ConsumerWidget {
  const PlannedTripsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    return PageFrame(
      title: 'Мои поездки',
      leading: const BackButton(),
      footer: _action('Спланировать поездку', () => context.push('/plan-trip')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (store.travelPlans.isEmpty) ...[
            Photo(store.cityData['image'], height: 230),
            _heading(context, 'Путешествие в вашем ритме'),
            const Text(
              'Расскажите, что любите и где остановитесь. Соберём дни так, чтобы вы успевали жить в городе, а не только ставить галочки.',
            ),
            const SizedBox(height: 22),
            const InfoLine(
              Icons.hotel_outlined,
              'Первый день — недалеко от отеля',
            ),
            const InfoLine(Icons.route_outlined, 'Соседние районы в один день'),
            const InfoLine(
              Icons.coffee_outlined,
              'Дорога, обед и паузы уже учтены',
            ),
            const SizedBox(height: 16),
            const Tag('5 городов · планы на 2–7 дней'),
          ],
          for (final plan in store.travelPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/trip-plan/${plan.id}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined),
                          const Spacer(),
                          Text(_days(plan.brief.days)),
                        ],
                      ),
                      _heading(
                        context,
                        '${store.cityFor(plan.brief.cityId)['name']}',
                      ),
                      Text(
                        '${_date(plan.brief.date)} — ${_date(plan.days.last.date)} · ${_vibe(plan.brief.vibe)}',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        plan.brief.hotel.isEmpty
                            ? store
                                  .planningFor(plan.brief.cityId)
                                  .zone(plan.brief.zone)['name']
                            : plan.brief.hotel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TripSetupScreen extends ConsumerStatefulWidget {
  final String? editId;
  const TripSetupScreen({super.key, this.editId});
  @override
  ConsumerState<TripSetupScreen> createState() => _TripSetupState();
}

class _TripSetupState extends ConsumerState<TripSetupScreen> {
  late TripBrief brief;
  late final TextEditingController hotel;
  int step = 0;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    final previous = widget.editId == null
        ? null
        : store.travelPlan(widget.editId!);
    final draft = previous?.brief.toJson() ?? store.state['tripDraft'];
    brief = draft is Map
        ? TripBrief.fromJson(Map<String, dynamic>.from(draft))
        : TripBrief(
            cityId: store.cityId,
            zone: store.planningCatalog.zones.first['id'],
            date: DateTime(
              store.cityNow().year,
              store.cityNow().month,
              store.cityNow().day + 1,
            ),
          );
    if (previous == null && draft is Map) {
      step = (draft['step'] as int? ?? 0).clamp(0, 2);
    }
    hotel = TextEditingController(text: brief.hotel);
  }

  @override
  void dispose() {
    hotel.dispose();
    super.dispose();
  }

  void update(Map<String, dynamic> values) => setState(
    () => brief = TripBrief.fromJson({...brief.toJson(), ...values}),
  );
  Future<void> next() async {
    setState(() => saving = true);
    final store = ref.read(storeProvider);
    final current = TripBrief.fromJson({
      ...brief.toJson(),
      'hotel': hotel.text.trim(),
    });
    if (step < 2) {
      final ok = await _save(
        context,
        () => store.saveTripDraft({...current.toJson(), 'step': step + 1}),
      );
      if (mounted) {
        setState(() {
          saving = false;
          if (ok) {
            brief = current;
            step++;
          }
        });
      }
    } else {
      final id = 'plan-${DateTime.now().microsecondsSinceEpoch}';
      final plan = TripPlanner(
        store.planningFor(current.cityId),
      ).generate(current, id: id);
      final ok = await _save(context, () => store.saveTravelPlan(plan));
      if (mounted) {
        setState(() => saving = false);
        if (ok) context.pushReplacement('/trip-plan/$id');
      }
    }
  }

  Future<void> pickTime(bool arrival) async {
    final minutes = arrival ? brief.arrival : brief.departure;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      update({
        arrival ? 'arrival' : 'departure': picked.hour * 60 + picked.minute,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    return PageFrame(
      title: 'План поездки',
      leading: BackButton(
        onPressed: saving
            ? null
            : () {
                if (step > 0) {
                  setState(() => step--);
                } else {
                  context.pop();
                }
              },
      ),
      footer: _action(
        saving
            ? 'Сохраняем…'
            : step == 2
            ? 'Собрать мой план'
            : 'Дальше',
        saving ? null : next,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ШАГ ${step + 1} ИЗ 3',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (step + 1) / 3,
            minHeight: 3,
            borderRadius: BorderRadius.circular(4),
          ),
          if (step == 0) ...[
            _heading(context, 'Куда и в каком ритме?'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: brief.cityId,
              decoration: const InputDecoration(labelText: 'Город поездки'),
              items: [
                for (final city in store.cities.values)
                  DropdownMenuItem(
                    value: city['id'] as String,
                    child: Text(city['name']),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                update({
                  'cityId': id,
                  'zone': store.planningFor(id).zones.first['id'],
                  'arrivalAt': 'hotel',
                  'hotel': '',
                });
                hotel.clear();
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Выберите настроение. Главные места можно совместить с едой, искусством и обычной жизнью города.',
            ),
            const SizedBox(height: 20),
            for (final vibe in _vibes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => update({'vibe': vibe.$1}),
                  child: Panel(
                    color: brief.vibe == vibe.$1
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: Row(
                      children: [
                        Icon(vibe.$4),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vibe.$2,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vibe.$3,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          brief.vibe == vibe.$1
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Section('Что точно хочется'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final interest in [
                  'История',
                  'Еда',
                  'Искусство',
                  'Море',
                  'Шопинг',
                  'Природа',
                ])
                  FilterChip(
                    label: Text(interest),
                    selected: brief.interests.contains(interest),
                    onSelected: (v) {
                      final values = [...brief.interests];
                      v ? values.add(interest) : values.remove(interest);
                      update({'interests': values});
                    },
                  ),
              ],
            ),
            const Section('Ваш темп'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final pace in [
                  ('calm', 'Без спешки'),
                  ('balanced', 'В самый раз'),
                  ('active', 'Хочу больше'),
                ])
                  ChoiceChip(
                    label: Text(pace.$2),
                    selected: brief.pace == pace.$1,
                    onSelected: (_) => update({'pace': pace.$1}),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Добавлять платные музеи'),
              subtitle: const Text('Билеты покупаете самостоятельно'),
              value: brief.tickets,
              onChanged: (v) => update({'tickets': v}),
            ),
          ],
          if (step == 1) ...[
            _heading(context, 'Где остановитесь?'),
            const Text(
              'Первый и последний день проведём рядом с вашим районом.',
            ),
            const SizedBox(height: 22),
            TextField(
              controller: hotel,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Название отеля · необязательно',
                hintText: 'Название вашего отеля',
              ),
            ),
            const Section('Район отеля'),
            RadioGroup<String>(
              groupValue: brief.zone,
              onChanged: (v) => update({'zone': v}),
              child: Column(
                children: [
                  for (final z in store.planningFor(brief.cityId).zones)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(z['name']),
                      value: z['id'],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const InfoLine(
              Icons.location_on_outlined,
              'Сейчас стартуем от центра выбранного района. Название отеля служит подписью — точный адрес не определяется.',
            ),
          ],
          if (step == 2) ...[
            _heading(context, 'Когда вы в городе?'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Первый день'),
              subtitle: Text(
                DateFormat('d MMMM yyyy', 'ru').format(brief.date),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final now = store.cityNow();
                final date = await showDatePicker(
                  context: context,
                  initialDate: brief.date,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2, 12, 31),
                );
                if (date != null && mounted) {
                  update({'date': date.toIso8601String()});
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Дней в городе')),
                IconButton(
                  tooltip: 'Меньше дней',
                  onPressed: brief.days > 2
                      ? () => update({'days': brief.days - 1})
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${brief.days}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  tooltip: 'Больше дней',
                  onPressed: brief.days < 7
                      ? () => update({'days': brief.days + 1})
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Section('Приезд'),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final arrival in [
                  ('hotel', 'Уже в районе отеля'),
                  for (final code
                      in store.cityFor(brief.cityId)['airports'] as List)
                    (code as String, 'Прилёт в $code'),
                ])
                  ChoiceChip(
                    label: Text(arrival.$2),
                    selected: brief.arrivalAt == arrival.$1,
                    onSelected: (_) => update({'arrivalAt': arrival.$1}),
                  ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                brief.arrivalAt == 'hotel' ? 'Буду у отеля' : 'Время прилёта',
              ),
              trailing: Text(
                planTime(brief.arrival),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => pickTime(true),
            ),
            Text(
              brief.arrivalAt == 'hotel'
                  ? 'Добавим 30 минут на заселение и отдых.'
                  : 'Оставим примерно 3 часа на выход из аэропорта, дорогу и заселение.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Section('Последний день'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.luggage_outlined),
              title: const Text('Выезжаю из отеля до'),
              trailing: Text(
                planTime(brief.departure),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => pickTime(false),
            ),
            Text(
              'Укажите выезд из отеля, а не время рейса. До этого вернёмся за вещами с запасом 30 минут.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const Panel(
              child: InfoLine(
                Icons.directions_transit_outlined,
                'Передвижение своим ходом: пешком, метро, трамваи, автобусы и паромы. Без машины и экскурсий.',
              ),
            ),
            if (widget.editId != null)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  'Сохраним новый вариант поездки. Предыдущий план и его отметки останутся в «Моих поездках».',
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class TripPlanScreen extends ConsumerWidget {
  final String id;
  const TripPlanScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider),
        plan = ref.watch(storeProvider).travelPlan(id);
    if (plan == null) return _notFound(context);
    final b = plan.brief;
    return PageFrame(
      title: 'Ваша поездка',
      leading: const BackButton(),
      actions: [
        IconButton(
          tooltip: 'Изменить условия поездки',
          onPressed: () => context.push('/plan-trip?from=$id'),
          icon: const Icon(Icons.tune_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(
            plan.days.expand((d) => d.stops).firstOrNull?.poi.data['image'] ??
                'assets/images/city.jpg',
            height: 210,
          ),
          const SizedBox(height: 16),
          Tag('Демо-план · ${store.cityFor(b.cityId)['name']}'),
          _heading(
            context,
            '${store.cityFor(b.cityId)['name']} на ${_days(b.days)}',
          ),
          Text(
            '${_date(b.date)} — ${_date(plan.days.last.date)} · ${_vibe(b.vibe)}',
          ),
          const SizedBox(height: 10),
          InfoLine(
            Icons.hotel_outlined,
            b.hotel.isEmpty
                ? store.planningFor(b.cityId).zone(b.zone)['name']
                : '${b.hotel} · ${store.planningFor(b.cityId).zone(b.zone)['name']}',
          ),
          const SizedBox(height: 18),
          for (final day in plan.days)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/trip-day/$id/${day.index}'),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Tag(
                                'День ${day.index + 1} · ${_date(day.date)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        day.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(day.subtitle),
                      const SizedBox(height: 12),
                      Text(
                        day.stops.isEmpty
                            ? 'Без прогулки — время на дорогу и отдых'
                            : '${planTime(day.stops.first.start)}–${planTime(day.returnAt)} · ${_places(day.stops.length)} · ≈ ${(day.walkMeters / 1000).toStringAsFixed(1)} км пешком',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (day.visited > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Посещено ${day.visited} из ${day.stops.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const DetailsFold(
            'Как устроен план',
            children: [
              Text(
                'Это готовый пример на локальных данных. Время переездов, очередей и прогулок ориентировочное; пробки, праздники, погода и наличие билетов не проверяются. Обычные выходные музеев учтены. Перед платным визитом проверьте часы и купите билет самостоятельно. Название отеля не задаёт точный адрес: расчёт идёт от центра района. Маршруты транспорта и отправления уточняйте в картах.',
              ),
              SizedBox(height: 12),
              Text(
                'Заказ еды, покупки и билеты — по желанию. Бесплатные остановки можно пройти без расходов; транспорт оплачивается отдельно.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TripDayScreen extends ConsumerStatefulWidget {
  final String id;
  final int dayIndex;
  const TripDayScreen({super.key, required this.id, required this.dayIndex});
  @override
  ConsumerState<TripDayScreen> createState() => _TripDayState();
}

class _TripDayState extends ConsumerState<TripDayScreen> {
  bool saving = false;
  Future<void> maps(PlanPoi p) async {
    try {
      final ok = await launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${p.lat},${p.lon}',
        }),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(p.data['address'])));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(p.data['address'])));
      }
    }
  }

  void info(ScheduledStop stop) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (c) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Photo(stop.poi.data['image'], height: 180),
          const SizedBox(height: 8),
          Text(
            stop.poi.data['imageCaption'] ??
                'Фотография места или его окрестностей',
            style: Theme.of(c).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Tag(stop.poi.kind),
          _heading(c, stop.poi.name),
          Text(stop.poi.data['description']),
          const SizedBox(height: 16),
          Text(
            stop.poi.data['address'],
            style: Theme.of(c).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          InfoLine(
            Icons.schedule,
            '${planTime(stop.start)}–${planTime(stop.end)} · примерное время',
          ),
          Text(
            stop.poi.paid
                ? 'Нужен отдельный билет. Время входа не забронировано.'
                : 'Без обязательных билетов; покупки и еда по желанию.',
          ),
          const SizedBox(height: 18),
          _action('Открыть место в картах', () => maps(stop.poi)),
        ],
      ),
    ),
  );
  Future<void> perform(Future<void> Function() action) async {
    setState(() => saving = true);
    await _save(context, action);
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final plan = store.travelPlan(widget.id);
    if (plan == null ||
        widget.dayIndex < 0 ||
        widget.dayIndex >= plan.days.length) {
      return _notFound(context);
    }
    final day = plan.days[widget.dayIndex];
    final current = day.stops.where((s) => !s.done).firstOrNull;
    final nextIndex = current == null ? -1 : day.stops.indexOf(current);
    return PageFrame(
      title: 'День ${day.index + 1} · ${_date(day.date)}',
      leading: const BackButton(),
      footer: day.stops.isEmpty
          ? null
          : _action(
              saving
                  ? 'Сохраняем…'
                  : !day.started
                  ? 'Начать этот день'
                  : current == null
                  ? 'День сохранён · к плану'
                  : 'Отметить посещение',
              saving
                  ? null
                  : () {
                      if (!day.started) {
                        perform(
                          () => store.startPlannedDay(widget.id, day.index),
                        );
                      } else if (current != null) {
                        perform(
                          () => store.markPlannedStop(
                            widget.id,
                            day.index,
                            nextIndex,
                            true,
                          ),
                        );
                      } else {
                        context.pop();
                      }
                    },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context, day.title),
          Text(day.subtitle),
          const SizedBox(height: 16),
          if (day.stops.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(_places(day.stops.length)),
                Text(
                  '≈ ${(day.walkMeters / 1000).toStringAsFixed(1)} км пешком',
                ),
                if (day.started)
                  Text('${day.visited}/${day.stops.length} посещено'),
              ],
            ),
          if (day.started && current != null) ...[
            const SizedBox(height: 20),
            Text(
              'Сейчас: ${current.poi.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (current.transport == 'Пешком') ...[
              const SizedBox(height: 12),
              WalkNavigationMap(
                key: ValueKey('plan-map-${widget.id}-${day.index}'),
                tripId: '${widget.id}-${day.index}',
                destinationId: current.poi.id,
                destinationName: current.poi.name,
                destination: LatLng(current.poi.lat, current.poi.lon),
                visited: [
                  for (final s in day.stops.where((s) => s.done))
                    LatLng(s.poi.lat, s.poi.lon),
                ],
                db: store.db!,
                environment: ref.read(navigationEnvironmentProvider),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoLine(
                      Icons.directions_transit_outlined,
                      current.transport,
                    ),
                    Text(
                      'Это переезд, а не пеший участок. Рейс и точную дорогу уточните в картах.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => maps(current.poi),
                      child: const Text('Открыть место в картах'),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < day.stops.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Text(
                '≈ ${day.stops[i].travel} мин · ${day.stops[i].transport}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => info(day.stops[i]),
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Photo(
                          day.stops[i].poi.data['image'] as String? ?? '',
                          height: 160,
                          radius: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                child: day.stops[i].done
                                    ? const Icon(Icons.check, size: 20)
                                    : Text('${i + 1}'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${planTime(day.stops[i].start)}–${planTime(day.stops[i].end)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      day.stops[i].poi.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${day.stops[i].poi.area}${day.stops[i].poi.paid ? ' · нужен билет' : ''}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (day.stops[i].done)
                                      TextButton(
                                        onPressed: saving
                                            ? null
                                            : () => perform(
                                                () => store.markPlannedStop(
                                                  widget.id,
                                                  day.index,
                                                  i,
                                                  false,
                                                ),
                                              ),
                                        child: const Text('Убрать отметку'),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i == 1 &&
                day.stops.length > 2 &&
                day.index > 0 &&
                day.index < plan.days.length - 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: InfoLine(
                  Icons.restaurant_outlined,
                  '45 минут на обед + паузы между местами',
                ),
              ),
          ],
          if (day.stops.isNotEmpty)
            InfoLine(
              Icons.hotel_outlined,
              '≈ ${day.returnMinutes} мин обратно в район отеля · к ${planTime(day.returnAt)}',
            ),
          if (day.notes.isNotEmpty)
            DetailsFold(
              day.stops.isEmpty
                  ? 'Почему без остановок'
                  : 'Что учтено в этот день',
              initiallyExpanded: day.stops.isEmpty,
              children: [
                for (final note in day.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(note),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            'Время — ориентир, а не бронь. Старт и финиш считаем от центра района отеля.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
