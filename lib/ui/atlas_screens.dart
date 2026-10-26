part of 'screens.dart';

extension _AtlasScreens on _TravelScreenState {
  List<Map<String, dynamic>> get atlasEntries {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final visit in store.visits) {
      if (visit['hidden'] == true) continue;
      groups.putIfAbsent(visit['place'], () => []).add(visit);
    }
    return [
      for (final item in groups.entries)
        {'place': item.key, 'visits': item.value, 'last': item.value.last},
    ];
  }

  Widget atlas() {
    final all = atlasEntries;
    final entries = all.where((e) {
      final p = store.places[e['place']]!;
      return (themeFilter == copy.message027 || p.category == themeFilter) &&
          ('${p.name} ${(e['visits'] as List).map((v) => v['note']).join(' ')}')
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();
    return PageFrame(
      controller: scrollController,
      title: copy.message409,
      actions: [
        IconButton(
          tooltip: copy.message410,
          onPressed: () => open('s22'),
          icon: Icon(Icons.history),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: metricSmall('${all.length}', copy.message411)),
                Expanded(
                  child: metricSmall(
                    '${all.map((e) => store.cityForPlace(e['place'])).toSet().length}',
                    copy.message412,
                  ),
                ),
                Expanded(
                  child: metricSmall(
                    '${store.sessions.where((t) => t['ended'] != null).length}',
                    copy.message413,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: copy.message414,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => updateUi(() => query = v),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const Tag('Все города'),
              for (final tag in [
                copy.message027,
                ...all.map((e) => store.places[e['place']]!.category).toSet(),
              ])
                ChoiceChip(
                  label: Text(tag),
                  selected: themeFilter == tag,
                  onSelected: (_) => updateUi(() => themeFilter = tag),
                ),
            ],
          ),
          SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(copy.message416)),
              ButtonSegment(value: true, label: Text(copy.message296)),
            ],
            selected: {scheme},
            onSelectionChanged: (v) => updateUi(() => scheme = v.first),
          ),
          SizedBox(height: 20),
          if (all.isEmpty)
            EmptyView(
              title: copy.message417,
              text: copy.message418,
              button: copy.message419,
              onTap: () => context.go('/routes'),
            )
          else if (entries.isEmpty)
            EmptyView(
              title: copy.message420,
              text: copy.message421,
              button: copy.message168,
              onTap: () => updateUi(() {
                query = '';
                themeFilter = copy.message027;
              }),
            )
          else if (scheme)
            RouteSketch(
              entries.map((e) => store.places[e['place']]!.name).toList(),
            )
          else
            LayoutBuilder(
              builder: (c, b) {
                final columns = MediaQuery.textScalerOf(c).scale(16) > 22
                    ? 1
                    : 2;
                final width = (b.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: width,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => open('s21', id: entry['place']),
                          child: Panel(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (entry['last']['photos'] as List).isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: StoredPhoto(
                                          path: entry['last']['photos'].last,
                                          width: width - 20,
                                          height: 145,
                                        ),
                                      )
                                    : Photo(
                                        store.places[entry['place']]!.image,
                                        height: 145,
                                        radius: 14,
                                      ),
                                SizedBox(height: 12),
                                Text(
                                  store.places[entry['place']]!.name,
                                  style: Theme.of(c).textTheme.titleSmall,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  store.cityNameForPlace(entry['place']),
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  dateLabel(entry['last']['at']),
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if ((entry['visits'] as List).any(
                                      (v) => (v['note'] as String).isNotEmpty,
                                    ))
                                      Icon(Icons.notes, size: 16),
                                    if ((entry['visits'] as List).any(
                                      (v) => (v['photos'] as List).isNotEmpty,
                                    ))
                                      Icon(Icons.photo_outlined, size: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget metricSmall(String value, String label) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: TextStyle(fontSize: 12)),
    ],
  );
  Widget discovery() {
    final p = store.places[widget.id]!;
    final visits = store.visits.where((v) => v['place'] == p.id).toList();
    final last = visits.last;
    return PageFrame(
      title: copy.message422,
      leading: backButton(),
      actions: [
        IconButton(
          tooltip: copy.message423,
          onPressed: () async {
            if (await confirm(
              copy.message424,
              copy.message425,
              yes: copy.message426,
            )) {
              if (await act(
                    () => store.change((s) {
                      for (final v in s['visits']) {
                        if (v['place'] == p.id) v['hidden'] = true;
                      }
                    }),
                  ) &&
                  mounted) {
                context.pop();
              }
            }
          },
          icon: Icon(Icons.more_horiz),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Photo(p.image, height: 240),
          if ((last['photos'] as List).isNotEmpty) ...[
            SizedBox(height: 12),
            photoStrip(last),
          ],
          title(p.name),
          bodyText(copy.message427((p.address).toString())),
          Text(copy.message428((dateLabel(last['at'])).toString())),
          Section(copy.message429),
          bodyText(p.story),
          placePractical(p),
          Section(copy.message430),
          Text(p.mission),
          SizedBox(height: 8),
          Text(copy.message431),
          Section(copy.message432),
          Panel(
            child: Text(
              (last['note'] as String).isEmpty ? copy.message433 : last['note'],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => open('note', id: last['id']),
                icon: Icon(Icons.edit_note),
                label: Text(copy.message434),
              ),
              if ((last['note'] as String).isNotEmpty)
                TextButton(
                  onPressed: () async {
                    if (await confirm(
                      copy.message435,
                      copy.message436,
                      yes: copy.message437,
                    )) {
                      await act(
                        () => store.note(last['id'], ''),
                        success: copy.message438,
                      );
                    }
                  },
                  child: Text(copy.message439),
                ),
            ],
          ),
          Section(copy.message440),
          OutlinedButton.icon(
            onPressed: () => addPhoto(last['id']),
            icon: Icon(Icons.add_a_photo_outlined),
            label: Text(copy.message315),
          ),
          for (final visit in visits)
            if ((visit['photos'] as List).isNotEmpty) ...[
              Text(dateLabel(visit['at'])),
              photoStrip(visit),
            ],
          Section(copy.message441),
          for (final visit in visits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.directions_walk),
              title: Text(dateLabel(visit['at'])),
              subtitle: Text(
                visit['trip'] != null
                    ? store.sessions
                              .where((t) => t['id'] == visit['trip'])
                              .map((t) => store.route(t['routeId']).name)
                              .firstOrNull ??
                          copy.message442
                    : copy.message442,
              ),
              trailing: visit['trip'] != null
                  ? Icon(Icons.chevron_right)
                  : null,
              onTap: visit['trip'] == null
                  ? null
                  : () {
                      final t = store.session(visit['trip']);
                      open(
                        t['ended'] != null ? 's23' : 's12',
                        id: visit['trip'],
                      );
                    },
            ),
          SizedBox(height: 12),
          button(copy.message268, () => openMaps(p)),
        ],
      ),
    );
  }

  Widget photoStrip(Map<String, dynamic> visit) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final path in visit['photos'])
          Padding(
            padding: EdgeInsets.only(right: 10, bottom: 10),
            child: InkWell(
              onTap: () => open(
                'gallery',
                id: visit['id'],
                extra: '${(visit['photos'] as List).indexOf(path)}',
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: StoredPhoto(path: path, width: 130, height: 130),
              ),
            ),
          ),
      ],
    ),
  );
  Future<void> addPhoto(String visitId) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      final path = await persistPhoto(photo.path, bytes);
      final ok = await act(
        () => store.photo(visitId, path),
        success: copy.message443,
      );
      if (!ok) await deletePhotoFile(path);
    } catch (_) {
      if (mounted) {
        message(copy.message444);
      }
    }
  }

  Widget notePage() {
    final visit = store.visits.firstWhere((v) => v['id'] == widget.id);
    return NoteEditor(
      initial: visit['note'],
      onSave: (text) => store.note(widget.id!, text),
    );
  }

  Widget gallery() {
    final visit = store.visits.firstWhere((v) => v['id'] == widget.id);
    final photos = List<String>.from(visit['photos']);
    if (photos.isEmpty) {
      return PageFrame(
        title: copy.message440,
        leading: backButton(),
        child: Text(copy.message445),
      );
    }
    final index = (int.tryParse(widget.extra ?? '0') ?? 0).clamp(
      0,
      photos.length - 1,
    );
    return PageFrame(
      title: copy.message440,
      leading: backButton(),
      scroll: false,
      actions: [
        IconButton(
          tooltip: copy.message446,
          onPressed: () async {
            if (await confirm(
              copy.message447,
              copy.message448,
              yes: copy.message437,
            )) {
              if (await act(
                    () => store.removePhoto(visit['id'], photos[index]),
                  ) &&
                  mounted) {
                context.pop();
              }
            }
          },
          icon: Icon(Icons.delete_outline),
        ),
      ],
      child: PageView(
        controller: pager,
        children: [
          for (final photo in photos)
            InteractiveViewer(
              child: Center(
                child: StoredPhoto(
                  path: photo,
                  width: 640,
                  height: MediaQuery.sizeOf(context).height * .7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget history() {
    final all = store.sessions
        .where(
          (t) =>
              t['ended'] != null &&
              (historyFilter == copy.message027 ||
                  (historyFilter == copy.message449
                      ? t['status'] == 'completed'
                      : t['status'] != 'completed')),
        )
        .toList()
        .reversed
        .toList();
    String previous = '';
    return PageFrame(
      title: copy.message410,
      leading: backButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Все города'),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final f in [
                copy.message027,
                copy.message449,
                copy.message450,
              ])
                ChoiceChip(
                  label: Text(f),
                  selected: historyFilter == f,
                  onSelected: (_) => updateUi(() => historyFilter = f),
                ),
            ],
          ),
          if (store.active != null) ...[
            Section(copy.message113),
            ListTile(
              title: Text(store.route(store.active!['routeId']).name),
              subtitle: Text(copy.message451),
              trailing: Icon(Icons.play_arrow),
              onTap: () => open(
                store.active!['status'] == 'paused' ? 's18' : 's12',
                id: store.active!['id'],
              ),
            ),
          ],
          if (all.isEmpty)
            EmptyView(
              title: copy.message452,
              text: copy.message453,
              button: copy.message454,
              onTap: () => context.go('/routes'),
            )
          else
            for (final t in all) ...[
              if (previous !=
                  DateFormat(
                    'LLLL yyyy',
                    'ru',
                  ).format(DateTime.parse(t['started'])))
                Section(
                  previous = DateFormat(
                    'LLLL yyyy',
                    'ru',
                  ).format(DateTime.parse(t['started'])),
                ),
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => open('s23', id: t['id']),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.route(t['routeId']).name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 8),
                        Text(dateLabel(t['started'])),
                        Text(
                          t['status'] == 'completed'
                              ? copy.message449
                              : copy.message450,
                        ),
                        Text(
                          copy.message455(
                            (store.visitedCount(t)).toString(),
                            (store.skippedCount(t)).toString(),
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final stop
                                in (t['stops'] as List)
                                    .where((s) => s['result'] == 'visited')
                                    .take(3))
                              SizedBox(
                                width: 64,
                                child: Photo(
                                  store.places[stop['place']]!.image,
                                  height: 60,
                                  radius: 10,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget pastTrip() {
    final t = trip;
    return PageFrame(
      title: copy.message456,
      leading: backButton(),
      footer: button(
        copy.message457,
        () => chooseRoute(store.route(t['routeId'])),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(store.route(t['routeId']).name),
          Text(dateLabel(t['started'])),
          Tag(t['status'] == 'completed' ? copy.message449 : copy.message450),
          Section(copy.message458),
          Panel(
            child: Text(
              copy.message459(
                (t['filters']['mood']).toString(),
                (t['filters']['pace'] == 'calm'
                        ? copy.message224
                        : copy.message225)
                    .toString(),
                ((t['filters']['time'] / 60).round()).toString(),
              ),
            ),
          ),
          Section(copy.message275),
          Text(
            copy.message455(
              (store.visitedCount(t)).toString(),
              (store.skippedCount(t)).toString(),
            ),
          ),
          Text(copy.message460((store.elapsedMinutes(t)).toString())),
          Text(copy.message461((estimatedDistance(t)).toString())),
          SizedBox(height: 20),
          for (final stop in t['stops'])
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop['visible'] == true
                          ? store.places[stop['place']]!.name
                          : copy.message462,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(stopLabel(stop['result'])),
                    if (stop['original'] != null) Text(copy.message463),
                    if (stop['reason'] != null)
                      Text(copy.message464((stop['reason']).toString())),
                    if (stop['result'] == 'visited')
                      TextButton(
                        onPressed: () => open('s21', id: stop['place']),
                        child: Text(copy.message465),
                      ),
                  ],
                ),
              ),
            ),
          Section(copy.message466),
          for (final v in store.visits.where(
            (v) => v['trip'] == widget.id,
          )) ...[
            if ((v['note'] as String).isNotEmpty) Panel(child: Text(v['note'])),
            if ((v['photos'] as List).isNotEmpty) photoStrip(v),
          ],
          Section(copy.message467),
          Text(
            t['rating'] == 0
                ? copy.message468
                : copy.message469((t['rating']).toString()),
          ),
          if (t['feedback']['comment'] != null) Text(t['feedback']['comment']),
          TextButton(
            onPressed: () => open('s19', id: widget.id),
            child: Text(copy.message470),
          ),
          TextButton(
            onPressed: () => context.go('/atlas'),
            child: Text(copy.message471),
          ),
        ],
      ),
    );
  }

  Widget favoritesPage() {
    final list = store.allRoutes
        .where((r) => store.favorites.contains(r.id))
        .toList();
    return PageFrame(
      title: copy.message472,
      leading: backButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Tag('Все города'),
          SizedBox(height: 18),
          if (list.isEmpty)
            EmptyView(
              title: copy.message473,
              text: copy.message474,
              button: copy.message454,
              onTap: () => context.go('/routes'),
              icon: Icons.bookmark_border,
            )
          else
            ...list.map((r) => card(r)),
        ],
      ),
    );
  }

  Widget profile() => PageFrame(
    controller: scrollController,
    title: copy.message026,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.explore_outlined, size: 38),
              ),
              SizedBox(height: 14),
              Text(
                store.state['name'],
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(onPressed: editName, child: Text(copy.message475)),
              Text(copy.message476, textAlign: TextAlign.center),
            ],
          ),
        ),
        SizedBox(height: 22),
        profileItem(Icons.tune, copy.message477, () => open('s26')),
        profileItem(Icons.history, copy.message410, () => open('s22')),
        profileItem(Icons.bookmark_border, copy.message061, () => open('s24')),
        profileItem(
          Icons.settings_outlined,
          copy.message478,
          () => open('s27'),
        ),
        profileItem(
          Icons.help_outline,
          copy.message479,
          () => open('s02', extra: 'repeat'),
        ),
        profileItem(Icons.info_outline, copy.message480, () => open('s28')),
        SizedBox(height: 24),
        Text(copy.message481),
      ],
    ),
  );
  Widget profileItem(IconData icon, String text, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: Icon(icon),
        title: Text(text),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      );
  Future<void> editName() async {
    String name = store.state['name'];
    await sheet(copy.message482, [
      TextFormField(
        initialValue: name,
        maxLength: 40,
        decoration: InputDecoration(labelText: copy.message483),
        onChanged: (v) => name = v,
      ),
      SizedBox(height: 16),
      button(copy.message286, () async {
        if (await act(
              () => store.change(
                (s) => s['name'] = name.trim().isEmpty
                    ? copy.message484
                    : name.trim(),
              ),
            ) &&
            mounted) {
          context.pop();
        }
      }),
    ]);
  }

  Widget preferences() => PageFrame(
    title: copy.message477,
    leading: backButton(),
    footer: button(copy.message286, () async {
      if (await act(
            () => store.change((s) => s['preferences'] = form),
            success: copy.message485,
          ) &&
          mounted) {
        context.pop();
      }
    }),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(child: Text(copy.message486)),
        Section(copy.message130),
        choices('pace', ['calm', 'normal'], [copy.message131, copy.message132]),
        Section(copy.message125),
        choices(
          'distance',
          [2000, 4000, 7000, 100000],
          [copy.message126, copy.message127, copy.message128, copy.message176],
        ),
        Section(copy.message097),
        multi('interests', interests, limit: 3),
        Section(copy.message393),
        multi('missions', [copy.message142, copy.message143, copy.message144]),
        toggle('noMissions', copy.message145),
        Section(copy.message139),
        choices('diet', diets, diets),
        Section(copy.message487),
        toggle('noStairs', copy.message134),
        toggle('stroller', copy.message136),
        toggle('rest', copy.message137),
        toggle('indoors', copy.message138),
        TextButton(
          onPressed: () => updateUi(() => form = defaultFilters()),
          child: Text(copy.message488),
        ),
      ],
    ),
  );
  Widget settingsPage() => PageFrame(
    title: copy.message478,
    leading: backButton(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Section(copy.message489),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in {
              'system': copy.message490,
              'light': copy.message491,
              'dark': copy.message492,
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: store.settings['theme'] == entry.key,
                onSelected: (_) => act(() => store.setting('theme', entry.key)),
              ),
          ],
        ),
        Section(copy.message493),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(copy.message494),
          value: store.settings['haptics'] == true,
          onChanged: (v) => act(() => store.setting('haptics', v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(copy.message495),
          subtitle: Text(copy.message496),
          value: store.settings['reduceMotion'] == true,
          onChanged: (v) => act(() => store.setting('reduceMotion', v)),
        ),
        Section(copy.message497),
        FutureBuilder<int>(
          future: photoSize(),
          builder: (c, s) => Text(
            copy.message498(
              (((s.data ?? 0) / 1024 / 1024).toStringAsFixed(1)).toString(),
            ),
          ),
        ),
        profileItem(
          Icons.photo_outlined,
          copy.message499,
          () => clear('photos'),
        ),
        profileItem(Icons.history, copy.message500, () => clear('history')),
        profileItem(Icons.delete_outline, copy.message501, () => clear('all')),
        Section(copy.message502),
        profileItem(
          Icons.science_outlined,
          copy.message503,
          () => open('demo'),
        ),
        SizedBox(height: 24),
        Text(copy.message481),
      ],
    ),
  );
  Future<int> photoSize() async {
    var sum = 0;
    for (final v in store.visits) {
      for (final path in v['photos']) {
        sum += (await readPhoto(path))?.length ?? 0;
      }
    }
    return sum;
  }

  Future<void> clear(String type) async {
    final body = type == 'all'
        ? copy.message505(
            (store.active != null ? copy.message504 : '').toString(),
          )
        : type == 'photos'
        ? copy.message506
        : copy.message507;
    if (await confirm(copy.message508, body, yes: copy.message437)) {
      if (await act(() => store.clearData(type), success: copy.message509) &&
          mounted &&
          type == 'all') {
        context.go('/s02');
      }
    }
  }

  Widget about() => PageFrame(
    title: copy.message510,
    leading: backButton(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/images/app-icon.png',
            width: 96,
            height: 96,
            semanticLabel: 'Tripavela',
          ),
        ),
        title('Tripavela'),
        Text(copy.message511),
        Section(copy.message512),
        bodyText(copy.message513),
        Section(copy.message514),
        bodyText(copy.message515),
        Section(copy.message516),
        bodyText(copy.message517),
        Section(copy.message518),
        bodyText(copy.message519),
        Section(copy.photoCreditsTitle),
        Text(copy.photoCreditsChanges),
        for (final credit in store.cityData['photoCredits'] as List? ?? [])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${credit['author']} · ${credit['license']}'),
            subtitle: Text(
              credit['label'] as String? ?? credit['asset'] as String,
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () async {
              try {
                await launchUrl(
                  Uri.parse(credit['url'] as String),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {
                if (mounted) message(copy.message272);
              }
            },
          ),
        Text(copy.message520),
        SizedBox(height: 24),
        button(copy.message521, () => open('s02', extra: 'repeat')),
      ],
    ),
  );
  Widget demoPage() => PageFrame(
    title: copy.message522,
    leading: backButton(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(child: Text(copy.message523)),
        Section(copy.message524),
        for (final e in {
          'closed': copy.message525,
          'weather': copy.message526,
          'noAlternatives': copy.message527,
          'mapsError': copy.message528,
          'saveError': copy.message529,
          'late': copy.message530,
        }.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(e.value),
            value: store.demo[e.key] == true,
            onChanged: (v) => act(
              () => store.change((s) => s['demo'][e.key] = v, allowError: true),
            ),
          ),
        Section(copy.message531),
        for (final preset in [
          copy.message532,
          copy.message533,
          copy.message019,
          copy.message534,
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => presetDemo(preset),
              child: Text(preset),
            ),
          ),
      ],
    ),
  );
  Future<void> presetDemo(String preset) async {
    if (!await confirm(
      copy.message535,
      copy.message536,
      yes: copy.message537,
    )) {
      return;
    }
    if (!await act(() async {
      await store.clearData('all');
      await store.change((s) {
        s['onboarded'] = preset != copy.message532;
        s['city'] = preset != copy.message532;
        s['draft'] = defaultFilters();
      }, allowError: true);
      if (preset != copy.message532) {
        final id = await store.start('r0');
        if (preset == copy.message019) await store.pause(id);
        if (preset == copy.message534) {
          await store.arrive(id);
          await store.advance(id);
          await store.arrive(id);
          await store.advance(id);
          await store.branch(id, 0);
          await store.arrive(id);
          await store.advance(id);
          await store.advance(id, skip: true);
          final repeat = await store.start('r0');
          await store.arrive(repeat);
          await store.end(repeat);
        }
      }
    })) {
      return;
    }
    if (mounted) context.go(preset == copy.message532 ? '/s02' : '/home');
  }
}

class StoredPhoto extends StatelessWidget {
  final String path;
  final double width, height;
  final BoxFit fit;
  const StoredPhoto({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>?>(
    future: readPhoto(path),
    builder: (c, s) => s.data == null
        ? SizedBox(
            width: width,
            height: height,
            child: Center(child: Icon(Icons.image_not_supported_outlined)),
          )
        : Image.memory(
            Uint8List.fromList(s.data!),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (c, e, st) => SizedBox(
              width: width,
              height: height,
              child: Center(child: Icon(Icons.image_not_supported_outlined)),
            ),
          ),
  );
}

class NoteEditor extends StatefulWidget {
  final String initial;
  final Future<void> Function(String) onSave;
  const NoteEditor({super.key, required this.initial, required this.onSave});
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final controller = TextEditingController(text: widget.initial);
  bool saving = false, allowPop = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<bool> save() async {
    setState(() => saving = true);
    try {
      await widget.onSave(controller.text);
      if (mounted) {
        setState(() => allowPop = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(copy.message538)));
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(copy.message539)));
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> leave() async {
    if (controller.text == widget.initial) {
      setState(() => allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(copy.message540),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'stay'),
            child: Text(copy.message541),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: Text(copy.message542),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'save'),
            child: Text(copy.message286),
          ),
        ],
      ),
    );
    if (choice == 'save' && !await save()) return;
    if (choice == 'save' || choice == 'discard') {
      if (!mounted) return;
      setState(() => allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) leave();
    },
    child: PageFrame(
      title: copy.message432,
      leading: IconButton(
        tooltip: copy.message034,
        onPressed: leave,
        icon: Icon(Icons.arrow_back),
      ),
      footer: FilledButton(
        onPressed: saving
            ? null
            : () async {
                if (await save() && context.mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.pop();
                  });
                }
              },
        child: Text(saving ? copy.message543 : copy.message286),
      ),
      child: TextField(
        controller: controller,
        minLines: 10,
        maxLines: null,
        maxLength: 2000,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => currentLength > 1800
            ? Text('$currentLength / $maxLength')
            : null,
        decoration: InputDecoration(
          hintText: copy.message544,
          border: InputBorder.none,
        ),
      ),
    ),
  );
}
