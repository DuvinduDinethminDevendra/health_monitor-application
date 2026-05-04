import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
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
      'favorites': 'Favorites',
      'recent': 'Recent',
      'trending': 'Trending',
      'nutrition': 'Nutrition',
      // Dashboard Strings
      'dailyProgress': 'Daily Progress',
      'healthAtGlance': 'Your health at a glance',
      'activeGoals': 'Active Goals',
      'healthState': 'Health State',
      'stepsToday': 'Steps Today',
      'optimal': 'Optimal',
      'activity': 'Activity',
      'goals': 'Goals',
      'health': 'Health',
      'currentBmi': 'Current BMI',
      'healthTips': 'Health Tips',
      'explore': 'Explore',
      'quickActions': 'Quick Actions',
      'healthLogs': 'Health Logs',
      'reminders': 'Reminders',
      'keepPushing': 'Keep pushing, ',
      'healthJourneyGreat': 'Your health journey is looking great.',
      'home': 'Home',
      'progress': 'Progress',
      'activeGoalsUpper': 'ACTIVE GOALS',
      'healthStateUpper': 'HEALTH STATE',
      'stepsTodayUpper': 'STEPS TODAY',
      // Health Tips Strings
      'loadOfflineTips': 'Load Offline Tips',
      'noTipsFound': 'No health tips found for that keyword.',
      'readAndSave': 'Read & Save',
      'readAndSaveDesc': 'Tap any card to read the full article, or tap the heart to save it offline.',
      'sourceHealthGov': 'Source: MyHealthfinder (health.gov)',
      'searchTips': 'Search Tips',
      'searchTipsDesc': 'Type here to find specific health advice or keywords.',
      'searchHint': 'Search health tips...',
      'dataSource': 'Data Source:',
      'healthfinderApi': 'MyHealthfinder API (health.gov)',
      'healthGovInfo': 'Information provided by the Office of Disease Prevention and Health Promotion, U.S. Department of Health and Human Services.',
      'saveOffline': 'Save Offline',
      'saveOfflineDesc': 'Tap the heart to save this article to your Favorites for offline reading.',
      'removedFav': 'Removed from Favorites',
      'savedFav': 'Saved to Favorites!',
      'spreadWord': 'Spread the Word',
      'spreadWordDesc': 'Share this helpful health tip with your friends and family.',
      // Reminders Strings
      'healthReminders': 'Health Reminders',
      'selected': 'selected',
      'newReminder': 'New Reminder',
      'delete': 'Delete',
      'deleteReminder': 'Delete Reminder',
      'confirmDeleteMsg': 'Are you sure you want to delete',
      'cancel': 'Cancel',
      'stayOnTrack': 'Stay On Track',
      'enableRemindersDesc': 'Enable reminders to maintain healthy habits',
      'noTime': 'No time',
      'more': 'more',
      'custom': 'Custom',

      // Phase 2 Strings
      'activityTypeWalking': 'Walking',
      'activityTypeRunning': 'Running',
      'activityTypeCycling': 'Cycling',
      'activityTypeGym': 'Gym',
      'activityTypeYoga': 'Yoga',
      'activityTypeSwimming': 'Swimming',
      'activityTypeOther': 'Other',
      'activityTypeCustom': 'Custom',
      'greetingMorning': 'Good Morning',
      'greetingAfternoon': 'Good Afternoon',
      'greetingEvening': 'Good Evening',
      'greetingHello': 'Hello, ',
      'syncedAt': 'Synced',
      'syncing': 'Syncing...',
      'statDistance': 'Distance',
      'statCalories': 'Calories',
      'statActive': 'Active',
      'unitKm': 'km',
      'unitKcal': 'kcal',
      'unitMin': 'min',
      'btnStartWorkout': 'Start\nWorkout',
      'btnLogActivity': 'Log\nActivity',
      'btnHistory': 'History',
      'sectionWeeklyActivity': 'Weekly Activity',
      'btnDetails': 'Details',
      'sectionGoalProgress': 'Goal Progress',
      'titleStepGoal': 'Step Goal',
      'titleWorkoutGoal': 'Workout Goal',
      'stepsRemaining': 'steps remaining',
      'goalReached': 'Daily goal reached! 🎉',
      'workoutsLeft': 'workout(s) left today',
      'workoutGoalComplete': 'Workout goal complete! 💪',
      'sectionRecentActivity': 'Recent Activity',
      'btnSeeAll': 'See All',
      'emptyRecentActivity': 'No recent activities recorded yet.\nStart moving to see your history here!',
      'chooseWorkoutType': 'Choose Workout Type',
      'btnCancel': 'Cancel',
      'errLoadHealthLogs': 'Failed to load health logs. Please try again.',
      'editData': 'Edit Data',
      'logHealthData': 'Log Health Data',
      'lblWaist': 'WAIST',
      'lblHip': 'HIP',
      'lblChest': 'CHEST',
      'lblBodyFat': 'BODY FAT',
      'estimatedBmi': 'Estimated BMI',
      'lblDate': 'DATE',
      'lblAdvancedMetrics': 'ADVANCED BODY METRICS',
      'txtAdvancedMetrics': 'Track these to unlock deeper body composition insights',
      'lblContextLifestyle': 'CONTEXT & LIFESTYLE',
      'btnAddCustomTag': 'Add Custom Tag',
      'btnEditTag': 'Edit Tag',
      'btnDelete': 'Delete',
      'btnAdd': 'Add',
      'btnSave': 'Save',
      'hintCustomTag': 'e.g., 🍷 Drank Alcohol',
      'titleHealthGoals': 'Health Goals',
      'noGoalsSet': 'No goals set yet',
      'tapToAddGoal': 'Tap the + button to set your first goal',
      'btnLogProgress': 'Log Progress',
      'titleUpdateGoal': 'Update Goal',
      'lblCurrentValue': 'Current Value',
      'lblNewCurrentValue': 'New Current Value',
      'titleCreateNewGoal': 'Create New Goal',
      'titleEditGoal': 'Edit Goal',
      'lblGoalTitle': 'Goal Title',
      'hintGoalTitle': 'e.g. Take Vitamins',
      'lblSelectCategory': 'Select Goal Category',
      'lblCategoryType': 'Category / Tracking Type',
      'lblTargetValue': 'Target Value',
      'lblUnit': 'Unit',
      'btnSetReminder': 'Set Reminder',
      'btnCreateGoal': 'Create Goal',
      'btnSaveChanges': 'Save Changes',
      'titleHealthInsights': 'Health Insights',
      'tabActivity': 'Activity',
      'tabTrends': 'Trends',
      'tabInsights': 'Insights',
      'emptyGoalInsights': 'No goals set yet.\nAdd goals to see your predictive insights!',
      'titleGoalPerformance': 'Goal Performance',
      'descGoalPerformance': 'Visual breakdown of your active health targets',
      'titleCumulativeProgress': 'Cumulative Progress',
      'titleDailyGoals': 'Daily Goals (Weekly Trend)',
      'titlePredictiveInsights': 'Predictive Insights',
      'emptyActivityChart': 'No activity data for charts',
      'descEmptyActivity': 'Log some activities to see trends',
      'titleActivityTimeline': 'Activity Timeline',
      'descActivityTimeline': 'Your performance over the last 30 days',
      'titleNewReminder': 'New Reminder',
      'titleEditReminder': 'Edit Reminder',
      'lblSchedule': 'Schedule',
      'btnAddTime': 'Add Time',
      'lblDetails': 'Details',
      'hintReminderTitle': 'e.g. Take Vitamins',
      'lblMessage': 'Message (optional)',
      'hintReminderMessage': 'e.g. Don\'t skip your daily vitamins!',
      'lblAlertStyle': 'Alert Style',
      'alertBanner': 'Banner',
      'alertAlarm': 'Alarm',
      'lblRepeat': 'Repeat',
      'repeatEveryDay': 'Every day',
      'repeatNever': 'Never',
      'repeatWeekdays': 'Weekdays',
      'repeatWeekends': 'Weekends',
      'lblSound': 'Sound',
      'soundDefault': 'Default',
      'soundGentle': 'Gentle',
      'soundUrgent': 'Urgent',
      'soundSilent': 'Silent',
      'lblVibration': 'Vibration',
      'txtVibrateOn': 'Device will vibrate',
      'txtVibrateOff': 'No vibration',
      'btnDeleteReminder': 'Delete Reminder',
      'msgScheduled': 'scheduled',
      'msgUpdated': 'updated',
      'msgDeleted': 'deleted',
      'titleLogActivity': 'Log Activity',
      'lblActivityType': 'Activity Type',
      'lblCustomActivityName': 'Custom Activity Name',
      'reqField': 'Required',
      'lblNumSteps': 'Number of Steps',
      'lblDistanceAmount': 'Distance (km) / Amount',
      'errValidNumber': 'Enter a valid number',
      'errPositive': 'Must be positive',
      'lblDurationMin': 'Duration (minutes)',
      'errValidInt': 'Enter a valid integer',
      'btnSaveActivity': 'Save Activity',
      'msgActivitySaved': 'Activity saved successfully!',
      'titleWelcomeBack': 'Welcome Back',
      'descLogin': 'Login to track your health',
      'lblEmailAddress': 'Email Address',
      'errInvalidEmail': 'Invalid email',
      'lblPassword': 'Password',
      'errPasswordShort': 'Password too short',
      'btnLogin': 'Login',
      'btnNewAccount': 'New here? Create Account',
      'txtOr': 'OR',
      'btnGoogleSignIn': 'Sign in with Google',
      'errGoogleSignInFailed': 'Google Sign-In failed',
      'titleCreateAccount': 'Create Account',
      'lblFullName': 'Full Name',
      'lblConfirmPassword': 'Confirm Password',
      'btnContinue': 'Continue',
      'btnAlreadyAccount': 'Already have an account? Login',
      'titleYourInterests': 'Your Interests',
      'descYourInterests': 'Select what matters to you',
      'errSelectTopic': 'Select at least one topic!',
      'btnBack': 'Back',
      'btnGetStarted': 'Get Started',
      'user': 'User',
    },
    'si': {
      'profileUpdated': 'පැතිකඩ සාර්ථකව යාවත්කාලීන කරන ලදී!',
      'manageInterests': 'අභිමතයන් කළමනාකරණය',
      'tailorExperience': 'ඔබේ සෞඛ්‍ය අත්දැකීම සකසා ගන්න',
      'saveAndDone': 'සුරකින්න',
      'profile': 'ස්මාර්ට් පැතිකඩ',
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
      'fitness': 'යෝග්‍යතාවය',
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
      'mentalHealth': 'මානසික සෞඛ්‍යය',
      'sleepTracking': 'නින්ද නිරීක්ෂණය',
      'cardio': 'හෘද ව්‍යායාම',
      'strengthTraining': 'ශක්තිමත් කිරීමේ ව්‍යායාම',
      'flexibility': 'යෝගා සහ නම්‍යශීලිත්වය',
      'male': 'පුරුෂ',
      'female': 'ස්ත්‍රී',
      'other': 'වෙනත්',
      'notSpecified': 'සඳහන් කර නැත',
      'favorites': 'ප්‍රියතමයන්',
      'recent': 'මෑත',
      'trending': 'ප්‍රවණතා',
      'nutrition': 'පෝෂණය',
      // Dashboard Strings
      'dailyProgress': 'දෛනික ප්‍රගතිය',
      'healthAtGlance': 'ඔබේ සෞඛ්‍යය බැලූ බැල්මට',
      'activeGoals': 'සක්‍රිය ඉලක්ක',
      'healthState': 'සෞඛ්‍ය තත්වය',
      'stepsToday': 'අද පියවර',
      'optimal': 'ප්‍රශස්ත',
      'activity': 'ක්‍රියාකාරකම්',
      'goals': 'ඉලක්ක',
      'health': 'සෞඛ්‍ය',
      'currentBmi': 'වත්මන් BMI',
      'healthTips': 'සෞඛ්‍ය උපදෙස්',
      'explore': 'ගවේෂණය කරන්න',
      'quickActions': 'ඉක්මන් ක්‍රියාමාර්ග',
      'healthLogs': 'සෞඛ්‍ය වාර්තා',
      'reminders': 'සිහිකැඳවීම්',
      'keepPushing': 'දිගටම කරගෙන යන්න, ',
      'healthJourneyGreat': 'ඔබේ සෞඛ්‍ය ගමන විශිෂ්ටයි.',
      'home': 'මුල් පිටුව',
      'progress': 'ප්‍රගතිය',
      'activeGoalsUpper': 'සක්‍රිය ඉලක්ක',
      'healthStateUpper': 'සෞඛ්‍ය තත්වය',
      'stepsTodayUpper': 'අද පියවර',
      // Health Tips Strings
      'loadOfflineTips': 'නොබැඳි උපදෙස් පූරණය කරන්න',
      'noTipsFound': 'එම මූලික පදය සඳහා සෞඛ්‍ය උපදෙස් කිසිවක් හමු නොවීය.',
      'readAndSave': 'කියවා සුරකින්න',
      'readAndSaveDesc': 'සම්පූර්ණ ලිපිය කියවීමට කාඩ්පතක් තට්ටු කරන්න, නැතහොත් එය නොබැඳිව සුරැකීමට හදවත තට්ටු කරන්න.',
      'sourceHealthGov': 'මූලාශ්‍රය: MyHealthfinder (health.gov)',
      'searchTips': 'උපදෙස් සොයන්න',
      'searchTipsDesc': 'නිශ්චිත සෞඛ්‍ය උපදෙස් හෝ මූලික පද සොයා ගැනීමට මෙහි ටයිප් කරන්න.',
      'searchHint': 'සෞඛ්‍ය උපදෙස් සොයන්න...',
      'dataSource': 'දත්ත මූලාශ්‍රය:',
      'healthfinderApi': 'MyHealthfinder API (health.gov)',
      'healthGovInfo': 'එක්සත් ජනපද සෞඛ්‍ය සහ මානව සේවා දෙපාර්තමේන්තුවේ රෝග නිවාරණ සහ සෞඛ්‍ය ප්‍රවර්ධන කාර්යාලය මගින් සපයන ලදී.',
      'saveOffline': 'නොබැඳිව සුරකින්න',
      'saveOfflineDesc': 'මෙම ලිපිය නොබැඳි කියවීම සඳහා ඔබේ ප්‍රියතමයන් වෙත සුරැකීමට හදවත තට්ටු කරන්න.',
      'removedFav': 'ප්‍රියතමයන්ගෙන් ඉවත් කරන ලදී',
      'savedFav': 'ප්‍රියතමයන්ට සුරකින ලදී!',
      'spreadWord': 'අන් අය සමඟ බෙදාගන්න',
      'spreadWordDesc': 'මෙම ප්‍රයෝජනවත් සෞඛ්‍ය උපදෙස ඔබේ මිතුරන් හා පවුලේ අය සමඟ බෙදාගන්න.',
      // Reminders Strings
      'healthReminders': 'සෞඛ්‍ය සිහිකැඳවීම්',
      'selected': 'තෝරාගෙන ඇත',
      'newReminder': 'නව සිහිකැඳවීමක්',
      'delete': 'මකාදමන්න',
      'deleteReminder': 'සිහිකැඳවීම මකාදමන්න',
      'confirmDeleteMsg': 'ඔබට මෙය මකාදැමීමට විශ්වාසද',
      'cancel': 'අවලංගු කරන්න',
      'stayOnTrack': 'ඔබේ ඉලක්කයේ රැඳී සිටින්න',
      'enableRemindersDesc': 'සෞඛ්‍ය සම්පන්න පුරුදු පවත්වා ගැනීමට සිහිකැඳවීම් සක්‍රීය කරන්න',
      'noTime': 'වේලාවක් නැත',
      'more': 'තවත්',
      'custom': 'අභිරුචි',

      // Phase 2 Strings
      'activityTypeWalking': 'ඇවිදීම',
      'activityTypeRunning': 'දිවීම',
      'activityTypeCycling': 'පාපැදි පැදීම',
      'activityTypeGym': 'ව්‍යායාම ශාලාව',
      'activityTypeYoga': 'යෝගා',
      'activityTypeSwimming': 'පිහිනීම',
      'activityTypeOther': 'වෙනත්',
      'activityTypeCustom': 'අභිරුචි',
      'greetingMorning': 'සුභ උදෑසනක්',
      'greetingAfternoon': 'සුභ මධ්‍යහ්නයක්',
      'greetingEvening': 'සුභ සන්ධ්‍යාවක්',
      'greetingHello': 'ආයුබෝවන්, ',
      'syncedAt': 'සමමුහුර්ත විය',
      'syncing': 'සමමුහුර්ත වෙමින්...',
      'statDistance': 'දුර',
      'statCalories': 'කැලරි',
      'statActive': 'ක්‍රියාකාරී',
      'unitKm': 'කි.මී.',
      'unitKcal': 'කි.කැලරි',
      'unitMin': 'මිනි.',
      'btnStartWorkout': 'ව්‍යායාම\nඅරඹන්න',
      'btnLogActivity': 'ක්‍රියාකාරකම්\nසටහන් කරන්න',
      'btnHistory': 'ඉතිහාසය',
      'sectionWeeklyActivity': 'සතිපතා ක්‍රියාකාරකම්',
      'btnDetails': 'විස්තර',
      'sectionGoalProgress': 'ඉලක්ක ප්‍රගතිය',
      'titleStepGoal': 'පියවර ඉලක්කය',
      'titleWorkoutGoal': 'ව්‍යායාම ඉලක්කය',
      'stepsRemaining': 'පියවර ඉතිරියි',
      'goalReached': 'දෛනික ඉලක්කය සපුරා ඇත! 🎉',
      'workoutsLeft': 'ව්‍යායාම ඉතිරියි',
      'workoutGoalComplete': 'ව්‍යායාම ඉලක්කය සපුරා ඇත! 💪',
      'sectionRecentActivity': 'මෑත ක්‍රියාකාරකම්',
      'btnSeeAll': 'සියල්ල බලන්න',
      'emptyRecentActivity': 'තවමත් මෑත ක්‍රියාකාරකම් සටහන් කර නොමැත.\nඔබේ ඉතිහාසය බැලීමට ක්‍රියාශීලී වන්න!',
      'chooseWorkoutType': 'ව්‍යායාම වර්ගය තෝරන්න',
      'btnCancel': 'අවලංගු කරන්න',
      'errLoadHealthLogs': 'සෞඛ්‍ය වාර්තා පූරණය කිරීමට නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.',
      'editData': 'දත්ත සංස්කරණය',
      'logHealthData': 'සෞඛ්‍ය දත්ත සටහන් කරන්න',
      'lblWaist': 'ඉණ',
      'lblHip': 'උකුළ',
      'lblChest': 'පපුව',
      'lblBodyFat': 'ශරීර මේදය',
      'estimatedBmi': 'ඇස්තමේන්තුගත BMI',
      'lblDate': 'දිනය',
      'lblAdvancedMetrics': 'උසස් ශරීර මිමි',
      'txtAdvancedMetrics': 'වැඩිදුර ශරීර සංයුතිය අවබෝධ කර ගැනීමට මේවා ලුහුබැඳ යන්න',
      'lblContextLifestyle': 'සන්දර්භය සහ ජීවන රටාව',
      'btnAddCustomTag': 'අභිරුචි ටැගයක් එක් කරන්න',
      'btnEditTag': 'ටැගය සංස්කරණය කරන්න',
      'btnDelete': 'මකාදමන්න',
      'btnAdd': 'එක් කරන්න',
      'btnSave': 'සුරකින්න',
      'hintCustomTag': 'උදා: 🍷 මත්පැන් පානය කළා',
      'titleHealthGoals': 'සෞඛ්‍ය ඉලක්ක',
      'noGoalsSet': 'තවමත් ඉලක්ක පිහිටුවා නැත',
      'tapToAddGoal': 'ඔබේ පළමු ඉලක්කය සැකසීමට + බොත්තම තට්ටු කරන්න',
      'btnLogProgress': 'ප්‍රගතිය සටහන් කරන්න',
      'titleUpdateGoal': 'ඉලක්කය යාවත්කාලීන කරන්න',
      'lblCurrentValue': 'වත්මන් අගය',
      'lblNewCurrentValue': 'නව වත්මන් අගය',
      'titleCreateNewGoal': 'නව ඉලක්කයක් සාදන්න',
      'titleEditGoal': 'ඉලක්කය සංස්කරණය කරන්න',
      'lblGoalTitle': 'ඉලක්කයේ නම',
      'hintGoalTitle': 'උදා: විටමින් ලබා ගැනීම',
      'lblSelectCategory': 'ඉලක්ක කාණ්ඩය තෝරන්න',
      'lblCategoryType': 'කාණ්ඩය / ලුහුබැඳීමේ වර්ගය',
      'lblTargetValue': 'ඉලක්ක අගය',
      'lblUnit': 'ඒකකය',
      'btnSetReminder': 'සිහිකැඳවීමක් සකසන්න',
      'btnCreateGoal': 'ඉලක්කය සාදන්න',
      'btnSaveChanges': 'වෙනස්කම් සුරකින්න',
      'titleHealthInsights': 'සෞඛ්‍ය අවබෝධය',
      'tabActivity': 'ක්‍රියාකාරකම්',
      'tabTrends': 'ප්‍රවණතා',
      'tabInsights': 'අවබෝධය',
      'emptyGoalInsights': 'තවමත් ඉලක්ක පිහිටුවා නැත.\nඔබේ පෙරනිමිති අවබෝධය දැකීමට ඉලක්ක එකතු කරන්න!',
      'titleGoalPerformance': 'ඉලක්ක ක්‍රියාකාරීත්වය',
      'descGoalPerformance': 'ඔබේ සක්‍රීය සෞඛ්‍ය ඉලක්කවල දෘශ්‍ය බිඳවැටීම',
      'titleCumulativeProgress': 'සමුච්චිත ප්‍රගතිය',
      'titleDailyGoals': 'දෛනික ඉලක්ක (සතිපතා ප්‍රවණතාව)',
      'titlePredictiveInsights': 'පෙරනිමිති අවබෝධය',
      'emptyActivityChart': 'ප්‍රස්තාර සඳහා ක්‍රියාකාරකම් දත්ත නොමැත',
      'descEmptyActivity': 'ප්‍රවණතා දැකීමට ක්‍රියාකාරකම් සටහන් කරන්න',
      'titleActivityTimeline': 'ක්‍රියාකාරකම් කාලරේඛාව',
      'descActivityTimeline': 'පසුගිය දින 30 තුළ ඔබේ ක්‍රියාකාරීත්වය',
      'titleNewReminder': 'නව සිහිකැඳවීමක්',
      'titleEditReminder': 'සිහිකැඳවීම සංස්කරණය කරන්න',
      'lblSchedule': 'කාලසටහන',
      'btnAddTime': 'වේලාවක් එක් කරන්න',
      'lblDetails': 'විස්තර',
      'hintReminderTitle': 'උදා: විටමින් ලබා ගැනීම',
      'lblMessage': 'පණිවිඩය (විකල්ප)',
      'hintReminderMessage': 'උදා: ඔබේ දෛනික විටමින් මඟ හරින්න එපා!',
      'lblAlertStyle': 'දැනුම්දීමේ විලාසය',
      'alertBanner': 'බැනරය',
      'alertAlarm': 'අනතුරු ඇඟවීම',
      'lblRepeat': 'පුනරාවර්තනය',
      'repeatEveryDay': 'සෑම දිනකම',
      'repeatNever': 'කිසිදාක නැත',
      'repeatWeekdays': 'සතියේ දිනවල',
      'repeatWeekends': 'සති අන්තයේ',
      'lblSound': 'ශබ්දය',
      'soundDefault': 'පෙරනිමි',
      'soundGentle': 'මෘදු',
      'soundUrgent': 'හදිසි',
      'soundSilent': 'නිහඬ',
      'lblVibration': 'කම්පනය',
      'txtVibrateOn': 'උපාංගය කම්පනය වේ',
      'txtVibrateOff': 'කම්පනයක් නැත',
      'btnDeleteReminder': 'සිහිකැඳවීම මකාදමන්න',
      'msgScheduled': 'උපලේඛනගත කර ඇත',
      'msgUpdated': 'යාවත්කාලීන කරන ලදී',
      'msgDeleted': 'මකාදමන ලදී',
      'titleLogActivity': 'ක්‍රියාකාරකම් සටහන් කරන්න',
      'lblActivityType': 'ක්‍රියාකාරකම් වර්ගය',
      'lblCustomActivityName': 'අභිරුචි ක්‍රියාකාරකම් නම',
      'reqField': 'අවශ්‍යයි',
      'lblNumSteps': 'පියවර ගණන',
      'lblDistanceAmount': 'දුර (කි.මී.) / ප්‍රමාණය',
      'errValidNumber': 'වලංගු අංකයක් ඇතුලත් කරන්න',
      'errPositive': 'ධන අගයක් විය යුතුය',
      'lblDurationMin': 'කාලය (මිනිත්තු)',
      'errValidInt': 'වලංගු පූර්ණ සංඛ්‍යාවක් ඇතුලත් කරන්න',
      'btnSaveActivity': 'ක්‍රියාකාරකම් සුරකින්න',
      'msgActivitySaved': 'ක්‍රියාකාරකම් සාර්ථකව සුරකින ලදී!',
      'titleWelcomeBack': 'නැවත සාදරයෙන් පිළිගනිමු',
      'descLogin': 'ඔබේ සෞඛ්‍යය නිරීක්ෂණය කිරීමට ලොග් වන්න',
      'lblEmailAddress': 'විද්‍යුත් තැපැල් ලිපිනය',
      'errInvalidEmail': 'අවලංගු විද්‍යුත් තැපෑලකි',
      'lblPassword': 'මුරපදය',
      'errPasswordShort': 'මුරපදය කෙටි වැඩියි',
      'btnLogin': 'ලොග් වන්න',
      'btnNewAccount': 'නව පරිශීලකයෙක්ද? ගිණුමක් සාදන්න',
      'txtOr': 'නැතහොත්',
      'btnGoogleSignIn': 'Google හරහා ලොග් වන්න',
      'errGoogleSignInFailed': 'Google ලොගින් වීම අසාර්ථක විය',
      'titleCreateAccount': 'ගිණුමක් සාදන්න',
      'lblFullName': 'සම්පූර්ණ නම',
      'lblConfirmPassword': 'මුරපදය තහවුරු කරන්න',
      'btnContinue': 'ඉදිරියට යන්න',
      'btnAlreadyAccount': 'දැනටමත් ගිණුමක් තිබේද? ලොග් වන්න',
      'titleYourInterests': 'ඔබේ රුචිකත්වයන්',
      'descYourInterests': 'ඔබට වැදගත් දේ තෝරන්න',
      'errSelectTopic': 'අවම වශයෙන් එක් මාතෘකාවක් හෝ තෝරන්න!',
      'btnBack': 'පසුපසට',
      'btnGetStarted': 'ආරම්භ කරන්න',
      'user': 'පරිශීලක',
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
  String get favorites => _localizedValues[locale.languageCode]!['favorites']!;
  String get recent => _localizedValues[locale.languageCode]!['recent']!;
  String get trending => _localizedValues[locale.languageCode]!['trending']!;
  String get nutrition => _localizedValues[locale.languageCode]!['nutrition']!;

  // Dashboard Getters
  String get dailyProgress => _localizedValues[locale.languageCode]!['dailyProgress']!;
  String get healthAtGlance => _localizedValues[locale.languageCode]!['healthAtGlance']!;
  String get activeGoals => _localizedValues[locale.languageCode]!['activeGoals']!;
  String get healthState => _localizedValues[locale.languageCode]!['healthState']!;
  String get stepsToday => _localizedValues[locale.languageCode]!['stepsToday']!;
  String get optimal => _localizedValues[locale.languageCode]!['optimal']!;
  String get activity => _localizedValues[locale.languageCode]!['activity']!;
  String get goals => _localizedValues[locale.languageCode]!['goals']!;
  String get health => _localizedValues[locale.languageCode]!['health']!;
  String get currentBmi => _localizedValues[locale.languageCode]!['currentBmi']!;
  String get healthTips => _localizedValues[locale.languageCode]!['healthTips']!;
  String get explore => _localizedValues[locale.languageCode]!['explore']!;
  String get quickActions => _localizedValues[locale.languageCode]!['quickActions']!;
  String get healthLogs => _localizedValues[locale.languageCode]!['healthLogs']!;
  String get reminders => _localizedValues[locale.languageCode]!['reminders']!;
  String get keepPushing => _localizedValues[locale.languageCode]!['keepPushing']!;
  String get healthJourneyGreat => _localizedValues[locale.languageCode]!['healthJourneyGreat']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get progress => _localizedValues[locale.languageCode]!['progress']!;
  String get activeGoalsUpper => _localizedValues[locale.languageCode]!['activeGoalsUpper']!;
  String get healthStateUpper => _localizedValues[locale.languageCode]!['healthStateUpper']!;
  String get stepsTodayUpper => _localizedValues[locale.languageCode]!['stepsTodayUpper']!;

  // Health Tips Getters
  String get loadOfflineTips => _localizedValues[locale.languageCode]!['loadOfflineTips']!;
  String get noTipsFound => _localizedValues[locale.languageCode]!['noTipsFound']!;
  String get readAndSave => _localizedValues[locale.languageCode]!['readAndSave']!;
  String get readAndSaveDesc => _localizedValues[locale.languageCode]!['readAndSaveDesc']!;
  String get sourceHealthGov => _localizedValues[locale.languageCode]!['sourceHealthGov']!;
  String get searchTips => _localizedValues[locale.languageCode]!['searchTips']!;
  String get searchTipsDesc => _localizedValues[locale.languageCode]!['searchTipsDesc']!;
  String get searchHint => _localizedValues[locale.languageCode]!['searchHint']!;
  String get dataSource => _localizedValues[locale.languageCode]!['dataSource']!;
  String get healthfinderApi => _localizedValues[locale.languageCode]!['healthfinderApi']!;
  String get healthGovInfo => _localizedValues[locale.languageCode]!['healthGovInfo']!;
  String get saveOffline => _localizedValues[locale.languageCode]!['saveOffline']!;
  String get saveOfflineDesc => _localizedValues[locale.languageCode]!['saveOfflineDesc']!;
  String get removedFav => _localizedValues[locale.languageCode]!['removedFav']!;
  String get savedFav => _localizedValues[locale.languageCode]!['savedFav']!;
  String get spreadWord => _localizedValues[locale.languageCode]!['spreadWord']!;
  String get spreadWordDesc => _localizedValues[locale.languageCode]!['spreadWordDesc']!;

  // Reminders Getters
  String get healthReminders => _localizedValues[locale.languageCode]!['healthReminders']!;
  String get selected => _localizedValues[locale.languageCode]!['selected']!;
  String get newReminder => _localizedValues[locale.languageCode]!['newReminder']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get deleteReminder => _localizedValues[locale.languageCode]!['deleteReminder']!;
  String get confirmDeleteMsg => _localizedValues[locale.languageCode]!['confirmDeleteMsg']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get stayOnTrack => _localizedValues[locale.languageCode]!['stayOnTrack']!;
  String get enableRemindersDesc => _localizedValues[locale.languageCode]!['enableRemindersDesc']!;
  String get noTime => _localizedValues[locale.languageCode]!['noTime']!;
  String get more => _localizedValues[locale.languageCode]!['more']!;
  String get custom => _localizedValues[locale.languageCode]!['custom']!;
  // Phase 2 Getters
  String get activityTypeWalking => _localizedValues[locale.languageCode]!['activityTypeWalking']!;
  String get activityTypeRunning => _localizedValues[locale.languageCode]!['activityTypeRunning']!;
  String get activityTypeCycling => _localizedValues[locale.languageCode]!['activityTypeCycling']!;
  String get activityTypeGym => _localizedValues[locale.languageCode]!['activityTypeGym']!;
  String get activityTypeYoga => _localizedValues[locale.languageCode]!['activityTypeYoga']!;
  String get activityTypeSwimming => _localizedValues[locale.languageCode]!['activityTypeSwimming']!;
  String get activityTypeOther => _localizedValues[locale.languageCode]!['activityTypeOther']!;
  String get activityTypeCustom => _localizedValues[locale.languageCode]!['activityTypeCustom']!;
  String get greetingMorning => _localizedValues[locale.languageCode]!['greetingMorning']!;
  String get greetingAfternoon => _localizedValues[locale.languageCode]!['greetingAfternoon']!;
  String get greetingEvening => _localizedValues[locale.languageCode]!['greetingEvening']!;
  String get greetingHello => _localizedValues[locale.languageCode]!['greetingHello']!;
  String get syncedAt => _localizedValues[locale.languageCode]!['syncedAt']!;
  String get syncing => _localizedValues[locale.languageCode]!['syncing']!;
  String get statDistance => _localizedValues[locale.languageCode]!['statDistance']!;
  String get statCalories => _localizedValues[locale.languageCode]!['statCalories']!;
  String get statActive => _localizedValues[locale.languageCode]!['statActive']!;
  String get unitKm => _localizedValues[locale.languageCode]!['unitKm']!;
  String get unitKcal => _localizedValues[locale.languageCode]!['unitKcal']!;
  String get unitMin => _localizedValues[locale.languageCode]!['unitMin']!;
  String get btnStartWorkout => _localizedValues[locale.languageCode]!['btnStartWorkout']!;
  String get btnLogActivity => _localizedValues[locale.languageCode]!['btnLogActivity']!;
  String get btnHistory => _localizedValues[locale.languageCode]!['btnHistory']!;
  String get sectionWeeklyActivity => _localizedValues[locale.languageCode]!['sectionWeeklyActivity']!;
  String get btnDetails => _localizedValues[locale.languageCode]!['btnDetails']!;
  String get sectionGoalProgress => _localizedValues[locale.languageCode]!['sectionGoalProgress']!;
  String get titleStepGoal => _localizedValues[locale.languageCode]!['titleStepGoal']!;
  String get titleWorkoutGoal => _localizedValues[locale.languageCode]!['titleWorkoutGoal']!;
  String get stepsRemaining => _localizedValues[locale.languageCode]!['stepsRemaining']!;
  String get goalReached => _localizedValues[locale.languageCode]!['goalReached']!;
  String get workoutsLeft => _localizedValues[locale.languageCode]!['workoutsLeft']!;
  String get workoutGoalComplete => _localizedValues[locale.languageCode]!['workoutGoalComplete']!;
  String get sectionRecentActivity => _localizedValues[locale.languageCode]!['sectionRecentActivity']!;
  String get btnSeeAll => _localizedValues[locale.languageCode]!['btnSeeAll']!;
  String get emptyRecentActivity => _localizedValues[locale.languageCode]!['emptyRecentActivity']!;
  String get chooseWorkoutType => _localizedValues[locale.languageCode]!['chooseWorkoutType']!;
  String get btnCancel => _localizedValues[locale.languageCode]!['btnCancel']!;

  String get errLoadHealthLogs => _localizedValues[locale.languageCode]!['errLoadHealthLogs']!;
  String get editData => _localizedValues[locale.languageCode]!['editData']!;
  String get logHealthData => _localizedValues[locale.languageCode]!['logHealthData']!;
  String get lblWaist => _localizedValues[locale.languageCode]!['lblWaist']!;
  String get lblHip => _localizedValues[locale.languageCode]!['lblHip']!;
  String get lblChest => _localizedValues[locale.languageCode]!['lblChest']!;
  String get lblBodyFat => _localizedValues[locale.languageCode]!['lblBodyFat']!;
  String get estimatedBmi => _localizedValues[locale.languageCode]!['estimatedBmi']!;
  String get lblDate => _localizedValues[locale.languageCode]!['lblDate']!;
  String get lblAdvancedMetrics => _localizedValues[locale.languageCode]!['lblAdvancedMetrics']!;
  String get txtAdvancedMetrics => _localizedValues[locale.languageCode]!['txtAdvancedMetrics']!;
  String get lblContextLifestyle => _localizedValues[locale.languageCode]!['lblContextLifestyle']!;
  String get btnAddCustomTag => _localizedValues[locale.languageCode]!['btnAddCustomTag']!;
  String get btnEditTag => _localizedValues[locale.languageCode]!['btnEditTag']!;
  String get btnDelete => _localizedValues[locale.languageCode]!['btnDelete']!;
  String get btnAdd => _localizedValues[locale.languageCode]!['btnAdd']!;
  String get btnSave => _localizedValues[locale.languageCode]!['btnSave']!;
  String get hintCustomTag => _localizedValues[locale.languageCode]!['hintCustomTag']!;

  String get titleHealthGoals => _localizedValues[locale.languageCode]!['titleHealthGoals']!;
  String get noGoalsSet => _localizedValues[locale.languageCode]!['noGoalsSet']!;
  String get tapToAddGoal => _localizedValues[locale.languageCode]!['tapToAddGoal']!;
  String get btnLogProgress => _localizedValues[locale.languageCode]!['btnLogProgress']!;
  String get titleUpdateGoal => _localizedValues[locale.languageCode]!['titleUpdateGoal']!;
  String get lblCurrentValue => _localizedValues[locale.languageCode]!['lblCurrentValue']!;
  String get lblNewCurrentValue => _localizedValues[locale.languageCode]!['lblNewCurrentValue']!;
  String get titleCreateNewGoal => _localizedValues[locale.languageCode]!['titleCreateNewGoal']!;
  String get titleEditGoal => _localizedValues[locale.languageCode]!['titleEditGoal']!;
  String get lblGoalTitle => _localizedValues[locale.languageCode]!['lblGoalTitle']!;
  String get hintGoalTitle => _localizedValues[locale.languageCode]!['hintGoalTitle']!;
  String get lblSelectCategory => _localizedValues[locale.languageCode]!['lblSelectCategory']!;
  String get lblCategoryType => _localizedValues[locale.languageCode]!['lblCategoryType']!;
  String get lblTargetValue => _localizedValues[locale.languageCode]!['lblTargetValue']!;
  String get lblUnit => _localizedValues[locale.languageCode]!['lblUnit']!;
  String get btnSetReminder => _localizedValues[locale.languageCode]!['btnSetReminder']!;
  String get btnCreateGoal => _localizedValues[locale.languageCode]!['btnCreateGoal']!;
  String get btnSaveChanges => _localizedValues[locale.languageCode]!['btnSaveChanges']!;

  String get titleHealthInsights => _localizedValues[locale.languageCode]!['titleHealthInsights']!;
  String get tabActivity => _localizedValues[locale.languageCode]!['tabActivity']!;
  String get tabTrends => _localizedValues[locale.languageCode]!['tabTrends']!;
  String get tabInsights => _localizedValues[locale.languageCode]!['tabInsights']!;
  String get emptyGoalInsights => _localizedValues[locale.languageCode]!['emptyGoalInsights']!;
  String get titleGoalPerformance => _localizedValues[locale.languageCode]!['titleGoalPerformance']!;
  String get descGoalPerformance => _localizedValues[locale.languageCode]!['descGoalPerformance']!;
  String get titleCumulativeProgress => _localizedValues[locale.languageCode]!['titleCumulativeProgress']!;
  String get titleDailyGoals => _localizedValues[locale.languageCode]!['titleDailyGoals']!;
  String get titlePredictiveInsights => _localizedValues[locale.languageCode]!['titlePredictiveInsights']!;
  String get emptyActivityChart => _localizedValues[locale.languageCode]!['emptyActivityChart']!;
  String get descEmptyActivity => _localizedValues[locale.languageCode]!['descEmptyActivity']!;
  String get titleActivityTimeline => _localizedValues[locale.languageCode]!['titleActivityTimeline']!;
  String get descActivityTimeline => _localizedValues[locale.languageCode]!['descActivityTimeline']!;

  String get titleNewReminder => _localizedValues[locale.languageCode]!['titleNewReminder']!;
  String get titleEditReminder => _localizedValues[locale.languageCode]!['titleEditReminder']!;
  String get lblSchedule => _localizedValues[locale.languageCode]!['lblSchedule']!;
  String get btnAddTime => _localizedValues[locale.languageCode]!['btnAddTime']!;
  String get lblDetails => _localizedValues[locale.languageCode]!['lblDetails']!;
  String get hintReminderTitle => _localizedValues[locale.languageCode]!['hintReminderTitle']!;
  String get lblMessage => _localizedValues[locale.languageCode]!['lblMessage']!;
  String get hintReminderMessage => _localizedValues[locale.languageCode]!['hintReminderMessage']!;
  String get lblAlertStyle => _localizedValues[locale.languageCode]!['lblAlertStyle']!;
  String get alertBanner => _localizedValues[locale.languageCode]!['alertBanner']!;
  String get alertAlarm => _localizedValues[locale.languageCode]!['alertAlarm']!;
  String get lblRepeat => _localizedValues[locale.languageCode]!['lblRepeat']!;
  String get repeatEveryDay => _localizedValues[locale.languageCode]!['repeatEveryDay']!;
  String get repeatNever => _localizedValues[locale.languageCode]!['repeatNever']!;
  String get repeatWeekdays => _localizedValues[locale.languageCode]!['repeatWeekdays']!;
  String get repeatWeekends => _localizedValues[locale.languageCode]!['repeatWeekends']!;
  String get lblSound => _localizedValues[locale.languageCode]!['lblSound']!;
  String get soundDefault => _localizedValues[locale.languageCode]!['soundDefault']!;
  String get soundGentle => _localizedValues[locale.languageCode]!['soundGentle']!;
  String get soundUrgent => _localizedValues[locale.languageCode]!['soundUrgent']!;
  String get soundSilent => _localizedValues[locale.languageCode]!['soundSilent']!;
  String get lblVibration => _localizedValues[locale.languageCode]!['lblVibration']!;
  String get txtVibrateOn => _localizedValues[locale.languageCode]!['txtVibrateOn']!;
  String get txtVibrateOff => _localizedValues[locale.languageCode]!['txtVibrateOff']!;
  String get btnDeleteReminder => _localizedValues[locale.languageCode]!['btnDeleteReminder']!;
  String get msgScheduled => _localizedValues[locale.languageCode]!['msgScheduled']!;
  String get msgUpdated => _localizedValues[locale.languageCode]!['msgUpdated']!;
  String get msgDeleted => _localizedValues[locale.languageCode]!['msgDeleted']!;

  String get titleLogActivity => _localizedValues[locale.languageCode]!['titleLogActivity']!;
  String get lblActivityType => _localizedValues[locale.languageCode]!['lblActivityType']!;
  String get lblCustomActivityName => _localizedValues[locale.languageCode]!['lblCustomActivityName']!;
  String get reqField => _localizedValues[locale.languageCode]!['reqField']!;
  String get lblNumSteps => _localizedValues[locale.languageCode]!['lblNumSteps']!;
  String get lblDistanceAmount => _localizedValues[locale.languageCode]!['lblDistanceAmount']!;
  String get errValidNumber => _localizedValues[locale.languageCode]!['errValidNumber']!;
  String get errPositive => _localizedValues[locale.languageCode]!['errPositive']!;
  String get lblDurationMin => _localizedValues[locale.languageCode]!['lblDurationMin']!;
  String get errValidInt => _localizedValues[locale.languageCode]!['errValidInt']!;
  String get btnSaveActivity => _localizedValues[locale.languageCode]!['btnSaveActivity']!;
  String get msgActivitySaved => _localizedValues[locale.languageCode]!['msgActivitySaved']!;

  String get titleWelcomeBack => _localizedValues[locale.languageCode]!['titleWelcomeBack']!;
  String get descLogin => _localizedValues[locale.languageCode]!['descLogin']!;
  String get lblEmailAddress => _localizedValues[locale.languageCode]!['lblEmailAddress']!;
  String get errInvalidEmail => _localizedValues[locale.languageCode]!['errInvalidEmail']!;
  String get lblPassword => _localizedValues[locale.languageCode]!['lblPassword']!;
  String get errPasswordShort => _localizedValues[locale.languageCode]!['errPasswordShort']!;
  String get btnLogin => _localizedValues[locale.languageCode]!['btnLogin']!;
  String get btnNewAccount => _localizedValues[locale.languageCode]!['btnNewAccount']!;
  String get txtOr => _localizedValues[locale.languageCode]!['txtOr']!;
  String get btnGoogleSignIn => _localizedValues[locale.languageCode]!['btnGoogleSignIn']!;
  String get errGoogleSignInFailed => _localizedValues[locale.languageCode]!['errGoogleSignInFailed']!;
  String get titleCreateAccount => _localizedValues[locale.languageCode]!['titleCreateAccount']!;
  String get lblFullName => _localizedValues[locale.languageCode]!['lblFullName']!;
  String get lblConfirmPassword => _localizedValues[locale.languageCode]!['lblConfirmPassword']!;
  String get btnContinue => _localizedValues[locale.languageCode]!['btnContinue']!;
  String get btnAlreadyAccount => _localizedValues[locale.languageCode]!['btnAlreadyAccount']!;
  String get titleYourInterests => _localizedValues[locale.languageCode]!['titleYourInterests']!;
  String get descYourInterests => _localizedValues[locale.languageCode]!['descYourInterests']!;
  String get errSelectTopic => _localizedValues[locale.languageCode]!['errSelectTopic']!;
  String get btnBack => _localizedValues[locale.languageCode]!['btnBack']!;
  String get btnGetStarted => _localizedValues[locale.languageCode]!['btnGetStarted']!;
  String get user => _localizedValues[locale.languageCode]!['user']!;

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

