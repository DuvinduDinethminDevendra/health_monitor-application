import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <
      LocalizationsDelegate<dynamic>>[
    delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  String get localeName => locale.languageCode;

  // Translations
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'profileUpdated': 'Profile Updated Successfully!',
      'manageInterests': 'Manage Interests',
      'tailorExperience': 'Tailor your health experience',
      'saveAndDone': 'Save & Done',
      'profile': 'Smart Profile',
      'userNotFound': 'User not found.',
      'darkMode': 'Dark Appearance',
      'solidMatteSapphire': 'Solid Matte Sapphire',
      'solidMatteAlabaster': 'Solid Matte Alabaster',
      'language': 'Language',
      'addMore': 'Add More',
      'fullName': 'Full Name',
      'nameEmpty': 'Name cannot be empty',
      'ageLabel': 'Age',
      'genderLabel': 'Gender',
      'heightCm': 'Height (cm)',
      'weightKg': 'Weight (kg)',
      'save': 'Save Profile Data',
      'fitness': 'Fitness',
      'diet': 'Diet',
      'meditation': 'Meditation',
      'hydration': 'Hydration',
      'weightLoss': 'Weight Loss',
      'muscleGain': 'Muscle Gain',
      'sleep': 'Sleep',
      'running': 'Running',
      'yoga': 'Yoga',
      'healthyHabits': 'Healthy Habits',
      'dietNutrition': 'Diet & Nutrition',
      'mentalHealth': 'Mental Health',
      'sleepTracking': 'Sleep Tracking',
      'cardio': 'Cardio',
      'strengthTraining': 'Strength Training',
      'flexibility': 'Yoga & Flexibility',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'notSpecified': 'Not Specified',
    },
    'si': {
      'profileUpdated': 'පැතිකඩ සාර්ථකව යාවත්කාලීන කරන ලදි!',
      'manageInterests': 'රුචිකත්වයන් කළමනාකරණය',
      'tailorExperience': 'ඔබේ සෞඛ්‍ය අත්දැකීම සකසා ගන්න',
      'saveAndDone': 'සුරකින්න',
      'profile': 'ඔබේ පැතිකඩ',
      'userNotFound': 'පරිශීලකයා හමු නොවීය.',
      'darkMode': 'අඳුරු තේමාව',
      'solidMatteSapphire': 'තද නිල් පැහැය',
      'solidMatteAlabaster': 'සුදු පැහැය',
      'language': 'භාෂාව',
      'addMore': 'තව එකතු කරන්න',
      'fullName': 'සම්පූර්ණ නම',
      'nameEmpty': 'නම හිස් විය නොහැක',
      'ageLabel': 'වයස',
      'genderLabel': 'ස්ත්‍රී/පුරුෂ භාවය',
      'heightCm': 'උස (cm)',
      'weightKg': 'බර (kg)',
      'save': 'දත්ත සුරකින්න',
      'fitness': 'යෝග්‍යතාව',
      'diet': 'ආහාර',
      'meditation': 'භාවනා',
      'hydration': 'ජල පරිභෝජනය',
      'weightLoss': 'බර අඩු කිරීම',
      'muscleGain': 'මාංශ පේශි වර්ධනය',
      'sleep': 'නින්ද',
      'running': 'දිවීම',
      'yoga': 'යෝගා',
      'healthyHabits': 'යහපත් පුරුදු',
      'dietNutrition': 'ආහාර සහ පෝෂණය',
      'mentalHealth': 'මානසික සෞඛ්‍ය',
      'sleepTracking': 'නින්ද නිරීක්ෂණය',
      'cardio': 'හෘද ව්‍යායාම',
      'strengthTraining': 'ශක්තිමත් කිරීමේ ව්‍යායාම',
      'flexibility': 'යෝගා සහ නම්‍යශීලිත්වය',
      'male': 'පුරුෂ',
      'female': 'ස්ත්‍රී',
      'other': 'වෙනත්',
      'notSpecified': 'සඳහන් කර නැත',
    },
  };

  String get profileUpdated => _localizedValues[locale.languageCode]!['profileUpdated']!;
  String get manageInterests => _localizedValues[locale.languageCode]!['manageInterests']!;
  String get tailorExperience => _localizedValues[locale.languageCode]!['tailorExperience']!;
  String get saveAndDone => _localizedValues[locale.languageCode]!['saveAndDone']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get userNotFound => _localizedValues[locale.languageCode]!['userNotFound']!;
  String get darkMode => _localizedValues[locale.languageCode]!['darkMode']!;
  String get solidMatteSapphire => _localizedValues[locale.languageCode]!['solidMatteSapphire']!;
  String get solidMatteAlabaster => _localizedValues[locale.languageCode]!['solidMatteAlabaster']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get addMore => _localizedValues[locale.languageCode]!['addMore']!;
  String get fullName => _localizedValues[locale.languageCode]!['fullName']!;
  String get nameEmpty => _localizedValues[locale.languageCode]!['nameEmpty']!;
  String get ageLabel => _localizedValues[locale.languageCode]!['ageLabel']!;
  String get genderLabel => _localizedValues[locale.languageCode]!['genderLabel']!;
  String get heightCm => _localizedValues[locale.languageCode]!['heightCm']!;
  String get weightKg => _localizedValues[locale.languageCode]!['weightKg']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get fitness => _localizedValues[locale.languageCode]!['fitness']!;
  String get diet => _localizedValues[locale.languageCode]!['diet']!;
  String get meditation => _localizedValues[locale.languageCode]!['meditation']!;
  String get hydration => _localizedValues[locale.languageCode]!['hydration']!;
  String get weightLoss => _localizedValues[locale.languageCode]!['weightLoss']!;
  String get muscleGain => _localizedValues[locale.languageCode]!['muscleGain']!;
  String get sleep => _localizedValues[locale.languageCode]!['sleep']!;
  String get running => _localizedValues[locale.languageCode]!['running']!;
  String get yoga => _localizedValues[locale.languageCode]!['yoga']!;
  String get healthyHabits => _localizedValues[locale.languageCode]!['healthyHabits']!;
  String get dietNutrition => _localizedValues[locale.languageCode]!['dietNutrition']!;
  String get mentalHealth => _localizedValues[locale.languageCode]!['mentalHealth']!;
  String get sleepTracking => _localizedValues[locale.languageCode]!['sleepTracking']!;
  String get cardio => _localizedValues[locale.languageCode]!['cardio']!;
  String get strengthTraining => _localizedValues[locale.languageCode]!['strengthTraining']!;
  String get flexibility => _localizedValues[locale.languageCode]!['flexibility']!;
  String get male => _localizedValues[locale.languageCode]!['male']!;
  String get female => _localizedValues[locale.languageCode]!['female']!;
  String get other => _localizedValues[locale.languageCode]!['other']!;
  String get notSpecified => _localizedValues[locale.languageCode]!['notSpecified']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
