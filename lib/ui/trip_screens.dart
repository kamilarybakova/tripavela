part of 'screens.dart';

extension _TripScreens on _TravelScreenState {
  Widget placePractical(Place p, {int? minutes}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Section(copy.placePracticalTitle),
      InfoLine(Icons.schedule, '${minutes ?? p.visitMinutes} мин · ${p.hours}'),
      InfoLine(Icons.payments_outlined, p.cost),
      InfoLine(Icons.accessible_outlined, p.access),
      InfoLine(Icons.door_front_door_outlined, p.booking),
      Section(copy.placeSourceLabel),
      Text(
        copy.placeCheckedLabel,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      for (final url in p.sources)
        TextButton.icon(
          onPressed: () async {
            try {
              if (!await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ) &&
                  mounted) {
                message(copy.message272);
              }
            } catch (_) {
              if (mounted) message(copy.message272);
            }
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(Uri.parse(url).host),
        ),
      Text(copy.sourcesOffline, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
  Map<String, dynamic> get currentStop =>
      Map<String, dynamic>.from(trip['stops'][trip['index']]);
  Place get currentPlace => store.places[currentStop['place']]!;
  String get progressText => copy.message249(
    (store.visitedCount(trip)).toString(),
    (store.skippedCount(trip)).toString(),
    (4 - store.visitedCount(trip) - store.skippedCount(trip)).toString(),
  );
  Widget tripProgress({bool compact = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        copy.message250(((trip['index'] as int) + 1).toString()),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      SizedBox(height: 10),
      Row(
        children: List.generate(4, (i) {
          final stops = trip['stops'] as List;
          final status = i < stops.length ? stops[i]['result'] : 'waiting';
          final current = trip['index'] == i;
          return Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
              decoration: BoxDecoration(
                color: status == 'visited'
                    ? Theme.of(context).colorScheme.primary
                    : status == 'skipped'
                    ? Palette.muted
                    : current
                    ? Palette.gold
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: status == 'skipped'
                  ? Center(
                      child: Text(
                        '−',
                        style: TextStyle(
                          fontSize: 8,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
      SizedBox(height: 10),
      if (!compact) Text(progressText, style: TextStyle(fontSize: 12)),
    ],
  );
  Widget activeTrip() {
    if (trip['status'] == 'paused') return pausePage();
    if (trip['ended'] != null) return summary();
    final p = currentPlace;
    return PageFrame(
      title: store.route(trip['routeId']).name,
      leading: IconButton(
        tooltip: copy.message251,
        onPressed: () => context.go('/home'),
        icon: Icon(Icons.keyboard_arrow_down),
      ),
      actions: [
        IconButton(
          tooltip: copy.message252,
          onPressed: tripMenu,
          icon: Icon(Icons.more_horiz),
        ),
      ],
      footer: button(
        currentStop['result'] == 'visited' ? copy.message021 : copy.message253,
        () async {
          if (currentStop['result'] == 'visited') {
            open('s14', id: widget.id);
          } else if (await act(() => store.arrive(widget.id!)) && mounted) {
            open('s14', id: widget.id);
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tripProgress(compact: true),
          const SizedBox(height: 8),
          Text(p.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          WalkNavigationMap(
            key: ValueKey('navigation-${widget.id}'),
            tripId: widget.id!,
            destinationId: p.id,
            destinationName: p.name,
            destination: LatLng(
              (p.data['lat'] as num).toDouble(),
              (p.data['lon'] as num).toDouble(),
            ),
            visited: [
              for (final stop in (trip['stops'] as List).where(
                (s) => s['result'] == 'visited' && s['place'] != p.id,
              ))
                LatLng(
                  (store.places[stop['place']]!.data['lat'] as num).toDouble(),
                  (store.places[stop['place']]!.data['lon'] as num).toDouble(),
                ),
            ],
            db: store.db!,
            environment: ref.read(navigationEnvironmentProvider),
            enabled: currentStop['result'] != 'visited',
            indoors: trip['snapshot']['indoor'] == true,
            needsStepFree:
                trip['filters']['noStairs'] == true ||
                trip['filters']['stroller'] == true,
          ),
          SizedBox(height: 20),
          if (store.demo['closed'] == true ||
              store.demo['weather'] == true) ...[
            Panel(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.demo['closed'] == true
                        ? copy.message254
                        : copy.message255,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: offerReplacement,
                    child: Text(copy.message256),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          Text(
            '${trip['snapshot']['stopMinutes'] ?? p.visitMinutes} мин на месте',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          DetailsFold(
            'О месте',
            children: [
              Photo(p.image, height: 180),
              const SizedBox(height: 12),
              Text(p.address),
              const SizedBox(height: 12),
              bodyText(p.notice),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => openMaps(p),
                icon: const Icon(Icons.near_me_outlined, size: 18),
                label: Text(copy.message268),
              ),
              placePractical(
                p,
                minutes: trip['snapshot']['stopMinutes'] as int?,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: offerReplacement, child: Text(copy.message270)),
          TextButton(onPressed: skipStop, child: Text(copy.message271)),
        ],
      ),
    );
  }

  Future<void> openMaps(Place place) async {
    bool ok = false;
    try {
      if (store.demo['mapsError'] != true) {
        ok = await launchUrl(
          Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': place.address,
          }),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      await sheet(copy.message272, [
        Text(place.address),
        SizedBox(height: 16),
        button(copy.message273, () async {
          await Clipboard.setData(ClipboardData(text: place.address));
          if (mounted) {
            context.pop();
            message(copy.message274);
          }
        }),
      ]);
    }
  }

  Future<void> tripMenu() async {
    await sheet(copy.message275, [
      ListTile(
        leading: Icon(Icons.route_outlined),
        title: Text(copy.message276),
        onTap: () {
          context.pop();
          open('s13', id: widget.id);
        },
      ),
      ListTile(
        leading: Icon(Icons.pause_circle_outline),
        title: Text(copy.message277),
        onTap: () async {
          context.pop();
          if (await act(() => store.pause(widget.id!)) && mounted) {
            open('s18', id: widget.id);
          }
        },
      ),
      ListTile(
        leading: Icon(Icons.flag_outlined),
        title: Text(copy.message278),
        onTap: () {
          context.pop();
          missionSettings();
        },
      ),
      ListTile(
        leading: Icon(Icons.visibility_outlined),
        title: Text(copy.message279),
        onTap: () async {
          context.pop();
          if (await confirm(
            copy.message280,
            copy.message281,
            yes: copy.message282,
          )) {
            await act(() => store.reveal(widget.id!), success: copy.message283);
          }
        },
      ),
      Divider(),
      ListTile(
        textColor: Theme.of(context).colorScheme.error,
        leading: Icon(Icons.stop_circle_outlined),
        title: Text(copy.message284),
        onTap: () {
          context.pop();
          endTrip();
        },
      ),
    ]);
  }

  Future<void> missionSettings() async {
    final filters = Map<String, dynamic>.from(trip['filters']);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.message285, style: Theme.of(c).textTheme.titleLarge),
              SwitchListTile(
                title: Text(copy.message145),
                value: filters['noMissions'] == true,
                onChanged: (v) => update(() => filters['noMissions'] = v),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in [
                    copy.message142,
                    copy.message143,
                    copy.message144,
                  ])
                    FilterChip(
                      label: Text(type),
                      selected: (filters['missions'] as List).contains(type),
                      onSelected: (v) => update(() {
                        v
                            ? (filters['missions'] as List).add(type)
                            : (filters['missions'] as List).remove(type);
                      }),
                    ),
                ],
              ),
              SizedBox(height: 16),
              button(copy.message286, () async {
                if (await act(
                      () => store.mutateTrip(
                        widget.id!,
                        (t, s) => t['filters'] = filters,
                      ),
                    ) &&
                    c.mounted) {
                  Navigator.pop(c);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> endTrip() async {
    if (await confirm(copy.message287, copy.message219, yes: copy.message288)) {
      if (await act(() => store.end(widget.id!)) && mounted) {
        context.pushReplacement('/s19?id=${widget.id}');
      }
    }
  }

  Future<void> skipStop() async {
    String reason = copy.message289;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.message290, style: Theme.of(c).textTheme.titleLarge),
              SizedBox(height: 12),
              Text(copy.message291),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in [
                    copy.message289,
                    copy.message292,
                    copy.message029,
                    copy.message293,
                    copy.message294,
                  ])
                    ChoiceChip(
                      label: Text(value),
                      selected: reason == value,
                      onSelected: (_) => update(() => reason = value),
                    ),
                ],
              ),
              SizedBox(height: 20),
              button(copy.message046, () async {
                Navigator.pop(c);
                await nextStop(skip: true, reason: reason);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> nextStop({bool skip = false, String? reason}) async {
    bool fork = false;
    if (await act(() async {
          fork = await store.advance(widget.id!, skip: skip, reason: reason);
        }) &&
        mounted) {
      final current = store.session(widget.id!);
      context.pushReplacement(
        '/${fork
            ? 's16'
            : current['ended'] != null
            ? 's19'
            : 's12'}?id=${widget.id}',
      );
    }
  }

  Widget stops() {
    final entries = trip['stops'] as List;
    final labels = [
      for (var i = 0; i < entries.length; i++)
        if (entries[i]['visible'] == true)
          store.places[entries[i]['place']]!.name,
    ];
    return PageFrame(
      title: copy.message276,
      leading: backButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(store.route(trip['routeId']).name),
          tripProgress(),
          SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(copy.message295),
                icon: Icon(Icons.list),
              ),
              ButtonSegment(
                value: true,
                label: Text(copy.message296),
                icon: Icon(Icons.route_outlined),
              ),
            ],
            selected: {scheme},
            onSelectionChanged: (v) => updateUi(() => scheme = v.first),
          ),
          SizedBox(height: 20),
          if (scheme)
            RouteSketch(labels)
          else ...[
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(
                      entries[i]['visible'] == true
                          ? store.places[entries[i]['place']]!.name
                          : copy.message297((i + 1).toString()),
                    ),
                    subtitle: Text(
                      copy.message298(
                        (stopLabel(entries[i]['result'])).toString(),
                      ),
                    ),
                    trailing: Icon(
                      entries[i]['visible'] == true
                          ? Icons.chevron_right
                          : Icons.lock_outline,
                    ),
                    onTap: () {
                      if (entries[i]['result'] == 'visited') {
                        open('s14', id: widget.id, extra: '$i');
                      } else if (i == trip['index']) {
                        open('s12', id: widget.id);
                      } else if (entries[i]['visible'] != true) {
                        message(copy.message299);
                      } else {
                        showRevealedPlace(entries[i]['place']);
                      }
                    },
                  ),
                ),
              ),
            if (trip['branch'] == null)
              Panel(child: InfoLine(Icons.alt_route, copy.message300)),
          ],
        ],
      ),
    );
  }

  String stopLabel(String value) => switch (value) {
    'visited' => copy.message301,
    'skipped' => copy.message302,
    'current' => copy.message303,
    'replaced' => copy.message304,
    _ => copy.message305,
  };
  Future<void> showRevealedPlace(String id) async {
    final p = store.places[id]!;
    await sheet(p.name, [
      Photo(p.image),
      SizedBox(height: 16),
      Text(p.address),
      Text(p.notice),
      SizedBox(height: 12),
      Text(copy.message306),
    ]);
  }

  int get storyIndex => widget.extra != null
      ? int.tryParse(widget.extra!) ?? trip['index']
      : trip['index'];
  Place get storyPlace => store.places[trip['stops'][storyIndex]['place']]!;
  bool get hasMission =>
      trip['filters']['noMissions'] != true &&
      (trip['filters']['missions'] as List).contains(storyPlace.missionType) &&
      storyIndex < 3;
  Map<String, dynamic>? visitFor(String place) => store.visits
      .where((v) => v['trip'] == widget.id && v['place'] == place)
      .firstOrNull;
  Widget story() {
    final p = storyPlace;
    final current = storyIndex == trip['index'] && trip['ended'] == null;
    final visit = visitFor(p.id);
    return PageFrame(
      title: copy.message307((storyIndex + 1).toString()),
      leading: backButton(),
      actions: [
        IconButton(
          tooltip: copy.placeMenu,
          icon: const Icon(Icons.more_horiz),
          onPressed: () => sheet(copy.placeMenu, [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(copy.message315),
              onTap: visit == null
                  ? null
                  : () {
                      context.pop();
                      open('note', id: visit['id']);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: Text(copy.message315),
              onTap: visit == null
                  ? null
                  : () {
                      context.pop();
                      addPhoto(visit['id']);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.near_me_outlined),
              title: Text(copy.message268),
              onTap: () {
                context.pop();
                openMaps(p);
              },
            ),
          ]),
        ),
      ],

      footer: current
          ? button(
              storyIndex == 1 && trip['branch'] == null
                  ? copy.message308
                  : storyIndex == (trip['stops'] as List).length - 1 &&
                        trip['branch'] != null
                  ? copy.message284
                  : hasMission
                  ? copy.message021
                  : copy.message309,
              () => nextStop(),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(p.image, height: 240),
          Text(
            p.data['imageCaption'] as String? ?? copy.placeImageCaption,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 18),
          Tag(p.category),
          title(p.name),
          bodyText(p.story.split('\n\n').first),
          if (p.story.contains('\n\n'))
            DetailsFold(
              'Подробнее о месте',
              children: [bodyText(p.story.split('\n\n').skip(1).join('\n\n'))],
            ),
          DetailsFold(
            'Что попробовать',
            children: [bodyText(p.tryIt), bodyText(p.notice)],
          ),
          DetailsFold(
            'Адрес и детали',
            children: [
              Text(p.address),
              placePractical(
                p,
                minutes: trip['snapshot']['stopMinutes'] as int?,
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: visit == null
                    ? null
                    : () => open('note', id: visit['id']),
                icon: Icon(Icons.edit_note),
                label: Text(copy.message314),
              ),
              OutlinedButton.icon(
                onPressed: visit == null ? null : () => addPhoto(visit['id']),
                icon: Icon(Icons.add_a_photo_outlined),
                label: Text(copy.message315),
              ),
            ],
          ),
          if (hasMission) ...[
            Section(copy.message316),
            Panel(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.mission,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${p.missionCategory} · ≈ ${p.missionMinutes} мин'),
                  Text(
                    p.missionPurchaseOptional
                        ? copy.message318
                        : copy.message171,
                  ),
                  TextButton(
                    onPressed: () =>
                        open('s15', id: widget.id, extra: '$storyIndex'),
                    child: Text(copy.message319),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget mission() {
    final p = storyPlace;
    final stop = trip['stops'][storyIndex];
    final done = stop['mission'] != 'available';
    final visit = visitFor(p.id);
    return PageFrame(
      title: copy.message316,
      leading: backButton(),
      footer: done
          ? button(copy.message320, () => context.pop())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(copy.message321, () async {
                  if (await act(
                        () => store.mutateTrip(widget.id!, (t, s) {
                          t['stops'][storyIndex]['mission'] = 'done';
                          if (missionNote != null && visit != null) {
                            (s['visits'] as List).firstWhere(
                              (v) => v['id'] == visit['id'],
                            )['note'] = missionNote;
                          }
                        }, event: 'mission_completed'),
                        success: copy.message322,
                      ) &&
                      mounted) {
                    context.pop();
                  }
                }),
                TextButton(
                  onPressed: () async {
                    if (await act(
                          () => store.mutateTrip(widget.id!, (t, s) {
                            t['stops'][storyIndex]['mission'] = 'skipped';
                            if (missionNote != null && visit != null) {
                              (s['visits'] as List).firstWhere(
                                (v) => v['id'] == visit['id'],
                              )['note'] = missionNote;
                            }
                          }, event: 'mission_skipped'),
                        ) &&
                        mounted) {
                      context.pop();
                    }
                  },
                  child: Text(copy.message323),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag(p.missionCategory, gold: true),
          title(p.mission),
          bodyText(p.data['missionDetails'] as String? ?? p.tryIt),
          Text(
            '≈ ${p.missionMinutes} мин · можно пропустить',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            p.missionPurchaseOptional
                ? (p.missionCategory == 'Транспорт'
                      ? 'Проезд оплачивается отдельно.'
                      : 'Покупка по желанию. Цену и состав уточните при заказе.')
                : 'Без обязательных расходов',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (p.missionFreeAlternative.isNotEmpty) ...[
            const SizedBox(height: 16),
            DetailsFold(
              'Без покупки',
              initiallyExpanded: trip['filters']['budget'] == 0,
              children: [bodyText(p.missionFreeAlternative)],
            ),
          ],
          const SizedBox(height: 20),
          if (done)
            Panel(
              child: InfoLine(
                stop['mission'] == 'done'
                    ? Icons.check_circle_outline
                    : Icons.skip_next_outlined,
                stop['mission'] == 'done' ? copy.message322 : copy.message330,
              ),
            ),
          DetailsFold(
            copy.message331,
            children: [
              if (visit != null) ...[
                TextFormField(
                  initialValue: visit['note'],
                  readOnly: done,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(labelText: copy.message314),
                  onChanged: (value) => missionNote = value,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: visit == null
                        ? null
                        : () => open('note', id: visit['id']),
                    icon: const Icon(Icons.edit_note),
                    label: Text(copy.message314),
                  ),
                  OutlinedButton.icon(
                    onPressed: visit == null
                        ? null
                        : () => addPhoto(visit['id']),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(copy.message315),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget branch() {
    final unavailable =
        store.demo['noAlternatives'] == true && store.demo['closed'] == true;
    return PageFrame(
      title: copy.message333,
      leading: IconButton(
        tooltip: copy.message036,
        onPressed: () => context.go('/home'),
        icon: Icon(Icons.close),
      ),
      footer: unavailable
          ? button(copy.message284, endTrip)
          : button(
              copy.message334,
              selection < 0
                  ? null
                  : () async {
                      if (await act(
                            () => store.branch(widget.id!, selection),
                          ) &&
                          mounted) {
                        context.pushReplacement('/s12?id=${widget.id}');
                      }
                    },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(copy.message335),
          bodyText(unavailable ? copy.message336 : copy.message337),
          if (!unavailable)
            for (var i = 0; i < 2; i++)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Semantics(
                  selected: selection == i,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => updateUi(() => selection = i),
                    child: Panel(
                      color: selection == i
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                i == 0
                                    ? Icons.spa_outlined
                                    : Icons.auto_awesome_outlined,
                              ),
                              Spacer(),
                              Icon(
                                selection == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          Text(
                            trip['snapshot']['branchHints'][i]['title']
                                as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 10),
                          Text(
                            trip['snapshot']['branchHints'][i]['description']
                                as String,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '+${trip['snapshot']['branchDelta'][i]['minutes']} мин · +${trip['snapshot']['branchDelta'][i]['meters']} м · без обязательных расходов',
                          ),
                          Text(
                            trip['snapshot']['stairs'] == 'no'
                                ? copy.message229
                                : copy.message343,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> offerReplacement({bool editing = false}) async {
    var reason = replacementReason;
    var comment = noteDraft;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.replacementReason,
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: reason,
                  onChanged: (v) => update(() => reason = v!),
                  child: Column(
                    children: [
                      for (final value in [
                        copy.message029,
                        copy.message348,
                        copy.message349,
                        copy.message350,
                        copy.message351,
                        copy.message294,
                      ])
                        RadioListTile<String>(value: value, title: Text(value)),
                    ],
                  ),
                ),
                TextFormField(
                  initialValue: comment,
                  decoration: InputDecoration(labelText: copy.message352),
                  onChanged: (v) => comment = v,
                ),
                const SizedBox(height: 16),
                button(copy.showAlternatives, () {
                  Navigator.pop(c);
                  if (editing) {
                    updateUi(() {
                      replacementReason = reason;
                      noteDraft = comment;
                    });
                  } else {
                    open(
                      's17',
                      id: widget.id,
                      extra: Uri.encodeComponent('$reason|$comment'),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget replacement() {
    final alternative = trip['snapshot']['alternative'] as String;
    final no =
        store.demo['noAlternatives'] == true ||
        alternative == currentStop['place'];
    return PageFrame(
      title: copy.message344,
      leading: backButton(),
      footer: no
          ? null
          : button(
              copy.message345,
              selection < 0
                  ? null
                  : () async {
                      if (await act(
                            () => store.replace(
                              widget.id!,
                              alternative,
                              noteDraft.trim().isEmpty
                                  ? replacementReason
                                  : '$replacementReason: ${noteDraft.trim()}',
                            ),
                          ) &&
                          mounted) {
                        context.pushReplacement('/s12?id=${widget.id}');
                      }
                    },
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(copy.message346),
          Tag(replacementReason),
          TextButton(
            onPressed: () => offerReplacement(editing: true),
            child: Text(copy.changeReason),
          ),
          Section(copy.message353),
          if (no) ...[
            bodyText(copy.message354),
            button(
              copy.message355,
              () => nextStop(skip: true, reason: replacementReason),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(copy.message022),
            ),
            TextButton(onPressed: endTrip, child: Text(copy.message284)),
          ] else
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => updateUi(() => selection = 0),
              child: Panel(
                color: selection == 0
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip['reveal'] == true
                                ? store.places[alternative]!.name
                                : copy.message356,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Icon(
                          selection == 0
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(copy.message357),
                    InfoLine(Icons.schedule, copy.message358),
                    InfoLine(
                      Icons.directions_walk,
                      copy.replacementDistance(
                        (store.replacementMetrics(trip)['meters']! / 1000)
                            .toStringAsFixed(1),
                      ),
                    ),
                    InfoLine(Icons.payments_outlined, copy.message360),
                    Text(store.places[alternative]!.access),
                    if ((trip['snapshot']['minutes'] as int) + 35 >
                        (trip['filters']['time'] as int))
                      Text(copy.message363),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget pausePage() => PageFrame(
    title: copy.message364,
    leading: IconButton(
      tooltip: copy.message036,
      onPressed: () => context.go('/home'),
      icon: Icon(Icons.close),
    ),
    footer: button(copy.message365, () async {
      if (await act(() => store.resume(widget.id!)) && mounted) {
        if (store.cityNow().hour > (trip['snapshot']['lastStart'] as int) ||
            store.demo['late'] == true) {
          message(copy.message366);
          context.pushReplacement('/s17?id=${widget.id}');
        } else {
          context.pushReplacement('/s12?id=${widget.id}');
        }
      }
    }),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40),
        Icon(
          Icons.pause_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        title(copy.message367),
        bodyText(store.route(trip['routeId']).name),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(progressText),
              SizedBox(height: 12),
              InfoLine(Icons.check_circle_outline, copy.message368),
            ],
          ),
        ),
        SizedBox(height: 24),
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text(copy.message369),
        ),
        TextButton(onPressed: endTrip, child: Text(copy.message284)),
      ],
    ),
  );
  Widget summary() {
    final t = trip;
    final count = store.visitedCount(t);
    final visited = (t['stops'] as List)
        .where((s) => s['result'] == 'visited')
        .toList();
    final missions = (t['stops'] as List)
        .where((s) => s['mission'] == 'done')
        .length;
    return PageFrame(
      title: copy.message370,
      leading: IconButton(
        tooltip: copy.message036,
        onPressed: () => context.go('/home'),
        icon: Icon(Icons.close),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(copy.message371, () => context.go('/atlas')),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(copy.message372),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tag(copy.message373, gold: true),
          title(
            t['status'] == 'completed'
                ? copy.message374
                : count == 0
                ? copy.message375
                : copy.message376,
          ),
          bodyText(store.route(t['routeId']).name),
          Text(dateLabel(t['started'])),
          SizedBox(height: 20),
          Panel(
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                metric('$count', copy.message377),
                metric('$missions', copy.message378),
                metric(
                  copy.message379((store.elapsedMinutes(t)).toString()),
                  copy.message380,
                ),
                metric(
                  copy.message246((estimatedDistance(t)).toString()),
                  copy.message381,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          if (count > 0) ...[
            RouteSketch([
              for (final stop in visited) store.places[stop['place']]!.name,
            ]),
            Section(copy.message382),
            for (final stop in visited)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Photo(store.places[stop['place']]!.image, height: 160),
                      SizedBox(height: 12),
                      Text(
                        store.places[stop['place']]!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            SizedBox(height: 16),
            bodyText(copy.message383),
          ],
          DetailsFold(
            'Оценить прогулку',
            children: [
              Section(copy.message384),
              Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  for (var i = 1; i <= 5; i++)
                    ChoiceChip(
                      label: Text(
                        [
                          copy.message385,
                          copy.message386,
                          copy.message387,
                          copy.message388,
                          copy.message389,
                        ][i - 1],
                      ),
                      selected: t['rating'] == i,
                      onSelected: (_) => act(
                        () => store.mutateTrip(
                          widget.id!,
                          (t, s) => t['rating'] = i,
                          event: 'feedback_saved',
                        ),
                      ),
                    ),
                ],
              ),
              if ((t['rating'] as int) > 0) ...[
                Section(copy.message390),
                feedbackChips('liked', [
                  copy.message391,
                  copy.message392,
                  copy.message393,
                  copy.message394,
                ]),
                Section(copy.message395),
                feedbackChips('improve', [
                  copy.message175,
                  copy.message396,
                  copy.message397,
                  copy.message327,
                ]),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: t['feedback']['comment'] ?? '',
                  maxLines: 3,
                  decoration: InputDecoration(labelText: copy.message352),
                  onChanged: (v) => noteDraft = v,
                ),
                TextButton(
                  onPressed: () => act(
                    () => store.mutateTrip(
                      widget.id!,
                      (t, s) => t['feedback']['comment'] = noteDraft,
                    ),
                    success: copy.message398,
                  ),
                  child: Text(copy.message399),
                ),
              ],
              Section(copy.message400),
              feedbackChips('time', [
                copy.message401,
                copy.message402,
                copy.message403,
              ], single: true),
              Section(copy.message404),
              feedbackChips('cost', [
                copy.message401,
                copy.message405,
                copy.message406,
                copy.message407,
              ], single: true),
              SizedBox(height: 12),
              Text(copy.message408),
            ],
          ),
        ],
      ),
    );
  }

  Widget metric(String value, String label) => SizedBox(
    width: 135,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    ),
  );
  String estimatedDistance(Map<String, dynamic> t) =>
      (store.visitedMeters(t) / 1000).toStringAsFixed(1);
  Widget feedbackChips(String key, List<String> values, {bool single = false}) {
    final selected = trip['feedback'][key] as List? ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            onSelected: (v) => act(
              () => store.mutateTrip(widget.id!, (t, s) {
                final list = List<String>.from(t['feedback'][key] ?? []);
                if (single) list.clear();
                v ? list.add(value) : list.remove(value);
                t['feedback'][key] = list;
              }),
            ),
          ),
      ],
    );
  }
}
