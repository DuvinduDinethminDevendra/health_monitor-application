import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Monitor'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @stepsToday.
  ///
  /// In en, this message translates to:
  /// **'STEPS TODAY'**
  String get stepsToday;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get calories;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'HEART RATE'**
  String get heartRate;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'WATER'**
  String get water;

  /// No description provided for @addActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get addActivity;

  /// No description provided for @activeGoals.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE GOALS'**
  String get activeGoals;

  /// No description provided for @healthState.
  ///
  /// In en, this message translates to:
  /// **'HEALTH STATE'**
  String get healthState;

  /// No description provided for @addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoal;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Appearance'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;

  /// No description provided for @manageInterests.
  ///
  /// In en, this message translates to:
  /// **'Manage Interests'**
  String get manageInterests;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @healthLog.
  ///
  /// In en, this message translates to:
  /// **'Health Log'**
  String get healthLog;

  /// No description provided for @dailyTips.
  ///
  /// In en, this message translates to:
  /// **'Daily Health Tips'**
  String get dailyTips;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No health logs yet'**
  String get noLogs;

  /// No description provided for @noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get noGoals;

  /// No description provided for @noActivities.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivities;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToTrack.
  ///
  /// In en, this message translates to:
  /// **'Login to track your health'**
  String get loginToTrack;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here? Create Account'**
  String get newHere;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @selectInterests.
  ///
  /// In en, this message translates to:
  /// **'Select what matters to you'**
  String get selectInterests;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyAccount;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @diet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get diet;

  /// No description provided for @meditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get meditation;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get weightLoss;

  /// No description provided for @muscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get muscleGain;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @yoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get yoga;

  /// No description provided for @healthyHabits.
  ///
  /// In en, this message translates to:
  /// **'Healthy Habits'**
  String get healthyHabits;

  /// No description provided for @saveAndDone.
  ///
  /// In en, this message translates to:
  /// **'Save & Done'**
  String get saveAndDone;

  /// No description provided for @logActivity.
  ///
  /// In en, this message translates to:
  /// **'Log Activity'**
  String get logActivity;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get selectType;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @cycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get cycling;

  /// No description provided for @swimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get swimming;

  /// No description provided for @underweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get underweight;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @overweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get overweight;

  /// No description provided for @obese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get obese;

  /// No description provided for @tapToAddLog.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to log your vitals'**
  String get tapToAddLog;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get durationMin;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Title'**
  String get goalTitle;

  /// No description provided for @targetValue.
  ///
  /// In en, this message translates to:
  /// **'Target Value'**
  String get targetValue;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get notSpecified;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @logProgress.
  ///
  /// In en, this message translates to:
  /// **'Log Progress'**
  String get logProgress;

  /// No description provided for @updateGoal.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateGoal;

  /// No description provided for @currentValue.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentValue;

  /// No description provided for @newCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'New Current Value'**
  String get newCurrentValue;

  /// No description provided for @createGoal.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get createGoal;

  /// No description provided for @editGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoal;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Goal Category'**
  String get selectCategory;

  /// No description provided for @trackingType.
  ///
  /// In en, this message translates to:
  /// **'Category / Tracking Type'**
  String get trackingType;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated Successfully!'**
  String get profileUpdated;

  /// No description provided for @tailorExperience.
  ///
  /// In en, this message translates to:
  /// **'Tailor your health experience'**
  String get tailorExperience;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameEmpty;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @solidMatteSapphire.
  ///
  /// In en, this message translates to:
  /// **'Solid Matte Sapphire'**
  String get solidMatteSapphire;

  /// No description provided for @solidMatteAlabaster.
  ///
  /// In en, this message translates to:
  /// **'Solid Matte Alabaster'**
  String get solidMatteAlabaster;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @healthAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your health at a glance'**
  String get healthAtAGlance;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @keepPushing.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing'**
  String get keepPushing;

  /// No description provided for @healthJourneyGreat.
  ///
  /// In en, this message translates to:
  /// **'Your health journey is looking great.'**
  String get healthJourneyGreat;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @goalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Goal Performance'**
  String get goalPerformance;

  /// No description provided for @visualBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Visual breakdown of your active health targets'**
  String get visualBreakdown;

  /// No description provided for @cumulativeProgress.
  ///
  /// In en, this message translates to:
  /// **'Cumulative Progress'**
  String get cumulativeProgress;

  /// No description provided for @dailyGoalsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals (Weekly Trend)'**
  String get dailyGoalsWeekly;

  /// No description provided for @predictiveInsights.
  ///
  /// In en, this message translates to:
  /// **'Predictive Insights'**
  String get predictiveInsights;

  /// No description provided for @activityTimeline.
  ///
  /// In en, this message translates to:
  /// **'Activity Timeline'**
  String get activityTimeline;

  /// No description provided for @performance30Days.
  ///
  /// In en, this message translates to:
  /// **'Your performance over the last 30 days'**
  String get performance30Days;

  /// No description provided for @noActivityData.
  ///
  /// In en, this message translates to:
  /// **'No activity data for charts'**
  String get noActivityData;

  /// No description provided for @logActivitiesToSeeTrends.
  ///
  /// In en, this message translates to:
  /// **'Log some activities to see trends'**
  String get logActivitiesToSeeTrends;

  /// No description provided for @noGoalsSet.
  ///
  /// In en, this message translates to:
  /// **'No goals set yet.\nAdd goals to see your predictive insights!'**
  String get noGoalsSet;

  /// No description provided for @smartReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get smartReminders;

  /// No description provided for @habitTracking.
  ///
  /// In en, this message translates to:
  /// **'Habit Tracking'**
  String get habitTracking;

  /// No description provided for @setDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Set daily reminders to maintain your healthy lifestyle'**
  String get setDailyReminders;

  /// No description provided for @dailySchedules.
  ///
  /// In en, this message translates to:
  /// **'Daily Schedules'**
  String get dailySchedules;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'reminder enabled'**
  String get reminderEnabled;

  /// No description provided for @morningWorkout.
  ///
  /// In en, this message translates to:
  /// **'Morning Workout'**
  String get morningWorkout;

  /// No description provided for @morningWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your daily exercise routine!'**
  String get morningWorkoutBody;

  /// No description provided for @drinkWater.
  ///
  /// In en, this message translates to:
  /// **'Drink Water'**
  String get drinkWater;

  /// No description provided for @drinkWaterBody.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated! Take a glass of water now.'**
  String get drinkWaterBody;

  /// No description provided for @logMeals.
  ///
  /// In en, this message translates to:
  /// **'Log Your Meals'**
  String get logMeals;

  /// No description provided for @logMealsBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to log what you ate today.'**
  String get logMealsBody;

  /// No description provided for @takeAWalk.
  ///
  /// In en, this message translates to:
  /// **'Take a Walk'**
  String get takeAWalk;

  /// No description provided for @takeAWalkBody.
  ///
  /// In en, this message translates to:
  /// **'Get some fresh air! A 15-minute walk is great for your health.'**
  String get takeAWalkBody;

  /// No description provided for @logWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Your Weight'**
  String get logWeight;

  /// No description provided for @logWeightBody.
  ///
  /// In en, this message translates to:
  /// **'Time to track your weight and BMI progress.'**
  String get logWeightBody;

  /// No description provided for @bedtimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Bedtime Reminder'**
  String get bedtimeReminder;

  /// No description provided for @bedtimeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time to wind down. A good night\'s sleep is essential!'**
  String get bedtimeReminderBody;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @healthTips.
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get healthTips;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @cumulative.
  ///
  /// In en, this message translates to:
  /// **'Cumulative'**
  String get cumulative;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @dietNutrition.
  ///
  /// In en, this message translates to:
  /// **'Diet & Nutrition'**
  String get dietNutrition;

  /// No description provided for @mentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get mentalHealth;

  /// No description provided for @sleepTracking.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracking'**
  String get sleepTracking;

  /// No description provided for @cardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardio;

  /// No description provided for @strengthTraining.
  ///
  /// In en, this message translates to:
  /// **'Strength Training'**
  String get strengthTraining;

  /// No description provided for @flexibility.
  ///
  /// In en, this message translates to:
  /// **'Yoga & Flexibility'**
  String get flexibility;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;
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
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
