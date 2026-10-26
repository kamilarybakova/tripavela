import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @message000.
  ///
  /// In ru, this message translates to:
  /// **'5 городов · поездки по дням и прогулки'**
  String get message000;

  /// No description provided for @message001.
  ///
  /// In ru, this message translates to:
  /// **'Удивиться'**
  String get message001;

  /// No description provided for @message002.
  ///
  /// In ru, this message translates to:
  /// **'Замедлиться'**
  String get message002;

  /// No description provided for @message003.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать новое'**
  String get message003;

  /// No description provided for @message004.
  ///
  /// In ru, this message translates to:
  /// **'Почувствовать город'**
  String get message004;

  /// No description provided for @message005.
  ///
  /// In ru, this message translates to:
  /// **'Провести время вместе'**
  String get message005;

  /// No description provided for @message006.
  ///
  /// In ru, this message translates to:
  /// **'Довериться случаю'**
  String get message006;

  /// No description provided for @message007.
  ///
  /// In ru, this message translates to:
  /// **'Еда'**
  String get message007;

  /// No description provided for @message008.
  ///
  /// In ru, this message translates to:
  /// **'Искусство'**
  String get message008;

  /// No description provided for @message009.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get message009;

  /// No description provided for @message010.
  ///
  /// In ru, this message translates to:
  /// **'Архитектура'**
  String get message010;

  /// No description provided for @message011.
  ///
  /// In ru, this message translates to:
  /// **'Природа'**
  String get message011;

  /// No description provided for @message012.
  ///
  /// In ru, this message translates to:
  /// **'Мастерские'**
  String get message012;

  /// No description provided for @message013.
  ///
  /// In ru, this message translates to:
  /// **'Книжные'**
  String get message013;

  /// No description provided for @message014.
  ///
  /// In ru, this message translates to:
  /// **'Городские детали'**
  String get message014;

  /// No description provided for @message015.
  ///
  /// In ru, this message translates to:
  /// **'Без предпочтений'**
  String get message015;

  /// No description provided for @message016.
  ///
  /// In ru, this message translates to:
  /// **'Вегетарианское'**
  String get message016;

  /// No description provided for @message017.
  ///
  /// In ru, this message translates to:
  /// **'Веганское'**
  String get message017;

  /// No description provided for @message018.
  ///
  /// In ru, this message translates to:
  /// **'Без алкоголя'**
  String get message018;

  /// No description provided for @message019.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка на паузе'**
  String get message019;

  /// No description provided for @message020.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка продолжается · остановка {value0} из {value1}'**
  String message020(String value0, String value1);

  /// No description provided for @message021.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get message021;

  /// No description provided for @message022.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться'**
  String get message022;

  /// No description provided for @message023.
  ///
  /// In ru, this message translates to:
  /// **'Обзор'**
  String get message023;

  /// No description provided for @message024.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты'**
  String get message024;

  /// No description provided for @message025.
  ///
  /// In ru, this message translates to:
  /// **'Атлас'**
  String get message025;

  /// No description provided for @message026.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get message026;

  /// No description provided for @message027.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get message027;

  /// No description provided for @message028.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемые'**
  String get message028;

  /// No description provided for @message029.
  ///
  /// In ru, this message translates to:
  /// **'Закрыто'**
  String get message029;

  /// No description provided for @message030.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get message030;

  /// No description provided for @message031.
  ///
  /// In ru, this message translates to:
  /// **'Можно выбрать до трёх интересов.'**
  String get message031;

  /// No description provided for @message032.
  ///
  /// In ru, this message translates to:
  /// **'Убрано из избранного'**
  String get message032;

  /// No description provided for @message033.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в избранное'**
  String get message033;

  /// No description provided for @message034.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get message034;

  /// No description provided for @message035.
  ///
  /// In ru, this message translates to:
  /// **'Страница не найдена'**
  String get message035;

  /// No description provided for @message036.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get message036;

  /// No description provided for @message037.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get message037;

  /// No description provided for @message038.
  ///
  /// In ru, this message translates to:
  /// **'Город приготовил кое-что интересное'**
  String get message038;

  /// No description provided for @message039.
  ///
  /// In ru, this message translates to:
  /// **'Следующее место — маленький сюрприз'**
  String get message039;

  /// No description provided for @message040.
  ///
  /// In ru, this message translates to:
  /// **'Приключение в вашем темпе'**
  String get message040;

  /// No description provided for @message041.
  ///
  /// In ru, this message translates to:
  /// **'Выберите настроение, время и бюджет. Мы предложим прогулку с небольшими открытиями.'**
  String get message041;

  /// No description provided for @message042.
  ///
  /// In ru, this message translates to:
  /// **'Остановки открываются постепенно. Длительность, расходы и важные условия видны заранее.'**
  String get message042;

  /// No description provided for @message043.
  ///
  /// In ru, this message translates to:
  /// **'Пропускайте задания, меняйте остановки и завершайте прогулку, когда захотите.'**
  String get message043;

  /// No description provided for @message044.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать город'**
  String get message044;

  /// No description provided for @message045.
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get message045;

  /// No description provided for @message046.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get message046;

  /// No description provided for @message047.
  ///
  /// In ru, this message translates to:
  /// **'Ваш город. Ваша история.'**
  String get message047;

  /// No description provided for @message048.
  ///
  /// In ru, this message translates to:
  /// **'Одно открытие за другим'**
  String get message048;

  /// No description provided for @message049.
  ///
  /// In ru, this message translates to:
  /// **'Без спешки и обязательств'**
  String get message049;

  /// No description provided for @message050.
  ///
  /// In ru, this message translates to:
  /// **'стамбул istanbul турция'**
  String get message050;

  /// No description provided for @message051.
  ///
  /// In ru, this message translates to:
  /// **'Где погуляем?'**
  String get message051;

  /// No description provided for @message052.
  ///
  /// In ru, this message translates to:
  /// **'В демоверсии доступны пять городов'**
  String get message052;

  /// No description provided for @message053.
  ///
  /// In ru, this message translates to:
  /// **'Найти город'**
  String get message053;

  /// No description provided for @message054.
  ///
  /// In ru, this message translates to:
  /// **'Стамбул'**
  String get message054;

  /// No description provided for @message055.
  ///
  /// In ru, this message translates to:
  /// **'Турция · 15 приключений'**
  String get message055;

  /// No description provided for @message056.
  ///
  /// In ru, this message translates to:
  /// **'Доступен офлайн'**
  String get message056;

  /// No description provided for @message057.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет такого города. Попробуйте другое название'**
  String get message057;

  /// No description provided for @message058.
  ///
  /// In ru, this message translates to:
  /// **'Пять направлений для самостоятельной поездки'**
  String get message058;

  /// No description provided for @message059.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город и соберите план на несколько дней.'**
  String get message059;

  /// No description provided for @message060.
  ///
  /// In ru, this message translates to:
  /// **'ВАШ ГОРОД'**
  String get message060;

  /// No description provided for @message061.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get message061;

  /// No description provided for @message062.
  ///
  /// In ru, this message translates to:
  /// **'На паузе'**
  String get message062;

  /// No description provided for @message063.
  ///
  /// In ru, this message translates to:
  /// **'Продолжается'**
  String get message063;

  /// No description provided for @message064.
  ///
  /// In ru, this message translates to:
  /// **'Посещено {value0} из 4 остановок'**
  String message064(String value0);

  /// No description provided for @message065.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к прогулке'**
  String get message065;

  /// No description provided for @message066.
  ///
  /// In ru, this message translates to:
  /// **'Маленькое приключение рядом'**
  String get message066;

  /// No description provided for @message067.
  ///
  /// In ru, this message translates to:
  /// **'Какое приключение устроим сегодня?'**
  String get message067;

  /// No description provided for @message068.
  ///
  /// In ru, this message translates to:
  /// **'Подберём прогулку под ваше настроение.'**
  String get message068;

  /// No description provided for @message069.
  ///
  /// In ru, this message translates to:
  /// **'Подобрать прогулку'**
  String get message069;

  /// No description provided for @message070.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть все маршруты'**
  String get message070;

  /// No description provided for @message071.
  ///
  /// In ru, this message translates to:
  /// **'На пару часов'**
  String get message071;

  /// No description provided for @message072.
  ///
  /// In ru, this message translates to:
  /// **'Еда и открытия'**
  String get message072;

  /// No description provided for @message073.
  ///
  /// In ru, this message translates to:
  /// **'Хочется тишины'**
  String get message073;

  /// No description provided for @message074.
  ///
  /// In ru, this message translates to:
  /// **'Для двоих'**
  String get message074;

  /// No description provided for @message075.
  ///
  /// In ru, this message translates to:
  /// **'Вдвоём'**
  String get message075;

  /// No description provided for @message076.
  ///
  /// In ru, this message translates to:
  /// **'Для первого знакомства'**
  String get message076;

  /// No description provided for @message077.
  ///
  /// In ru, this message translates to:
  /// **'Выберите настроение'**
  String get message077;

  /// No description provided for @message078.
  ///
  /// In ru, this message translates to:
  /// **'Гастрономия'**
  String get message078;

  /// No description provided for @message079.
  ///
  /// In ru, this message translates to:
  /// **'Спокойная прогулка'**
  String get message079;

  /// No description provided for @message080.
  ///
  /// In ru, this message translates to:
  /// **'Городские истории'**
  String get message080;

  /// No description provided for @message081.
  ///
  /// In ru, this message translates to:
  /// **'Необычные места'**
  String get message081;

  /// No description provided for @message082.
  ///
  /// In ru, this message translates to:
  /// **'Совместный досуг'**
  String get message082;

  /// No description provided for @message083.
  ///
  /// In ru, this message translates to:
  /// **'Как это работает'**
  String get message083;

  /// No description provided for @message084.
  ///
  /// In ru, this message translates to:
  /// **'Выберите условия'**
  String get message084;

  /// No description provided for @message085.
  ///
  /// In ru, this message translates to:
  /// **'Открывайте места по пути'**
  String get message085;

  /// No description provided for @message086.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните свою историю дня'**
  String get message086;

  /// No description provided for @message087.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить подбор?'**
  String get message087;

  /// No description provided for @message088.
  ///
  /// In ru, this message translates to:
  /// **'Сохранили ваши последние условия.'**
  String get message088;

  /// No description provided for @message089.
  ///
  /// In ru, this message translates to:
  /// **'Начать заново'**
  String get message089;

  /// No description provided for @message090.
  ///
  /// In ru, this message translates to:
  /// **'Подбор прогулки'**
  String get message090;

  /// No description provided for @message091.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть подбор'**
  String get message091;

  /// No description provided for @message092.
  ///
  /// In ru, this message translates to:
  /// **'Показать маршруты'**
  String get message092;

  /// No description provided for @message093.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {value0} из 3'**
  String message093(String value0);

  /// No description provided for @message094.
  ///
  /// In ru, this message translates to:
  /// **'Чего хочется сегодня?'**
  String get message094;

  /// No description provided for @message095.
  ///
  /// In ru, this message translates to:
  /// **'Выберите одно настроение и до трёх интересов'**
  String get message095;

  /// No description provided for @message096.
  ///
  /// In ru, this message translates to:
  /// **'Настроение'**
  String get message096;

  /// No description provided for @message097.
  ///
  /// In ru, this message translates to:
  /// **'Интересы'**
  String get message097;

  /// No description provided for @message098.
  ///
  /// In ru, this message translates to:
  /// **'С кем идёте?'**
  String get message098;

  /// No description provided for @message099.
  ///
  /// In ru, this message translates to:
  /// **'Один / одна'**
  String get message099;

  /// No description provided for @message100.
  ///
  /// In ru, this message translates to:
  /// **'С друзьями'**
  String get message100;

  /// No description provided for @message101.
  ///
  /// In ru, this message translates to:
  /// **'С детьми'**
  String get message101;

  /// No description provided for @message102.
  ///
  /// In ru, this message translates to:
  /// **'Возрастная группа'**
  String get message102;

  /// No description provided for @message103.
  ///
  /// In ru, this message translates to:
  /// **'До 6 лет'**
  String get message103;

  /// No description provided for @message104.
  ///
  /// In ru, this message translates to:
  /// **'6–11 лет'**
  String get message104;

  /// No description provided for @message105.
  ///
  /// In ru, this message translates to:
  /// **'12–17 лет'**
  String get message105;

  /// No description provided for @message106.
  ///
  /// In ru, this message translates to:
  /// **'Сколько времени на приключение?'**
  String get message106;

  /// No description provided for @message107.
  ///
  /// In ru, this message translates to:
  /// **'До 1 часа'**
  String get message107;

  /// No description provided for @message108.
  ///
  /// In ru, this message translates to:
  /// **'До 2 часов'**
  String get message108;

  /// No description provided for @message109.
  ///
  /// In ru, this message translates to:
  /// **'До 4 часов'**
  String get message109;

  /// No description provided for @message110.
  ///
  /// In ru, this message translates to:
  /// **'До 6 часов'**
  String get message110;

  /// No description provided for @message111.
  ///
  /// In ru, this message translates to:
  /// **'Учитываем переходы, остановки и время на отдых.'**
  String get message111;

  /// No description provided for @message112.
  ///
  /// In ru, this message translates to:
  /// **'Когда начнёте?'**
  String get message112;

  /// No description provided for @message113.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get message113;

  /// No description provided for @message114.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать время'**
  String get message114;

  /// No description provided for @message115.
  ///
  /// In ru, this message translates to:
  /// **'{value0} · {value1} · местное время'**
  String message115(String value0, String value1);

  /// No description provided for @message116.
  ///
  /// In ru, this message translates to:
  /// **'Время старта — рекомендация для прогулки днём. Работа заведений отдельно.'**
  String get message116;

  /// No description provided for @message117.
  ///
  /// In ru, this message translates to:
  /// **'Бюджет на человека'**
  String get message117;

  /// No description provided for @message118.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно · 0 ₺'**
  String get message118;

  /// No description provided for @message119.
  ///
  /// In ru, this message translates to:
  /// **'Экономно · до 400 ₺'**
  String get message119;

  /// No description provided for @message120.
  ///
  /// In ru, this message translates to:
  /// **'Умеренно · до 800 ₺'**
  String get message120;

  /// No description provided for @message121.
  ///
  /// In ru, this message translates to:
  /// **'Без строгого лимита'**
  String get message121;

  /// No description provided for @message122.
  ///
  /// In ru, this message translates to:
  /// **'Еда, билеты и транспорт оплачиваются отдельно. Необязательные покупки можно пропустить.'**
  String get message122;

  /// No description provided for @message123.
  ///
  /// In ru, this message translates to:
  /// **'Сделаем прогулку комфортной'**
  String get message123;

  /// No description provided for @message124.
  ///
  /// In ru, this message translates to:
  /// **'Пешком · доступно в демоверсии'**
  String get message124;

  /// No description provided for @message125.
  ///
  /// In ru, this message translates to:
  /// **'Комфортная дистанция'**
  String get message125;

  /// No description provided for @message126.
  ///
  /// In ru, this message translates to:
  /// **'До 2 км'**
  String get message126;

  /// No description provided for @message127.
  ///
  /// In ru, this message translates to:
  /// **'До 4 км'**
  String get message127;

  /// No description provided for @message128.
  ///
  /// In ru, this message translates to:
  /// **'До 7 км'**
  String get message128;

  /// No description provided for @message129.
  ///
  /// In ru, this message translates to:
  /// **'Не ограничивать'**
  String get message129;

  /// No description provided for @message130.
  ///
  /// In ru, this message translates to:
  /// **'Темп'**
  String get message130;

  /// No description provided for @message131.
  ///
  /// In ru, this message translates to:
  /// **'Спокойный'**
  String get message131;

  /// No description provided for @message132.
  ///
  /// In ru, this message translates to:
  /// **'Обычный'**
  String get message132;

  /// No description provided for @message133.
  ///
  /// In ru, this message translates to:
  /// **'Важные условия'**
  String get message133;

  /// No description provided for @message134.
  ///
  /// In ru, this message translates to:
  /// **'Без лестниц'**
  String get message134;

  /// No description provided for @message135.
  ///
  /// In ru, this message translates to:
  /// **'Без запланированных лестниц; покрытие и бордюры требуют проверки'**
  String get message135;

  /// No description provided for @message136.
  ///
  /// In ru, this message translates to:
  /// **'С детской коляской'**
  String get message136;

  /// No description provided for @message137.
  ///
  /// In ru, this message translates to:
  /// **'Нужны места для отдыха'**
  String get message137;

  /// No description provided for @message138.
  ///
  /// In ru, this message translates to:
  /// **'Предпочтительно внутри помещений'**
  String get message138;

  /// No description provided for @message139.
  ///
  /// In ru, this message translates to:
  /// **'Питание'**
  String get message139;

  /// No description provided for @message140.
  ///
  /// In ru, this message translates to:
  /// **'Состав блюд и возможные аллергены нужно уточнять на месте.'**
  String get message140;

  /// No description provided for @message141.
  ///
  /// In ru, this message translates to:
  /// **'Какие задания вам комфортны?'**
  String get message141;

  /// No description provided for @message142.
  ///
  /// In ru, this message translates to:
  /// **'Наблюдать'**
  String get message142;

  /// No description provided for @message143.
  ///
  /// In ru, this message translates to:
  /// **'Пробовать'**
  String get message143;

  /// No description provided for @message144.
  ///
  /// In ru, this message translates to:
  /// **'Общаться'**
  String get message144;

  /// No description provided for @message145.
  ///
  /// In ru, this message translates to:
  /// **'Без миссий'**
  String get message145;

  /// No description provided for @message146.
  ///
  /// In ru, this message translates to:
  /// **'Ваши прогулки'**
  String get message146;

  /// No description provided for @message147.
  ///
  /// In ru, this message translates to:
  /// **'Изменить условия'**
  String get message147;

  /// No description provided for @message148.
  ///
  /// In ru, this message translates to:
  /// **'без лимита'**
  String get message148;

  /// No description provided for @message149.
  ///
  /// In ru, this message translates to:
  /// **'До {value0} ч · пешком · бюджет {value1} · {value2}'**
  String message149(String value0, String value1, String value2);

  /// No description provided for @message150.
  ///
  /// In ru, this message translates to:
  /// **'С такими условиями пока нет прогулки'**
  String get message150;

  /// No description provided for @message151.
  ///
  /// In ru, this message translates to:
  /// **'Увеличить время до 6 часов и дистанцию'**
  String get message151;

  /// No description provided for @message152.
  ///
  /// In ru, this message translates to:
  /// **'Подходит маршрутов: {value0}'**
  String message152(String value0);

  /// No description provided for @message153.
  ///
  /// In ru, this message translates to:
  /// **' Совпадает с вашим настроением.'**
  String get message153;

  /// No description provided for @message154.
  ///
  /// In ru, this message translates to:
  /// **'Подходит по времени, расходам и обязательным условиям.{value0}'**
  String message154(String value0);

  /// No description provided for @message155.
  ///
  /// In ru, this message translates to:
  /// **'Для выбранного времени уже поздно начинать эту дневную прогулку. Выберите утренний старт.'**
  String get message155;

  /// No description provided for @message156.
  ///
  /// In ru, this message translates to:
  /// **'Самая короткая прогулка с запасом занимает 90 минут. Увеличьте доступное время.'**
  String get message156;

  /// No description provided for @message157.
  ///
  /// In ru, this message translates to:
  /// **'Сочетание времени, дистанции, бюджета и ограничений исключило все маршруты. Измените условия; требования доступности и питания сохраняются.'**
  String get message157;

  /// No description provided for @message158.
  ///
  /// In ru, this message translates to:
  /// **'Сначала короткие'**
  String get message158;

  /// No description provided for @message159.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дешевле'**
  String get message159;

  /// No description provided for @message160.
  ///
  /// In ru, this message translates to:
  /// **'Сначала меньше ходьбы'**
  String get message160;

  /// No description provided for @message161.
  ///
  /// In ru, this message translates to:
  /// **'Прогулки по городу'**
  String get message161;

  /// No description provided for @message162.
  ///
  /// In ru, this message translates to:
  /// **'Название или тема'**
  String get message162;

  /// No description provided for @message163.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get message163;

  /// No description provided for @message164.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get message164;

  /// No description provided for @message165.
  ///
  /// In ru, this message translates to:
  /// **'Маршрутов: {value0}'**
  String message165(String value0);

  /// No description provided for @message166.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не нашлось'**
  String get message166;

  /// No description provided for @message167.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другую тему или сбросьте фильтры.'**
  String get message167;

  /// No description provided for @message168.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить фильтры'**
  String get message168;

  /// No description provided for @message169.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get message169;

  /// No description provided for @message170.
  ///
  /// In ru, this message translates to:
  /// **'Бюджет'**
  String get message170;

  /// No description provided for @message171.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно'**
  String get message171;

  /// No description provided for @message172.
  ///
  /// In ru, this message translates to:
  /// **'До 400 ₺'**
  String get message172;

  /// No description provided for @message173.
  ///
  /// In ru, this message translates to:
  /// **'До 800 ₺'**
  String get message173;

  /// No description provided for @message174.
  ///
  /// In ru, this message translates to:
  /// **'Без лимита'**
  String get message174;

  /// No description provided for @message175.
  ///
  /// In ru, this message translates to:
  /// **'Дистанция'**
  String get message175;

  /// No description provided for @message176.
  ///
  /// In ru, this message translates to:
  /// **'Любая'**
  String get message176;

  /// No description provided for @message177.
  ///
  /// In ru, this message translates to:
  /// **'Тематика'**
  String get message177;

  /// No description provided for @message178.
  ///
  /// In ru, this message translates to:
  /// **'Показать {value0} маршрутов'**
  String message178(String value0);

  /// No description provided for @message179.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get message179;

  /// No description provided for @message180.
  ///
  /// In ru, this message translates to:
  /// **'О прогулке'**
  String get message180;

  /// No description provided for @message181.
  ///
  /// In ru, this message translates to:
  /// **'{value0}–{value1} мин · {value2}–{value3} на человека'**
  String message181(String value0, String value1, String value2, String value3);

  /// No description provided for @message182.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать прогулку'**
  String get message182;

  /// No description provided for @message183.
  ///
  /// In ru, this message translates to:
  /// **'Автор · Редакция Tripavela'**
  String get message183;

  /// No description provided for @message184.
  ///
  /// In ru, this message translates to:
  /// **'Главное о прогулке'**
  String get message184;

  /// No description provided for @message185.
  ///
  /// In ru, this message translates to:
  /// **'{value0}–{value1} мин'**
  String message185(String value0, String value1);

  /// No description provided for @message186.
  ///
  /// In ru, this message translates to:
  /// **'{value0}–{value1} км'**
  String message186(String value0, String value1);

  /// No description provided for @message187.
  ///
  /// In ru, this message translates to:
  /// **'4 остановки'**
  String get message187;

  /// No description provided for @message188.
  ///
  /// In ru, this message translates to:
  /// **'{value0}–{value1} / чел.'**
  String message188(String value0, String value1);

  /// No description provided for @message189.
  ///
  /// In ru, this message translates to:
  /// **'Почему может понравиться'**
  String get message189;

  /// No description provided for @message190.
  ///
  /// In ru, this message translates to:
  /// **'Тема: {value0}. Есть выбор направления.'**
  String message190(String value0);

  /// No description provided for @message191.
  ///
  /// In ru, this message translates to:
  /// **'Можно останавливаться, пропускать миссии и менять планы.'**
  String get message191;

  /// No description provided for @message192.
  ///
  /// In ru, this message translates to:
  /// **'Что вас ждёт'**
  String get message192;

  /// No description provided for @message193.
  ///
  /// In ru, this message translates to:
  /// **'Начнём с небольшого открытия'**
  String get message193;

  /// No description provided for @message194.
  ///
  /// In ru, this message translates to:
  /// **'Рассмотрим город внимательнее'**
  String get message194;

  /// No description provided for @message195.
  ///
  /// In ru, this message translates to:
  /// **'Выберем настроение второй половины'**
  String get message195;

  /// No description provided for @message196.
  ///
  /// In ru, this message translates to:
  /// **'Завершим прогулку новой историей'**
  String get message196;

  /// No description provided for @message197.
  ///
  /// In ru, this message translates to:
  /// **'Запланированных лестниц нет; безбарьерность не проверена'**
  String get message197;

  /// No description provided for @message198.
  ///
  /// In ru, this message translates to:
  /// **'Есть лестницы'**
  String get message198;

  /// No description provided for @message199.
  ///
  /// In ru, this message translates to:
  /// **'Доступность не проверена'**
  String get message199;

  /// No description provided for @message200.
  ///
  /// In ru, this message translates to:
  /// **'есть места для отдыха'**
  String get message200;

  /// No description provided for @message201.
  ///
  /// In ru, this message translates to:
  /// **'места отдыха не подтверждены'**
  String get message201;

  /// No description provided for @message202.
  ///
  /// In ru, this message translates to:
  /// **'Городское покрытие; {value0}'**
  String message202(String value0);

  /// No description provided for @message203.
  ///
  /// In ru, this message translates to:
  /// **'Обязательные расходы: {value0}–{value1}'**
  String message203(String value0, String value1);

  /// No description provided for @message204.
  ///
  /// In ru, this message translates to:
  /// **'Желательно начать до {value0}:00 · местное время'**
  String message204(String value0);

  /// No description provided for @message205.
  ///
  /// In ru, this message translates to:
  /// **'Для наружного осмотра бронирование не требуется'**
  String get message205;

  /// No description provided for @message206.
  ///
  /// In ru, this message translates to:
  /// **'Возможна прогулка с детьми; учитывайте уклоны, транспорт и усталость'**
  String get message206;

  /// No description provided for @message207.
  ///
  /// In ru, this message translates to:
  /// **'Семейная доступность не подтверждена'**
  String get message207;

  /// No description provided for @message208.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут в пределах одного района, без обязательных поездок'**
  String get message208;

  /// No description provided for @message209.
  ///
  /// In ru, this message translates to:
  /// **'Дорога до старта и обратная дорога не включены в пешую длину и бюджет.'**
  String get message209;

  /// No description provided for @message210.
  ///
  /// In ru, this message translates to:
  /// **'Структура расходов'**
  String get message210;

  /// No description provided for @message211.
  ///
  /// In ru, this message translates to:
  /// **'Обязательные билеты: {value0}–{value1}'**
  String message211(String value0, String value1);

  /// No description provided for @message212.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемая еда: {value0}–{value1}'**
  String message212(String value0, String value1);

  /// No description provided for @message213.
  ///
  /// In ru, this message translates to:
  /// **'Необязательные покупки оплачиваются отдельно. Есть бесплатные варианты миссий.'**
  String get message213;

  /// No description provided for @message214.
  ///
  /// In ru, this message translates to:
  /// **'Миссии и развилка'**
  String get message214;

  /// No description provided for @message215.
  ///
  /// In ru, this message translates to:
  /// **'До трёх необязательных миссий и один выбор направления. Точные места откроются по пути.'**
  String get message215;

  /// No description provided for @message216.
  ///
  /// In ru, this message translates to:
  /// **'У вас уже есть незавершённая прогулка'**
  String get message216;

  /// No description provided for @message217.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к ней'**
  String get message217;

  /// No description provided for @message218.
  ///
  /// In ru, this message translates to:
  /// **'Завершить текущую прогулку?'**
  String get message218;

  /// No description provided for @message219.
  ///
  /// In ru, this message translates to:
  /// **'Посещённые места, фотографии и заметки сохранятся.'**
  String get message219;

  /// No description provided for @message220.
  ///
  /// In ru, this message translates to:
  /// **'Завершить и выбрать новую'**
  String get message220;

  /// No description provided for @message221.
  ///
  /// In ru, this message translates to:
  /// **'Завершить и начать новую'**
  String get message221;

  /// No description provided for @message222.
  ///
  /// In ru, this message translates to:
  /// **'Подготовка'**
  String get message222;

  /// No description provided for @message223.
  ///
  /// In ru, this message translates to:
  /// **'Начать прогулку'**
  String get message223;

  /// No description provided for @message224.
  ///
  /// In ru, this message translates to:
  /// **'спокойный'**
  String get message224;

  /// No description provided for @message225.
  ///
  /// In ru, this message translates to:
  /// **'обычный'**
  String get message225;

  /// No description provided for @message226.
  ///
  /// In ru, this message translates to:
  /// **'До {value0} часов · {value1} темп · бюджет {value2}'**
  String message226(String value0, String value1, String value2);

  /// No description provided for @message227.
  ///
  /// In ru, this message translates to:
  /// **'Первая остановка: центральный район. Дорога до старта не включена.'**
  String get message227;

  /// No description provided for @message228.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка займёт примерно {value0}–{value1} минут. Начните до {value2}:00.'**
  String message228(String value0, String value1, String value2);

  /// No description provided for @message229.
  ///
  /// In ru, this message translates to:
  /// **'Лестницы не запланированы; возможны бордюры и неровности'**
  String get message229;

  /// No description provided for @message230.
  ///
  /// In ru, this message translates to:
  /// **'На маршруте есть лестницы'**
  String get message230;

  /// No description provided for @message231.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно: {value0}–{value1}. Еда: {value2}–{value3} по желанию.'**
  String message231(String value0, String value1, String value2, String value3);

  /// No description provided for @message232.
  ///
  /// In ru, this message translates to:
  /// **'Прибытие подтверждается вручную'**
  String get message232;

  /// No description provided for @message233.
  ///
  /// In ru, this message translates to:
  /// **'Миссии отключены'**
  String get message233;

  /// No description provided for @message234.
  ///
  /// In ru, this message translates to:
  /// **'Миссии добровольные'**
  String get message234;

  /// No description provided for @message235.
  ///
  /// In ru, this message translates to:
  /// **'Перед выходом'**
  String get message235;

  /// No description provided for @message236.
  ///
  /// In ru, this message translates to:
  /// **'Зарядите телефон'**
  String get message236;

  /// No description provided for @message237.
  ///
  /// In ru, this message translates to:
  /// **'Возьмите воду'**
  String get message237;

  /// No description provided for @message238.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте погоду'**
  String get message238;

  /// No description provided for @message239.
  ///
  /// In ru, this message translates to:
  /// **'Настройка сюрприза'**
  String get message239;

  /// No description provided for @message240.
  ///
  /// In ru, this message translates to:
  /// **'Открывать места постепенно'**
  String get message240;

  /// No description provided for @message241.
  ///
  /// In ru, this message translates to:
  /// **'Сразу показать весь маршрут'**
  String get message241;

  /// No description provided for @message242.
  ///
  /// In ru, this message translates to:
  /// **'Раскрыть все места можно и во время прогулки. Вернуть сюрприз после раскрытия уже не получится.'**
  String get message242;

  /// No description provided for @message243.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get message243;

  /// No description provided for @message244.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get message244;

  /// No description provided for @message245.
  ///
  /// In ru, this message translates to:
  /// **'Лучше всего подходит'**
  String get message245;

  /// No description provided for @message246.
  ///
  /// In ru, this message translates to:
  /// **'{value0} км'**
  String message246(String value0);

  /// No description provided for @message247.
  ///
  /// In ru, this message translates to:
  /// **'Схема прогулки'**
  String get message247;

  /// No description provided for @message248.
  ///
  /// In ru, this message translates to:
  /// **'Иллюстрированная последовательность, не навигационная карта.'**
  String get message248;

  /// No description provided for @message249.
  ///
  /// In ru, this message translates to:
  /// **'Посещено {value0} · пропущено {value1} · осталось {value2}'**
  String message249(String value0, String value1, String value2);

  /// No description provided for @message250.
  ///
  /// In ru, this message translates to:
  /// **'Остановка {value0} из 4'**
  String message250(String value0);

  /// No description provided for @message251.
  ///
  /// In ru, this message translates to:
  /// **'Свернуть к обзору'**
  String get message251;

  /// No description provided for @message252.
  ///
  /// In ru, this message translates to:
  /// **'Меню прогулки'**
  String get message252;

  /// No description provided for @message253.
  ///
  /// In ru, this message translates to:
  /// **'Я на месте'**
  String get message253;

  /// No description provided for @message254.
  ///
  /// In ru, this message translates to:
  /// **'Место закрыто · демосценарий'**
  String get message254;

  /// No description provided for @message255.
  ///
  /// In ru, this message translates to:
  /// **'Погода изменилась · демосценарий'**
  String get message255;

  /// No description provided for @message256.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть замену'**
  String get message256;

  /// No description provided for @message257.
  ///
  /// In ru, this message translates to:
  /// **'Почему идём сюда'**
  String get message257;

  /// No description provided for @message258.
  ///
  /// In ru, this message translates to:
  /// **'Около 20 минут на месте'**
  String get message258;

  /// No description provided for @message259.
  ///
  /// In ru, this message translates to:
  /// **'бесплатный при наружном осмотре'**
  String get message259;

  /// No description provided for @message260.
  ///
  /// In ru, this message translates to:
  /// **'по условиям маршрута'**
  String get message260;

  /// No description provided for @message261.
  ///
  /// In ru, this message translates to:
  /// **'Вход {value0} · покупки по желанию'**
  String message261(String value0);

  /// No description provided for @message262.
  ///
  /// In ru, this message translates to:
  /// **'Для осмотра с улицы бронирование не требуется'**
  String get message262;

  /// No description provided for @message263.
  ///
  /// In ru, this message translates to:
  /// **'Путь к остановке'**
  String get message263;

  /// No description provided for @message264.
  ///
  /// In ru, this message translates to:
  /// **'Вы идёте к стартовой точке. Доезд и подход до неё в длину маршрута не включены.'**
  String get message264;

  /// No description provided for @message265.
  ///
  /// In ru, this message translates to:
  /// **'После замены: подготовленный переход около 550 м · 10 минут'**
  String get message265;

  /// No description provided for @message266.
  ///
  /// In ru, this message translates to:
  /// **'Подготовленный переход около {value0} м · 8–12 минут'**
  String message266(String value0);

  /// No description provided for @message267.
  ///
  /// In ru, this message translates to:
  /// **'Переход оценён ориентировочно; проверьте безопасный пеший путь в картах.'**
  String get message267;

  /// No description provided for @message268.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в картах'**
  String get message268;

  /// No description provided for @message269.
  ///
  /// In ru, this message translates to:
  /// **'Следующее место откроется после этой остановки.'**
  String get message269;

  /// No description provided for @message270.
  ///
  /// In ru, this message translates to:
  /// **'Место закрыто или не подходит'**
  String get message270;

  /// No description provided for @message271.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить остановку'**
  String get message271;

  /// No description provided for @message272.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть карты'**
  String get message272;

  /// No description provided for @message273.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать адрес'**
  String get message273;

  /// No description provided for @message274.
  ///
  /// In ru, this message translates to:
  /// **'Адрес скопирован'**
  String get message274;

  /// No description provided for @message275.
  ///
  /// In ru, this message translates to:
  /// **'Ваша прогулка'**
  String get message275;

  /// No description provided for @message276.
  ///
  /// In ru, this message translates to:
  /// **'Все остановки'**
  String get message276;

  /// No description provided for @message277.
  ///
  /// In ru, this message translates to:
  /// **'Поставить на паузу'**
  String get message277;

  /// No description provided for @message278.
  ///
  /// In ru, this message translates to:
  /// **'Изменить миссии'**
  String get message278;

  /// No description provided for @message279.
  ///
  /// In ru, this message translates to:
  /// **'Раскрыть весь маршрут'**
  String get message279;

  /// No description provided for @message280.
  ///
  /// In ru, this message translates to:
  /// **'Показать все места?'**
  String get message280;

  /// No description provided for @message281.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть эффект сюрприза в этой прогулке уже не получится.'**
  String get message281;

  /// No description provided for @message282.
  ///
  /// In ru, this message translates to:
  /// **'Показать места'**
  String get message282;

  /// No description provided for @message283.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут раскрыт'**
  String get message283;

  /// No description provided for @message284.
  ///
  /// In ru, this message translates to:
  /// **'Завершить прогулку'**
  String get message284;

  /// No description provided for @message285.
  ///
  /// In ru, this message translates to:
  /// **'Миссии этой прогулки'**
  String get message285;

  /// No description provided for @message286.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get message286;

  /// No description provided for @message287.
  ///
  /// In ru, this message translates to:
  /// **'Завершить прогулку сейчас?'**
  String get message287;

  /// No description provided for @message288.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get message288;

  /// No description provided for @message289.
  ///
  /// In ru, this message translates to:
  /// **'Нет времени'**
  String get message289;

  /// No description provided for @message290.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить это место?'**
  String get message290;

  /// No description provided for @message291.
  ///
  /// In ru, this message translates to:
  /// **'Место не попадёт в посещённый атлас. Причину можно не указывать.'**
  String get message291;

  /// No description provided for @message292.
  ///
  /// In ru, this message translates to:
  /// **'Неинтересно'**
  String get message292;

  /// No description provided for @message293.
  ///
  /// In ru, this message translates to:
  /// **'Устал / устала'**
  String get message293;

  /// No description provided for @message294.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get message294;

  /// No description provided for @message295.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get message295;

  /// No description provided for @message296.
  ///
  /// In ru, this message translates to:
  /// **'Схема'**
  String get message296;

  /// No description provided for @message297.
  ///
  /// In ru, this message translates to:
  /// **'Остановка {value0} · следующее открытие'**
  String message297(String value0);

  /// No description provided for @message298.
  ///
  /// In ru, this message translates to:
  /// **'{value0} · около 20 минут'**
  String message298(String value0);

  /// No description provided for @message299.
  ///
  /// In ru, this message translates to:
  /// **'Это место откроется после текущей остановки.'**
  String get message299;

  /// No description provided for @message300.
  ///
  /// In ru, this message translates to:
  /// **'Впереди один выбор направления. Места веток пока скрыты.'**
  String get message300;

  /// No description provided for @message301.
  ///
  /// In ru, this message translates to:
  /// **'Посещена'**
  String get message301;

  /// No description provided for @message302.
  ///
  /// In ru, this message translates to:
  /// **'Пропущена'**
  String get message302;

  /// No description provided for @message303.
  ///
  /// In ru, this message translates to:
  /// **'Текущая'**
  String get message303;

  /// No description provided for @message304.
  ///
  /// In ru, this message translates to:
  /// **'Заменена'**
  String get message304;

  /// No description provided for @message305.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get message305;

  /// No description provided for @message306.
  ///
  /// In ru, this message translates to:
  /// **'Просмотр места не подтверждает посещение. Порядок прогулки сохраняется.'**
  String get message306;

  /// No description provided for @message307.
  ///
  /// In ru, this message translates to:
  /// **'Остановка {value0}'**
  String message307(String value0);

  /// No description provided for @message308.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать, куда дальше'**
  String get message308;

  /// No description provided for @message309.
  ///
  /// In ru, this message translates to:
  /// **'Открыть следующую остановку'**
  String get message309;

  /// No description provided for @message310.
  ///
  /// In ru, this message translates to:
  /// **'Что заметить'**
  String get message310;

  /// No description provided for @message311.
  ///
  /// In ru, this message translates to:
  /// **'Что можно попробовать'**
  String get message311;

  /// No description provided for @message312.
  ///
  /// In ru, this message translates to:
  /// **'Практические сведения'**
  String get message312;

  /// No description provided for @message313.
  ///
  /// In ru, this message translates to:
  /// **'Длительность зависит от вашего темпа; вход внутрь не обязателен.'**
  String get message313;

  /// No description provided for @message314.
  ///
  /// In ru, this message translates to:
  /// **'Добавить заметку'**
  String get message314;

  /// No description provided for @message315.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get message315;

  /// No description provided for @message316.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать здесь'**
  String get message316;

  /// No description provided for @message317.
  ///
  /// In ru, this message translates to:
  /// **'{value0} · 3–5 минут · можно пропустить'**
  String message317(String value0);

  /// No description provided for @message318.
  ///
  /// In ru, this message translates to:
  /// **'Покупка по желанию · есть бесплатный вариант'**
  String get message318;

  /// No description provided for @message319.
  ///
  /// In ru, this message translates to:
  /// **'Открыть идею'**
  String get message319;

  /// No description provided for @message320.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к истории'**
  String get message320;

  /// No description provided for @message321.
  ///
  /// In ru, this message translates to:
  /// **'Сделано'**
  String get message321;

  /// No description provided for @message322.
  ///
  /// In ru, this message translates to:
  /// **'Миссия выполнена'**
  String get message322;

  /// No description provided for @message323.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить задание'**
  String get message323;

  /// No description provided for @message324.
  ///
  /// In ru, this message translates to:
  /// **'Выберите вкус, который раньше не пробовали. Можно просто рассмотреть витрину и узнать название блюда.'**
  String get message324;

  /// No description provided for @message325.
  ///
  /// In ru, this message translates to:
  /// **'Если хозяин не занят и вам комфортно, спросите, какая деталь этого места ему особенно нравится.'**
  String get message325;

  /// No description provided for @message326.
  ///
  /// In ru, this message translates to:
  /// **'Примерно 3–5 минут · без проверки и таймера'**
  String get message326;

  /// No description provided for @message327.
  ///
  /// In ru, this message translates to:
  /// **'Расходы'**
  String get message327;

  /// No description provided for @message328.
  ///
  /// In ru, this message translates to:
  /// **'Покупки добровольные. Уточните цену и состав до заказа. Можно рассмотреть витрину и выполнить миссию без расходов.'**
  String get message328;

  /// No description provided for @message329.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно. Разговор и любые покупки добровольны.'**
  String get message329;

  /// No description provided for @message330.
  ///
  /// In ru, this message translates to:
  /// **'Миссия пропущена'**
  String get message330;

  /// No description provided for @message331.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить впечатление'**
  String get message331;

  /// No description provided for @message332.
  ///
  /// In ru, this message translates to:
  /// **'Заметка и фотография необязательны.'**
  String get message332;

  /// No description provided for @message333.
  ///
  /// In ru, this message translates to:
  /// **'Выбор направления'**
  String get message333;

  /// No description provided for @message334.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать направление'**
  String get message334;

  /// No description provided for @message335.
  ///
  /// In ru, this message translates to:
  /// **'Куда повернём дальше?'**
  String get message335;

  /// No description provided for @message336.
  ///
  /// In ru, this message translates to:
  /// **'Обе ветки недоступны в демонстрационном состоянии. Посещённые места сохранятся.'**
  String get message336;

  /// No description provided for @message337.
  ///
  /// In ru, this message translates to:
  /// **'Оба варианта подходят вашим условиям.'**
  String get message337;

  /// No description provided for @message338.
  ///
  /// In ru, this message translates to:
  /// **'Хочется необычного'**
  String get message338;

  /// No description provided for @message339.
  ///
  /// In ru, this message translates to:
  /// **'Спокойное место, где можно немного замедлиться.'**
  String get message339;

  /// No description provided for @message340.
  ///
  /// In ru, this message translates to:
  /// **'Пространство с неожиданной деталью и собственной историей.'**
  String get message340;

  /// No description provided for @message341.
  ///
  /// In ru, this message translates to:
  /// **'Базовая ветка · дополнительных расходов нет'**
  String get message341;

  /// No description provided for @message342.
  ///
  /// In ru, this message translates to:
  /// **'+15 минут · +400 м · дополнительных расходов нет'**
  String get message342;

  /// No description provided for @message343.
  ///
  /// In ru, this message translates to:
  /// **'Доступность — согласно условиям выбранного маршрута'**
  String get message343;

  /// No description provided for @message344.
  ///
  /// In ru, this message translates to:
  /// **'Замена остановки'**
  String get message344;

  /// No description provided for @message345.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать замену'**
  String get message345;

  /// No description provided for @message346.
  ///
  /// In ru, this message translates to:
  /// **'Изменим планы?'**
  String get message346;

  /// No description provided for @message347.
  ///
  /// In ru, this message translates to:
  /// **'Выберите причину. Она поможет сохранить контекст этой прогулки.'**
  String get message347;

  /// No description provided for @message348.
  ///
  /// In ru, this message translates to:
  /// **'Слишком многолюдно'**
  String get message348;

  /// No description provided for @message349.
  ///
  /// In ru, this message translates to:
  /// **'Изменилась погода'**
  String get message349;

  /// No description provided for @message350.
  ///
  /// In ru, this message translates to:
  /// **'Не хочется сюда'**
  String get message350;

  /// No description provided for @message351.
  ///
  /// In ru, this message translates to:
  /// **'Трудно добраться'**
  String get message351;

  /// No description provided for @message352.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий — необязательно'**
  String get message352;

  /// No description provided for @message353.
  ///
  /// In ru, this message translates to:
  /// **'Подготовленная альтернатива'**
  String get message353;

  /// No description provided for @message354.
  ///
  /// In ru, this message translates to:
  /// **'Для этой остановки пока нет подходящей замены.'**
  String get message354;

  /// No description provided for @message355.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить и продолжить'**
  String get message355;

  /// No description provided for @message356.
  ///
  /// In ru, this message translates to:
  /// **'Другое небольшое открытие'**
  String get message356;

  /// No description provided for @message357.
  ///
  /// In ru, this message translates to:
  /// **'Подготовленное место поблизости. Новый взгляд на тему прогулки.'**
  String get message357;

  /// No description provided for @message358.
  ///
  /// In ru, this message translates to:
  /// **'Примерно на 10 минут дольше'**
  String get message358;

  /// No description provided for @message359.
  ///
  /// In ru, this message translates to:
  /// **'Расстояние пересчитывается по выбранным точкам'**
  String get message359;

  /// No description provided for @message360.
  ///
  /// In ru, this message translates to:
  /// **'Расходы не изменятся'**
  String get message360;

  /// No description provided for @message361.
  ///
  /// In ru, this message translates to:
  /// **'Подход к замене требует отдельной проверки'**
  String get message361;

  /// No description provided for @message362.
  ///
  /// In ru, this message translates to:
  /// **'Условия подхода указаны для конкретной замены'**
  String get message362;

  /// No description provided for @message363.
  ///
  /// In ru, this message translates to:
  /// **'Замена может превысить выбранный лимит времени. Вы можете пропустить остановку.'**
  String get message363;

  /// No description provided for @message364.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get message364;

  /// No description provided for @message365.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить прогулку'**
  String get message365;

  /// No description provided for @message366.
  ///
  /// In ru, this message translates to:
  /// **'После паузы расписание изменилось. Посмотрите замену.'**
  String get message366;

  /// No description provided for @message367.
  ///
  /// In ru, this message translates to:
  /// **'Можно никуда не спешить'**
  String get message367;

  /// No description provided for @message368.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс сохранён'**
  String get message368;

  /// No description provided for @message369.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться на главную'**
  String get message369;

  /// No description provided for @message370.
  ///
  /// In ru, this message translates to:
  /// **'Итоги прогулки'**
  String get message370;

  /// No description provided for @message371.
  ///
  /// In ru, this message translates to:
  /// **'Открыть атлас'**
  String get message371;

  /// No description provided for @message372.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get message372;

  /// No description provided for @message373.
  ///
  /// In ru, this message translates to:
  /// **'Ваша история дня'**
  String get message373;

  /// No description provided for @message374.
  ///
  /// In ru, this message translates to:
  /// **'У этой прогулки теперь есть ваша история'**
  String get message374;

  /// No description provided for @message375.
  ///
  /// In ru, this message translates to:
  /// **'Можно попробовать в другой день'**
  String get message375;

  /// No description provided for @message376.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня получилось вот такое приключение'**
  String get message376;

  /// No description provided for @message377.
  ///
  /// In ru, this message translates to:
  /// **'посещено мест'**
  String get message377;

  /// No description provided for @message378.
  ///
  /// In ru, this message translates to:
  /// **'миссий выполнено'**
  String get message378;

  /// No description provided for @message379.
  ///
  /// In ru, this message translates to:
  /// **'{value0} мин'**
  String message379(String value0);

  /// No description provided for @message380.
  ///
  /// In ru, this message translates to:
  /// **'с начала, без пауз'**
  String get message380;

  /// No description provided for @message381.
  ///
  /// In ru, this message translates to:
  /// **'расчётная дистанция'**
  String get message381;

  /// No description provided for @message382.
  ///
  /// In ru, this message translates to:
  /// **'Ваши открытия'**
  String get message382;

  /// No description provided for @message383.
  ///
  /// In ru, this message translates to:
  /// **'Вы завершили прогулку до первого посещения. Запись осталась в истории, а открытия появятся после следующего старта.'**
  String get message383;

  /// No description provided for @message384.
  ///
  /// In ru, this message translates to:
  /// **'Как вам прогулка?'**
  String get message384;

  /// No description provided for @message385.
  ///
  /// In ru, this message translates to:
  /// **'Не понравилась'**
  String get message385;

  /// No description provided for @message386.
  ///
  /// In ru, this message translates to:
  /// **'Скорее нет'**
  String get message386;

  /// No description provided for @message387.
  ///
  /// In ru, this message translates to:
  /// **'Нормально'**
  String get message387;

  /// No description provided for @message388.
  ///
  /// In ru, this message translates to:
  /// **'Хорошо'**
  String get message388;

  /// No description provided for @message389.
  ///
  /// In ru, this message translates to:
  /// **'Отлично'**
  String get message389;

  /// No description provided for @message390.
  ///
  /// In ru, this message translates to:
  /// **'Что понравилось?'**
  String get message390;

  /// No description provided for @message391.
  ///
  /// In ru, this message translates to:
  /// **'Места'**
  String get message391;

  /// No description provided for @message392.
  ///
  /// In ru, this message translates to:
  /// **'Ритм'**
  String get message392;

  /// No description provided for @message393.
  ///
  /// In ru, this message translates to:
  /// **'Миссии'**
  String get message393;

  /// No description provided for @message394.
  ///
  /// In ru, this message translates to:
  /// **'Развилка'**
  String get message394;

  /// No description provided for @message395.
  ///
  /// In ru, this message translates to:
  /// **'Что можно улучшить?'**
  String get message395;

  /// No description provided for @message396.
  ///
  /// In ru, this message translates to:
  /// **'Истории'**
  String get message396;

  /// No description provided for @message397.
  ///
  /// In ru, this message translates to:
  /// **'Выбор мест'**
  String get message397;

  /// No description provided for @message398.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв сохранён'**
  String get message398;

  /// No description provided for @message399.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить комментарий'**
  String get message399;

  /// No description provided for @message400.
  ///
  /// In ru, this message translates to:
  /// **'Времени хватило?'**
  String get message400;

  /// No description provided for @message401.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get message401;

  /// No description provided for @message402.
  ///
  /// In ru, this message translates to:
  /// **'Было мало'**
  String get message402;

  /// No description provided for @message403.
  ///
  /// In ru, this message translates to:
  /// **'Было с запасом'**
  String get message403;

  /// No description provided for @message404.
  ///
  /// In ru, this message translates to:
  /// **'Расходы совпали с ожиданиями?'**
  String get message404;

  /// No description provided for @message405.
  ///
  /// In ru, this message translates to:
  /// **'Выше'**
  String get message405;

  /// No description provided for @message406.
  ///
  /// In ru, this message translates to:
  /// **'Ниже'**
  String get message406;

  /// No description provided for @message407.
  ///
  /// In ru, this message translates to:
  /// **'Не отслеживал'**
  String get message407;

  /// No description provided for @message408.
  ///
  /// In ru, this message translates to:
  /// **'Обратную связь можно пропустить.'**
  String get message408;

  /// No description provided for @message409.
  ///
  /// In ru, this message translates to:
  /// **'Мой атлас'**
  String get message409;

  /// No description provided for @message410.
  ///
  /// In ru, this message translates to:
  /// **'История прогулок'**
  String get message410;

  /// No description provided for @message411.
  ///
  /// In ru, this message translates to:
  /// **'открытий'**
  String get message411;

  /// No description provided for @message412.
  ///
  /// In ru, this message translates to:
  /// **'городов'**
  String get message412;

  /// No description provided for @message413.
  ///
  /// In ru, this message translates to:
  /// **'прогулок'**
  String get message413;

  /// No description provided for @message414.
  ///
  /// In ru, this message translates to:
  /// **'Место или ваша заметка'**
  String get message414;

  /// No description provided for @message415.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get message415;

  /// No description provided for @message416.
  ///
  /// In ru, this message translates to:
  /// **'Карточки'**
  String get message416;

  /// No description provided for @message417.
  ///
  /// In ru, this message translates to:
  /// **'Здесь будут ваши открытия'**
  String get message417;

  /// No description provided for @message418.
  ///
  /// In ru, this message translates to:
  /// **'Начните прогулку — посещённые места сохранятся автоматически.'**
  String get message418;

  /// No description provided for @message419.
  ///
  /// In ru, this message translates to:
  /// **'Найти прогулку'**
  String get message419;

  /// No description provided for @message420.
  ///
  /// In ru, this message translates to:
  /// **'Нет таких открытий'**
  String get message420;

  /// No description provided for @message421.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другой запрос или тему.'**
  String get message421;

  /// No description provided for @message422.
  ///
  /// In ru, this message translates to:
  /// **'Ваше открытие'**
  String get message422;

  /// No description provided for @message423.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть открытие из атласа'**
  String get message423;

  /// No description provided for @message424.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть открытие?'**
  String get message424;

  /// No description provided for @message425.
  ///
  /// In ru, this message translates to:
  /// **'История посещений в прогулках сохранится.'**
  String get message425;

  /// No description provided for @message426.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get message426;

  /// No description provided for @message427.
  ///
  /// In ru, this message translates to:
  /// **'{value0}'**
  String message427(String value0);

  /// No description provided for @message428.
  ///
  /// In ru, this message translates to:
  /// **'Последнее посещение: {value0}'**
  String message428(String value0);

  /// No description provided for @message429.
  ///
  /// In ru, this message translates to:
  /// **'История места'**
  String get message429;

  /// No description provided for @message430.
  ///
  /// In ru, this message translates to:
  /// **'Связанные миссии'**
  String get message430;

  /// No description provided for @message431.
  ///
  /// In ru, this message translates to:
  /// **'Миссии добровольные. Посещение сохраняется независимо от выполнения.'**
  String get message431;

  /// No description provided for @message432.
  ///
  /// In ru, this message translates to:
  /// **'Личная заметка'**
  String get message432;

  /// No description provided for @message433.
  ///
  /// In ru, this message translates to:
  /// **'Какая деталь запомнилась вам больше всего?'**
  String get message433;

  /// No description provided for @message434.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать заметку'**
  String get message434;

  /// No description provided for @message435.
  ///
  /// In ru, this message translates to:
  /// **'Удалить личную заметку?'**
  String get message435;

  /// No description provided for @message436.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии и посещения сохранятся.'**
  String get message436;

  /// No description provided for @message437.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get message437;

  /// No description provided for @message438.
  ///
  /// In ru, this message translates to:
  /// **'Заметка удалена'**
  String get message438;

  /// No description provided for @message439.
  ///
  /// In ru, this message translates to:
  /// **'Удалить заметку'**
  String get message439;

  /// No description provided for @message440.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get message440;

  /// No description provided for @message441.
  ///
  /// In ru, this message translates to:
  /// **'Посещения'**
  String get message441;

  /// No description provided for @message442.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка удалена из истории'**
  String get message442;

  /// No description provided for @message443.
  ///
  /// In ru, this message translates to:
  /// **'Фотография добавлена'**
  String get message443;

  /// No description provided for @message444.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить фотографию. Можно продолжить без неё.'**
  String get message444;

  /// No description provided for @message445.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии удалены. Остальные данные сохранены.'**
  String get message445;

  /// No description provided for @message446.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фотографию'**
  String get message446;

  /// No description provided for @message447.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фотографию?'**
  String get message447;

  /// No description provided for @message448.
  ///
  /// In ru, this message translates to:
  /// **'Файл будет удалён из приложения.'**
  String get message448;

  /// No description provided for @message449.
  ///
  /// In ru, this message translates to:
  /// **'Завершена'**
  String get message449;

  /// No description provided for @message450.
  ///
  /// In ru, this message translates to:
  /// **'Завершена досрочно'**
  String get message450;

  /// No description provided for @message451.
  ///
  /// In ru, this message translates to:
  /// **'Незавершённая прогулка'**
  String get message451;

  /// No description provided for @message452.
  ///
  /// In ru, this message translates to:
  /// **'История ещё впереди'**
  String get message452;

  /// No description provided for @message453.
  ///
  /// In ru, this message translates to:
  /// **'Здесь сохранятся завершённые прогулки.'**
  String get message453;

  /// No description provided for @message454.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть маршруты'**
  String get message454;

  /// No description provided for @message455.
  ///
  /// In ru, this message translates to:
  /// **'Посещено {value0} · пропущено {value1}'**
  String message455(String value0, String value1);

  /// No description provided for @message456.
  ///
  /// In ru, this message translates to:
  /// **'История прогулки'**
  String get message456;

  /// No description provided for @message457.
  ///
  /// In ru, this message translates to:
  /// **'Пройти ещё раз'**
  String get message457;

  /// No description provided for @message458.
  ///
  /// In ru, this message translates to:
  /// **'Исходные условия'**
  String get message458;

  /// No description provided for @message459.
  ///
  /// In ru, this message translates to:
  /// **'{value0} · {value1} темп · до {value2} часов'**
  String message459(String value0, String value1, String value2);

  /// No description provided for @message460.
  ///
  /// In ru, this message translates to:
  /// **'Время с начала без пауз: {value0} мин'**
  String message460(String value0);

  /// No description provided for @message461.
  ///
  /// In ru, this message translates to:
  /// **'Расчётная дистанция: {value0} км'**
  String message461(String value0);

  /// No description provided for @message462.
  ///
  /// In ru, this message translates to:
  /// **'Остановка · не раскрыта'**
  String get message462;

  /// No description provided for @message463.
  ///
  /// In ru, this message translates to:
  /// **'Остановка была заменена'**
  String get message463;

  /// No description provided for @message464.
  ///
  /// In ru, this message translates to:
  /// **'Причина: {value0}'**
  String message464(String value0);

  /// No description provided for @message465.
  ///
  /// In ru, this message translates to:
  /// **'Открыть в атласе'**
  String get message465;

  /// No description provided for @message466.
  ///
  /// In ru, this message translates to:
  /// **'Заметки и фотографии'**
  String get message466;

  /// No description provided for @message467.
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get message467;

  /// No description provided for @message468.
  ///
  /// In ru, this message translates to:
  /// **'Оценка не оставлена'**
  String get message468;

  /// No description provided for @message469.
  ///
  /// In ru, this message translates to:
  /// **'Оценка: {value0} из 5'**
  String message469(String value0);

  /// No description provided for @message470.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть итоги и отзыв'**
  String get message470;

  /// No description provided for @message471.
  ///
  /// In ru, this message translates to:
  /// **'Открыть места в атласе'**
  String get message471;

  /// No description provided for @message472.
  ///
  /// In ru, this message translates to:
  /// **'Избранные маршруты'**
  String get message472;

  /// No description provided for @message473.
  ///
  /// In ru, this message translates to:
  /// **'Сохраните маршрут на потом'**
  String get message473;

  /// No description provided for @message474.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите закладку на понравившейся прогулке.'**
  String get message474;

  /// No description provided for @message475.
  ///
  /// In ru, this message translates to:
  /// **'Изменить имя'**
  String get message475;

  /// No description provided for @message476.
  ///
  /// In ru, this message translates to:
  /// **'Данные хранятся на этом устройстве'**
  String get message476;

  /// No description provided for @message477.
  ///
  /// In ru, this message translates to:
  /// **'Мои предпочтения'**
  String get message477;

  /// No description provided for @message478.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get message478;

  /// No description provided for @message479.
  ///
  /// In ru, this message translates to:
  /// **'Как работает приложение'**
  String get message479;

  /// No description provided for @message480.
  ///
  /// In ru, this message translates to:
  /// **'О демоверсии'**
  String get message480;

  /// No description provided for @message481.
  ///
  /// In ru, this message translates to:
  /// **'Данные сохраняются на этом устройстве. После удаления приложения они могут быть потеряны.'**
  String get message481;

  /// No description provided for @message482.
  ///
  /// In ru, this message translates to:
  /// **'Как вас называть?'**
  String get message482;

  /// No description provided for @message483.
  ///
  /// In ru, this message translates to:
  /// **'Имя — необязательно'**
  String get message483;

  /// No description provided for @message484.
  ///
  /// In ru, this message translates to:
  /// **'Исследователь'**
  String get message484;

  /// No description provided for @message485.
  ///
  /// In ru, this message translates to:
  /// **'Предпочтения сохранены'**
  String get message485;

  /// No description provided for @message486.
  ///
  /// In ru, this message translates to:
  /// **'Эти настройки применятся к следующему подбору. Текущая прогулка не изменится.'**
  String get message486;

  /// No description provided for @message487.
  ///
  /// In ru, this message translates to:
  /// **'Доступность'**
  String get message487;

  /// No description provided for @message488.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить предпочтения'**
  String get message488;

  /// No description provided for @message489.
  ///
  /// In ru, this message translates to:
  /// **'Внешний вид'**
  String get message489;

  /// No description provided for @message490.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get message490;

  /// No description provided for @message491.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get message491;

  /// No description provided for @message492.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get message492;

  /// No description provided for @message493.
  ///
  /// In ru, this message translates to:
  /// **'Поведение'**
  String get message493;

  /// No description provided for @message494.
  ///
  /// In ru, this message translates to:
  /// **'Тактильный отклик'**
  String get message494;

  /// No description provided for @message495.
  ///
  /// In ru, this message translates to:
  /// **'Уменьшение анимации'**
  String get message495;

  /// No description provided for @message496.
  ///
  /// In ru, this message translates to:
  /// **'Системная настройка также учитывается'**
  String get message496;

  /// No description provided for @message497.
  ///
  /// In ru, this message translates to:
  /// **'Данные'**
  String get message497;

  /// No description provided for @message498.
  ///
  /// In ru, this message translates to:
  /// **'Локальные фотографии: {value0} МБ'**
  String message498(String value0);

  /// No description provided for @message499.
  ///
  /// In ru, this message translates to:
  /// **'Очистить пользовательские фотографии'**
  String get message499;

  /// No description provided for @message500.
  ///
  /// In ru, this message translates to:
  /// **'Удалить историю'**
  String get message500;

  /// No description provided for @message501.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить все данные'**
  String get message501;

  /// No description provided for @message502.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрация'**
  String get message502;

  /// No description provided for @message503.
  ///
  /// In ru, this message translates to:
  /// **'Панель демонстрационных сценариев'**
  String get message503;

  /// No description provided for @message504.
  ///
  /// In ru, this message translates to:
  /// **' Активная прогулка тоже будет удалена.'**
  String get message504;

  /// No description provided for @message505.
  ///
  /// In ru, this message translates to:
  /// **'Будут удалены прогресс, история, избранное, заметки и фотографии из приложения.{value0}'**
  String message505(String value0);

  /// No description provided for @message506.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии будут удалены из приложения. Заметки и история сохранятся.'**
  String get message506;

  /// No description provided for @message507.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые прогулки будут удалены из истории. Открытия, заметки, фотографии и активная прогулка сохранятся.'**
  String get message507;

  /// No description provided for @message508.
  ///
  /// In ru, this message translates to:
  /// **'Удалить данные?'**
  String get message508;

  /// No description provided for @message509.
  ///
  /// In ru, this message translates to:
  /// **'Данные удалены'**
  String get message509;

  /// No description provided for @message510.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get message510;

  /// No description provided for @message511.
  ///
  /// In ru, this message translates to:
  /// **'Версия 1.0.0 · интерактивный прототип'**
  String get message511;

  /// No description provided for @message512.
  ///
  /// In ru, this message translates to:
  /// **'Город раскрывается по пути'**
  String get message512;

  /// No description provided for @message513.
  ///
  /// In ru, this message translates to:
  /// **'Выберите настроение, время и бюджет. Пройдите подготовленный маршрут, замечайте детали и сохраняйте свою историю дня.'**
  String get message513;

  /// No description provided for @message514.
  ///
  /// In ru, this message translates to:
  /// **'Вы управляете приключением'**
  String get message514;

  /// No description provided for @message515.
  ///
  /// In ru, this message translates to:
  /// **'Места открываются постепенно. Можно пропускать задания, заменять остановки, поставить прогулку на паузу или раскрыть весь маршрут.'**
  String get message515;

  /// No description provided for @message516.
  ///
  /// In ru, this message translates to:
  /// **'Локальное хранение'**
  String get message516;

  /// No description provided for @message517.
  ///
  /// In ru, this message translates to:
  /// **'Данные сохраняются на этом устройстве. После удаления приложения они могут быть потеряны. Синхронизация и резервное копирование не предусмотрены.'**
  String get message517;

  /// No description provided for @message518.
  ///
  /// In ru, this message translates to:
  /// **'Ограничения демоверсии'**
  String get message518;

  /// No description provided for @message519.
  ///
  /// In ru, this message translates to:
  /// **'В каталоге 75 активных прогулок: по 15 для Стамбула, Баку, Тбилиси, Дубая и Нячанга. Главный сценарий — поездки на 2–7 дней по вашему вайбу и району отеля. Интерес «Шопинг» добавляет магазины, рынки и торговые центры. Данные, фото и планы доступны офлайн. Координаты, окна визитов, расходы и переезды ориентировочные; это редакционный прототип, не проверенный пеший трек и не расписание транспорта. Там, где указан осмотр снаружи, платный вход не предполагается. Некоторые фото иллюстрируют город или район. Перед визитом уточняйте часы и доступ. Новая уличная карта и построение пешего пути требуют сети; сохранённый план работает без неё.'**
  String get message519;

  /// No description provided for @message520.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии: Wikimedia Commons и Unsplash. Шрифты: Cormorant Garamond, Manrope и Golos Text, SIL Open Font License.'**
  String get message520;

  /// No description provided for @message521.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть онбординг'**
  String get message521;

  /// No description provided for @message522.
  ///
  /// In ru, this message translates to:
  /// **'Демонстрационные сценарии'**
  String get message522;

  /// No description provided for @message523.
  ///
  /// In ru, this message translates to:
  /// **'Сценарии моделируют локальные состояния. Никакие данные не отправляются на сервер.'**
  String get message523;

  /// No description provided for @message524.
  ///
  /// In ru, this message translates to:
  /// **'Состояния'**
  String get message524;

  /// No description provided for @message525.
  ///
  /// In ru, this message translates to:
  /// **'Текущее место закрыто'**
  String get message525;

  /// No description provided for @message526.
  ///
  /// In ru, this message translates to:
  /// **'Плохая погода'**
  String get message526;

  /// No description provided for @message527.
  ///
  /// In ru, this message translates to:
  /// **'Замены недоступны'**
  String get message527;

  /// No description provided for @message528.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка открытия карт'**
  String get message528;

  /// No description provided for @message529.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сохранения'**
  String get message529;

  /// No description provided for @message530.
  ///
  /// In ru, this message translates to:
  /// **'Позднее время старта'**
  String get message530;

  /// No description provided for @message531.
  ///
  /// In ru, this message translates to:
  /// **'Подготовить состояние'**
  String get message531;

  /// No description provided for @message532.
  ///
  /// In ru, this message translates to:
  /// **'Новый пользователь'**
  String get message532;

  /// No description provided for @message533.
  ///
  /// In ru, this message translates to:
  /// **'Есть активная прогулка'**
  String get message533;

  /// No description provided for @message534.
  ///
  /// In ru, this message translates to:
  /// **'Заполненный атлас'**
  String get message534;

  /// No description provided for @message535.
  ///
  /// In ru, this message translates to:
  /// **'Подготовить демосостояние?'**
  String get message535;

  /// No description provided for @message536.
  ///
  /// In ru, this message translates to:
  /// **'Текущий прогресс будет заменён. Заметки и фотографии текущего набора будут удалены.'**
  String get message536;

  /// No description provided for @message537.
  ///
  /// In ru, this message translates to:
  /// **'Подготовить'**
  String get message537;

  /// No description provided for @message538.
  ///
  /// In ru, this message translates to:
  /// **'Заметка сохранена'**
  String get message538;

  /// No description provided for @message539.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить заметку. Попробуйте ещё раз.'**
  String get message539;

  /// No description provided for @message540.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения?'**
  String get message540;

  /// No description provided for @message541.
  ///
  /// In ru, this message translates to:
  /// **'Остаться'**
  String get message541;

  /// No description provided for @message542.
  ///
  /// In ru, this message translates to:
  /// **'Не сохранять'**
  String get message542;

  /// No description provided for @message543.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get message543;

  /// No description provided for @message544.
  ///
  /// In ru, this message translates to:
  /// **'Какая деталь останется с вами?'**
  String get message544;

  /// No description provided for @messageConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get messageConfirm;

  /// No description provided for @preparedTransition.
  ///
  /// In ru, this message translates to:
  /// **'Подготовленный переход: около {meters} м · {minutes} минут'**
  String preparedTransition(String meters, String minutes);

  /// No description provided for @unknownTransition.
  ///
  /// In ru, this message translates to:
  /// **'Для этого перехода нет подготовленного расчёта. Откройте адрес в картах.'**
  String get unknownTransition;

  /// No description provided for @currentEstimate.
  ///
  /// In ru, this message translates to:
  /// **'С учётом выбранного пути: около {minutes} мин · {distance} км. Обязательные расходы: {cost}.'**
  String currentEstimate(String minutes, String distance, String cost);

  /// No description provided for @budgetLimit.
  ///
  /// In ru, this message translates to:
  /// **'До {amount}'**
  String budgetLimit(String amount);

  /// No description provided for @errorOpenData.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть локальные данные. Повторите запуск.'**
  String get errorOpenData;

  /// No description provided for @errorSaving.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Попробуйте ещё раз.'**
  String get errorSaving;

  /// No description provided for @errorBusy.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение уже выполняется'**
  String get errorBusy;

  /// No description provided for @errorActiveTrip.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть активная прогулка'**
  String get errorActiveTrip;

  /// No description provided for @recoveryNotice.
  ///
  /// In ru, this message translates to:
  /// **'Локальные данные восстановлены в безопасном режиме. Исходная запись сохранена; фотографии и заметки не удалялись.'**
  String get recoveryNotice;

  /// No description provided for @replacementReason.
  ///
  /// In ru, this message translates to:
  /// **'Почему меняем остановку?'**
  String get replacementReason;

  /// No description provided for @showAlternatives.
  ///
  /// In ru, this message translates to:
  /// **'Показать альтернативы'**
  String get showAlternatives;

  /// No description provided for @changeReason.
  ///
  /// In ru, this message translates to:
  /// **'Изменить причину'**
  String get changeReason;

  /// No description provided for @placeMenu.
  ///
  /// In ru, this message translates to:
  /// **'Действия с местом'**
  String get placeMenu;

  /// No description provided for @noReplacement.
  ///
  /// In ru, this message translates to:
  /// **'Для этой остановки пока нет подходящей замены.'**
  String get noReplacement;

  /// No description provided for @budgetEconomy.
  ///
  /// In ru, this message translates to:
  /// **'Экономно · до {amount}'**
  String budgetEconomy(String amount);

  /// No description provided for @budgetModerate.
  ///
  /// In ru, this message translates to:
  /// **'Умеренно · до {amount}'**
  String budgetModerate(String amount);

  /// No description provided for @placePracticalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перед визитом'**
  String get placePracticalTitle;

  /// No description provided for @placeHoursLabel.
  ///
  /// In ru, this message translates to:
  /// **'Когда прийти'**
  String get placeHoursLabel;

  /// No description provided for @placeAccessLabel.
  ///
  /// In ru, this message translates to:
  /// **'Подход и доступность'**
  String get placeAccessLabel;

  /// No description provided for @placeSourceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Источники о месте'**
  String get placeSourceLabel;

  /// No description provided for @placeImageCaption.
  ///
  /// In ru, this message translates to:
  /// **'Фотография места или его окрестностей'**
  String get placeImageCaption;

  /// No description provided for @placeCheckedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Справочная информация проверена 22.10.2026'**
  String get placeCheckedLabel;

  /// No description provided for @routePracticalTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как спланировать прогулку'**
  String get routePracticalTitle;

  /// No description provided for @routeTransportLabel.
  ///
  /// In ru, this message translates to:
  /// **'До старта и обратно'**
  String get routeTransportLabel;

  /// No description provided for @routeEstimatesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Как читать оценки'**
  String get routeEstimatesLabel;

  /// No description provided for @sourcesOffline.
  ///
  /// In ru, this message translates to:
  /// **'Ссылки открываются в браузере при наличии интернета. Все сведения для прогулки сохранены в приложении.'**
  String get sourcesOffline;

  /// No description provided for @photoCreditsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии и авторы'**
  String get photoCreditsTitle;

  /// No description provided for @photoCreditsChanges.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии уменьшены и сжаты; в карточках кадрируются.'**
  String get photoCreditsChanges;

  /// No description provided for @replacementDistance.
  ///
  /// In ru, this message translates to:
  /// **'После замены — около {km} км на всю прогулку'**
  String replacementDistance(String km);

  /// No description provided for @nearbyResultsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Есть несколько близких вариантов'**
  String get nearbyResultsTitle;

  /// No description provided for @nearbyResultsBody.
  ///
  /// In ru, this message translates to:
  /// **'Точного совпадения сейчас нет. Вот приключения с минимальными изменениями условий. Перед выбором покажем каждое изменение — ваши ограничения сами не изменятся.'**
  String get nearbyResultsBody;

  /// No description provided for @nearbyResultBadge.
  ///
  /// In ru, this message translates to:
  /// **'Можно подобрать, изменив условия'**
  String get nearbyResultBadge;

  /// No description provided for @acceptSuggestionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Условия этого приключения'**
  String get acceptSuggestionTitle;

  /// No description provided for @acceptSuggestionBody.
  ///
  /// In ru, this message translates to:
  /// **'Для этого варианта нужно изменить следующие параметры. Если это вам не подходит, вернитесь к подбору.'**
  String get acceptSuggestionBody;

  /// No description provided for @acceptSuggestionButton.
  ///
  /// In ru, this message translates to:
  /// **'Применить условия и посмотреть'**
  String get acceptSuggestionButton;

  /// No description provided for @changeTime.
  ///
  /// In ru, this message translates to:
  /// **'Выделить {value} мин'**
  String changeTime(String value);

  /// No description provided for @changeDistance.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить дистанцию до {value} км'**
  String changeDistance(String value);

  /// No description provided for @changeBudget.
  ///
  /// In ru, this message translates to:
  /// **'Бюджет до {value}'**
  String changeBudget(String value);

  /// No description provided for @changeStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать в {value}'**
  String changeStart(String value);

  /// No description provided for @changeDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата старта: {value}'**
  String changeDate(String value);

  /// No description provided for @changeStairs.
  ///
  /// In ru, this message translates to:
  /// **'Снять ограничение «без лестниц»: подход не подтверждён'**
  String get changeStairs;

  /// No description provided for @changeStroller.
  ///
  /// In ru, this message translates to:
  /// **'Снять требование прогулки с коляской: подход не подтверждён'**
  String get changeStroller;

  /// No description provided for @changeIndoors.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать прогулку на открытом воздухе'**
  String get changeIndoors;

  /// No description provided for @changeRest.
  ///
  /// In ru, this message translates to:
  /// **'Снять требование подтверждённых мест для отдыха'**
  String get changeRest;

  /// No description provided for @changeCompany.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать другой состав компании'**
  String get changeCompany;

  /// No description provided for @changeDiet.
  ///
  /// In ru, this message translates to:
  /// **'Изменить пищевые предпочтения — меню не проверено'**
  String get changeDiet;

  /// No description provided for @nearbyShortBadge.
  ///
  /// In ru, this message translates to:
  /// **'Близкий вариант'**
  String get nearbyShortBadge;

  /// No description provided for @navConsentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Путь от вашего местоположения'**
  String get navConsentTitle;

  /// No description provided for @navConsentBody.
  ///
  /// In ru, this message translates to:
  /// **'Приложение запросит геолокацию. Чтобы построить и обновлять пеший путь, координаты вашего положения и текущей остановки будут отправляться сервису FOSSGIS (routing.openstreetmap.de). Сервис может сохранять запросы в журнале. Уличную карту предоставляет OpenStreetMap.'**
  String get navConsentBody;

  /// No description provided for @navConsentLocal.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация работает, пока открыт экран прогулки или его карта. При сворачивании и уходе с экрана отслеживание останавливается. Пройденный след хранится только в памяти; полученный путь сохраняется на устройстве для работы без связи.'**
  String get navConsentLocal;

  /// No description provided for @navConsentAccept.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить построение пути'**
  String get navConsentAccept;

  /// No description provided for @navLocating.
  ///
  /// In ru, this message translates to:
  /// **'Определяем ваше положение…'**
  String get navLocating;

  /// No description provided for @navPermissionDenied.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к геолокации не разрешён. Можно повторить запрос или продолжить по адресу без отслеживания.'**
  String get navPermissionDenied;

  /// No description provided for @navPermissionForever.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация заблокирована. Разрешите доступ в настройках устройства или браузера, затем повторите попытку.'**
  String get navPermissionForever;

  /// No description provided for @navServicesOff.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация на устройстве выключена. Включите её и повторите попытку.'**
  String get navServicesOff;

  /// No description provided for @navLocationTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет сигнала геолокации. Выйдите на открытое место или повторите попытку.'**
  String get navLocationTimeout;

  /// No description provided for @navLocationUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить положение. Проверьте разрешение и настройки геолокации. В браузере нужны HTTPS или localhost.'**
  String get navLocationUnavailable;

  /// No description provided for @navRouteNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить пеший путь. Проверьте связь и повторите попытку; ранее полученная линия остаётся на карте.'**
  String get navRouteNetwork;

  /// No description provided for @navNoRoute.
  ///
  /// In ru, this message translates to:
  /// **'Сервис не нашёл подходящий пеший путь. Сверьте точку и адрес или откройте внешние карты.'**
  String get navNoRoute;

  /// No description provided for @navTooFar.
  ///
  /// In ru, this message translates to:
  /// **'Вы далеко от остановки — больше 30 км. Доберитесь до района прогулки или посмотрите пример с условным стартом.'**
  String get navTooFar;

  /// No description provided for @navPoorAccuracy.
  ///
  /// In ru, this message translates to:
  /// **'Положение слишком неточное для построения пути. Разрешите точное местоположение или подождите более точного GPS-сигнала.'**
  String get navPoorAccuracy;

  /// No description provided for @navNeedPosition.
  ///
  /// In ru, this message translates to:
  /// **'Для пути нужна свежая геолокация. Нажмите «Путь от меня».'**
  String get navNeedPosition;

  /// No description provided for @navRouting.
  ///
  /// In ru, this message translates to:
  /// **'Строим пеший путь по улицам…'**
  String get navRouting;

  /// No description provided for @navDemoExplanation.
  ///
  /// In ru, this message translates to:
  /// **'Пример пути с условной точкой старта рядом с текущей остановкой. Синяя точка в этом режиме — не ваше местоположение.'**
  String get navDemoExplanation;

  /// No description provided for @navStale.
  ///
  /// In ru, this message translates to:
  /// **'Положение не обновлялось больше 45 секунд. Точка может быть устаревшей; проверьте сигнал.'**
  String get navStale;

  /// No description provided for @navNear.
  ///
  /// In ru, this message translates to:
  /// **'Вы рядом с ориентиром остановки. Сверьте адрес и вход; прибытие подтверждается кнопкой «Я на месте».'**
  String get navNear;

  /// No description provided for @navCached.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённый пеший путь. Без свежей геолокации он не подтверждает ваше положение; проверьте актуальность перехода.'**
  String get navCached;

  /// No description provided for @navFollowing.
  ///
  /// In ru, this message translates to:
  /// **'Путь до текущей открытой остановки. При отклонении от линии пересчитаем его, когда доступна связь.'**
  String get navFollowing;

  /// No description provided for @navIntro.
  ///
  /// In ru, this message translates to:
  /// **'На карте — текущая открытая остановка. Включите путь от вашего положения или посмотрите пример.'**
  String get navIntro;

  /// No description provided for @navKm.
  ///
  /// In ru, this message translates to:
  /// **'км'**
  String get navKm;

  /// No description provided for @navMeters.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get navMeters;

  /// No description provided for @navMinutes.
  ///
  /// In ru, this message translates to:
  /// **'≈ {value} мин пешком'**
  String navMinutes(String value);

  /// No description provided for @navVisited.
  ///
  /// In ru, this message translates to:
  /// **'Посещённая остановка'**
  String get navVisited;

  /// No description provided for @navDestination.
  ///
  /// In ru, this message translates to:
  /// **'Текущая остановка'**
  String get navDestination;

  /// No description provided for @navDemoMarker.
  ///
  /// In ru, this message translates to:
  /// **'Условная позиция для примера'**
  String get navDemoMarker;

  /// No description provided for @navYou.
  ///
  /// In ru, this message translates to:
  /// **'Ваше положение'**
  String get navYou;

  /// No description provided for @navDemoBadge.
  ///
  /// In ru, this message translates to:
  /// **'Пример · условный старт'**
  String get navDemoBadge;

  /// No description provided for @navCachedBadge.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённый путь'**
  String get navCachedBadge;

  /// No description provided for @navWalkingBadge.
  ///
  /// In ru, this message translates to:
  /// **'К текущей остановке'**
  String get navWalkingBadge;

  /// No description provided for @navExpand.
  ///
  /// In ru, this message translates to:
  /// **'Развернуть карту'**
  String get navExpand;

  /// No description provided for @navFit.
  ///
  /// In ru, this message translates to:
  /// **'Показать весь путь'**
  String get navFit;

  /// No description provided for @navCenter.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть к моей точке'**
  String get navCenter;

  /// No description provided for @navFixMap.
  ///
  /// In ru, this message translates to:
  /// **'Сообщить об ошибке карты'**
  String get navFixMap;

  /// No description provided for @navIndoors.
  ///
  /// In ru, this message translates to:
  /// **'Карта ведёт к ориентиру входа в здание. Между остановками внутри пользуйтесь указателями и описаниями: навигации по этажам здесь нет.'**
  String get navIndoors;

  /// No description provided for @navAccessibility.
  ///
  /// In ru, this message translates to:
  /// **'Пешеходный сервис не гарантирует отсутствие ступеней и подход для коляски. Сверьте условия перехода до начала движения.'**
  String get navAccessibility;

  /// No description provided for @navAccuracy.
  ///
  /// In ru, this message translates to:
  /// **'Точность положения: около {value} м'**
  String navAccuracy(String value);

  /// No description provided for @navTilesRetry.
  ///
  /// In ru, this message translates to:
  /// **'Часть уличной карты недоступна · повторить'**
  String get navTilesRetry;

  /// No description provided for @navRefreshRoute.
  ///
  /// In ru, this message translates to:
  /// **'Обновить путь'**
  String get navRefreshRoute;

  /// No description provided for @navStart.
  ///
  /// In ru, this message translates to:
  /// **'Путь от меня'**
  String get navStart;

  /// No description provided for @navExample.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть пример'**
  String get navExample;

  /// No description provided for @navPauseExample.
  ///
  /// In ru, this message translates to:
  /// **'Пауза примера'**
  String get navPauseExample;

  /// No description provided for @navWalkExample.
  ///
  /// In ru, this message translates to:
  /// **'Пройти пример'**
  String get navWalkExample;

  /// No description provided for @navStopTracking.
  ///
  /// In ru, this message translates to:
  /// **'Остановить геолокацию'**
  String get navStopTracking;

  /// No description provided for @navOfflineNote.
  ///
  /// In ru, this message translates to:
  /// **'Новая уличная карта и новый расчёт пути требуют интернета. Полученная линия сохраняется локально. Координаты мест приблизительны — сверяйте адрес и вход.'**
  String get navOfflineNote;

  /// No description provided for @navFerry.
  ///
  /// In ru, this message translates to:
  /// **'В предложенном пути есть переправа. Расписание и стоимость проверьте отдельно; это не полностью пеший переход.'**
  String get navFerry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
