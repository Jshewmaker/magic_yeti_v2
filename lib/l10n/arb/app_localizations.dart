import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Text shown in the AppBar of the Counter Page
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counterAppBarTitle;

  /// Message shown when there is an error at login
  ///
  /// In en, this message translates to:
  /// **'Authentication failure'**
  String get authenticationFailure;

  /// Button text for create account button
  ///
  /// In en, this message translates to:
  /// **'CREATE AN ACCOUNT'**
  String get createAccountButtonText;

  /// Forgot password button title shown on Login page
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordText;

  /// Email error text on sign up form when email is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmailInputErrorText;

  /// Password error text on login form when password is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPasswordInputErrorText;

  /// Game ID
  ///
  /// In en, this message translates to:
  /// **'Game ID'**
  String get gameId;

  /// Login Button Text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonText;

  /// Logout Button Text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logOutButtonText;

  /// Greeting shown on the login page.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Magic Yeti!'**
  String get loginWelcomeText;

  /// Email label on sign up form
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailInputLabelText;

  /// Password label on login form
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordInputLabelText;

  /// Message shown when a valid email is submitted for a password reset
  ///
  /// In en, this message translates to:
  /// **'If an account is registered with the provided email, we will send a link to reset your password'**
  String get resetPasswordSubmitText;

  /// Reset Password page title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Sign in with Apple Button Text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithAppleButtonText;

  /// Sign up with Apple Button Text
  ///
  /// In en, this message translates to:
  /// **'Sign up with Apple'**
  String get signUpWithAppleButtonText;

  /// Sign in with Google Button Text
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogleButtonText;

  /// Sign up with Google Button Text
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogleButtonText;

  /// App bar title shown on Sign Up page
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpAppBarTitle;

  /// Sign Up button title shown on Sign Up page
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButtonText;

  /// Message shown when there is an error creating an account
  ///
  /// In en, this message translates to:
  /// **'Unable to create an account'**
  String get signUpFailure;

  /// Submit button title shown on Reset Password page
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitButtonText;

  /// Search button label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButtonText;

  /// Tab tile for timeline view
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTabResults;

  /// Tab tile for timeline view
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get resultsTabAnalysis;

  /// Tab tile for timeline view
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get resultsTabTimeline;

  /// Text shown in the navigation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to go to the home page? The current game progress will be lost.'**
  String get navigationDialogText;

  /// Text shown in the navigation dialog
  ///
  /// In en, this message translates to:
  /// **'Exit Game?'**
  String get exitGameDialogText;

  /// Confirmation button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTextButton;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTextButton;

  /// Text shown in the navigation dialog
  ///
  /// In en, this message translates to:
  /// **'Reset Game?'**
  String get resetGameDialogText;

  /// No description provided for @numberOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'{numberOfPlayers} Player'**
  String numberOfPlayers(int numberOfPlayers);

  /// Hint text shown in commander search input field
  ///
  /// In en, this message translates to:
  /// **'Search for your commander'**
  String get searchCommanderHintText;

  /// Text shown on save buttons throughout the app
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButtonText;

  /// Text shown in the account ownership widget prompting user to link their account
  ///
  /// In en, this message translates to:
  /// **'Link this player to your account so we know which commander you are!'**
  String get accountOwnershipLinkText;

  /// Title shown in the account ownership widget
  ///
  /// In en, this message translates to:
  /// **'This is my commander'**
  String get accountOwnershipTitle;

  /// Title for the match history section
  ///
  /// In en, this message translates to:
  /// **'Match History'**
  String get matchHistoryTitle;

  /// Title shown in the AppBar of the Match Details Page
  ///
  /// In en, this message translates to:
  /// **'Match Details'**
  String get matchDetailsTitle;

  /// Heading for the match details section
  ///
  /// In en, this message translates to:
  /// **'Match Details'**
  String get matchDetailsHeading;

  /// Label showing the winner's name
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String winnerLabel(String name);

  /// Label showing the commander's name
  ///
  /// In en, this message translates to:
  /// **'Commander: {name}'**
  String commanderLabel(String name);

  /// Text shown when no commanders are found
  ///
  /// In en, this message translates to:
  /// **'No Commanders found'**
  String get noCommanders;

  /// Text shown when something went wrong
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Text shown when a player started first
  ///
  /// In en, this message translates to:
  /// **'was the starting player'**
  String get startedFirst;

  /// Game duration label in match overview
  ///
  /// In en, this message translates to:
  /// **'Game Duration'**
  String get gameDuration;

  /// Tooltip for Scryfall link button
  ///
  /// In en, this message translates to:
  /// **'View on Scryfall'**
  String get viewOnScryfall;

  /// Heading for the players section
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersHeading;

  /// Column header for placement in players list
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get placementColumnHeader;

  /// Column header for commander in players list
  ///
  /// In en, this message translates to:
  /// **'Commander'**
  String get commanderColumnHeader;

  /// Column header for player in players list
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get playerColumnHeader;

  /// Title for the friends section
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// Title for the friend requests section
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequestsTitle;

  /// Button text for claiming a player
  ///
  /// In en, this message translates to:
  /// **'This is me'**
  String get thisIsMe;

  /// Heading for match information section
  ///
  /// In en, this message translates to:
  /// **'Match Information'**
  String get matchInformationHeading;

  /// Label showing the room ID
  ///
  /// In en, this message translates to:
  /// **'Room ID: {id}'**
  String roomIdLabel(String id);

  /// Label showing when the game was played
  ///
  /// In en, this message translates to:
  /// **'Played on:'**
  String get playedOnLabel;

  /// Message shown when changing player ownership
  ///
  /// In en, this message translates to:
  /// **'Changed your player from {oldName} to {newName}'**
  String changedPlayerMessage(String oldName, String newName);

  /// Message shown when selecting the same player
  ///
  /// In en, this message translates to:
  /// **'You were {name} in this game'**
  String wasPlayerMessage(String name);

  /// Title for the game mode section
  ///
  /// In en, this message translates to:
  /// **'Game Mode'**
  String get gameModeTitle;

  /// Title for the stats section
  ///
  /// In en, this message translates to:
  /// **'Your Stats'**
  String get statsTitle;

  /// Error message shown when match history fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load match history'**
  String get matchHistoryLoadError;

  /// Message shown when there is no match history to display
  ///
  /// In en, this message translates to:
  /// **'No match history available'**
  String get noMatchHistoryAvailable;

  /// Title shown on the game over page
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOverTitle;

  /// Match overview section title
  ///
  /// In en, this message translates to:
  /// **'Match Overview'**
  String get matchOverview;

  /// Winner label in match overview
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// Text shown when linking to an account
  ///
  /// In en, this message translates to:
  /// **'Link to my account'**
  String get linkToMyAccount;

  /// Final standings section title
  ///
  /// In en, this message translates to:
  /// **'Final Standings'**
  String get finalStandings;

  /// Life points display in standings
  ///
  /// In en, this message translates to:
  /// **'Life: {points}'**
  String lifePoints(int points);

  /// Game details section title
  ///
  /// In en, this message translates to:
  /// **'Game Details'**
  String get gameDetails;

  /// Label for first player selection
  ///
  /// In en, this message translates to:
  /// **'Who went first:'**
  String get whoWentFirst;

  /// Label for account owner selection
  ///
  /// In en, this message translates to:
  /// **'Please select the account owner from the list to sync the game stats to their account:'**
  String get accountOwner;

  /// Account owner dropdown option meaning the current user is not one of the players
  ///
  /// In en, this message translates to:
  /// **'I\'m not playing'**
  String get notPlayingOption;

  /// Tooltip for the badge shown on a standings row linked to another account
  ///
  /// In en, this message translates to:
  /// **'Linked to a friend\'s account'**
  String get linkedAccountBadge;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Play again button text
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// Return to home button text
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnToHome;

  /// Format for displaying duration
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationFormat(int hours, int minutes);

  /// Title for the add game dialog
  ///
  /// In en, this message translates to:
  /// **'Add Game to Match History'**
  String get addGameToHistoryTitle;

  /// Hint text for room ID input
  ///
  /// In en, this message translates to:
  /// **'Enter room ID'**
  String get enterRoomIdHint;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButtonText;

  /// Error message when game is not found
  ///
  /// In en, this message translates to:
  /// **'Game not found'**
  String get gameNotFoundError;

  /// Title for login/sign up section
  ///
  /// In en, this message translates to:
  /// **'Login/Sign Up'**
  String get loginSignUpTitle;

  /// Title for win rate stat
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRateTitle;

  /// Title for total wins stat
  ///
  /// In en, this message translates to:
  /// **'Total Wins'**
  String get totalWinsTitle;

  /// Title for total games stat
  ///
  /// In en, this message translates to:
  /// **'Total Games'**
  String get totalGamesTitle;

  /// Title for shortest game stat
  ///
  /// In en, this message translates to:
  /// **'Shortest Game'**
  String get shortestGameTitle;

  /// Title for longest game stat
  ///
  /// In en, this message translates to:
  /// **'Longest Game'**
  String get longestGameTitle;

  /// Title for average placement stat
  ///
  /// In en, this message translates to:
  /// **'Average\nPlacement'**
  String get averagePlacementTitle;

  /// Title for unique commanders stat
  ///
  /// In en, this message translates to:
  /// **'Unique\nCommanders'**
  String get uniqueCommandersTitle;

  /// Message shown when game ID is copied
  ///
  /// In en, this message translates to:
  /// **'Copied game ID'**
  String get copiedGameId;

  /// Title for times went first stat
  ///
  /// In en, this message translates to:
  /// **'Times\nWent First'**
  String get timesWentFirstTitle;

  /// Title for average EDHRec rank stat
  ///
  /// In en, this message translates to:
  /// **'Average\nEDHRec Rank'**
  String get avgEdhRecRankTitle;

  /// Title for most played commander stat
  ///
  /// In en, this message translates to:
  /// **'Most Played\nCommander'**
  String get mostPlayedCommanderTitle;

  /// Title for average game duration stat
  ///
  /// In en, this message translates to:
  /// **'Average\nGame Duration'**
  String get averageGameDurationTitle;

  /// Title for win rate when going first stat
  ///
  /// In en, this message translates to:
  /// **'Win Rate\nWhen First'**
  String get winRateWhenFirstTitle;

  /// Title for highest win rate commander stat
  ///
  /// In en, this message translates to:
  /// **'Best\nCommander'**
  String get bestCommanderTitle;

  /// Title for current win/loss streak stat
  ///
  /// In en, this message translates to:
  /// **'Current\nStreak'**
  String get currentStreakTitle;

  /// Title for most common opponent stat
  ///
  /// In en, this message translates to:
  /// **'Most Common\nOpponent'**
  String get mostCommonOpponentTitle;

  /// Title for nemesis stat - opponent who beats you most
  ///
  /// In en, this message translates to:
  /// **'Nemesis'**
  String get nemesisTitle;

  /// Title for average commander damage taken per game
  ///
  /// In en, this message translates to:
  /// **'Avg Commander\nDamage Taken'**
  String get avgCommanderDamageTakenTitle;

  /// Title for times eliminated by 21+ commander damage
  ///
  /// In en, this message translates to:
  /// **'Killed by\nCommander Dmg'**
  String get timesKilledByCommanderTitle;

  /// Title for best win rate by exact color identity combination
  ///
  /// In en, this message translates to:
  /// **'Best Color\nCombo'**
  String get bestColorComboTitle;

  /// Title for best win rate by individual color
  ///
  /// In en, this message translates to:
  /// **'Best Single\nColor'**
  String get bestSingleColorTitle;

  /// Text shown for features under construction
  ///
  /// In en, this message translates to:
  /// **'Under Construction'**
  String get underConstructionText;

  /// Text shown for features coming soon
  ///
  /// In en, this message translates to:
  /// **'Feature Coming Soon!'**
  String get comingSoonText;

  /// No description provided for @achievementColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievementColumnHeader;

  /// No description provided for @youTooltip.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTooltip;

  /// No description provided for @wentFirstTooltip.
  ///
  /// In en, this message translates to:
  /// **'Went First'**
  String get wentFirstTooltip;

  /// No description provided for @deleteMatchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Match'**
  String get deleteMatchDialogTitle;

  /// No description provided for @deleteMatchDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this match?'**
  String get deleteMatchDialogContent;

  /// No description provided for @cancelButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButtonLabel;

  /// No description provided for @deleteMatchButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Match'**
  String get deleteMatchButtonLabel;

  /// Snackbar error message with error details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorSnackbarMessage(Object error);

  /// Button label for restoring the previous game state on the Game Over page
  ///
  /// In en, this message translates to:
  /// **'Undo / Restore'**
  String get undoGameOverButtonLabel;

  /// Snackbar message shown when a previous game state is successfully restored from the Game Over page
  ///
  /// In en, this message translates to:
  /// **'Previous game restored!'**
  String get gameRestoredMessage;

  /// Label for PIN input field
  ///
  /// In en, this message translates to:
  /// **'4-Digit PIN'**
  String get pinInputLabel;

  /// Helper text for PIN input field
  ///
  /// In en, this message translates to:
  /// **'Confirms your identity when friends add you to a game'**
  String get pinInputHelper;

  /// Error text when PIN is invalid
  ///
  /// In en, this message translates to:
  /// **'Must be 4 digits'**
  String get pinInputError;

  /// Title for the friend search page
  ///
  /// In en, this message translates to:
  /// **'Find Friends'**
  String get findFriendsTitle;

  /// Hint text for the friend search input, which accepts either a username or a friend code
  ///
  /// In en, this message translates to:
  /// **'Search by name or friend code (e.g. A3F9K2XQ)'**
  String get friendCodeSearchHint;

  /// Message shown after sending a friend request
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get friendRequestSentMessage;

  /// Message shown when a name or friend code search returns no results
  ///
  /// In en, this message translates to:
  /// **'No user found.'**
  String get noUserFoundMessage;

  /// Prompt shown on the friend search page before searching
  ///
  /// In en, this message translates to:
  /// **'Search by name or friend code to find players.'**
  String get friendCodeSearchPrompt;

  /// Label above friend selection chips on customize player page
  ///
  /// In en, this message translates to:
  /// **'Select a friend'**
  String get selectFriendLabel;

  /// Text shown when a friend is linked to a player slot
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String linkedToFriend(String name);

  /// Button text to clear friend selection
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButtonText;

  /// Title for the PIN verification dialog
  ///
  /// In en, this message translates to:
  /// **'Verify {name}'**
  String verifyFriendTitle(String name);

  /// Prompt in the PIN verification dialog
  ///
  /// In en, this message translates to:
  /// **'Enter their 4-digit PIN to confirm identity.'**
  String get enterPinPrompt;

  /// Button text to verify PIN
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButtonText;

  /// Error shown when a friend PIN is incorrect, with attempts remaining
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. {count, plural, =1{1 attempt} other{{count} attempts}} remaining.'**
  String pinIncorrectError(int count);

  /// Error shown when the PIN flow is locked out after too many failed attempts
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {minutes} min.'**
  String pinLockedOutError(int minutes);

  /// Error shown when the PIN could not be verified due to offline or server error
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the PIN. Check your connection and try again.'**
  String get pinUnavailableError;

  /// Error shown when the selected friend has no PIN set
  ///
  /// In en, this message translates to:
  /// **'This friend hasn\'t set a PIN yet. Ask them to set one in their profile.'**
  String get pinNotSetError;

  /// Label for the friend code display on profile page
  ///
  /// In en, this message translates to:
  /// **'Friend Code'**
  String get friendCodeLabel;

  /// Tooltip for the copy friend code button
  ///
  /// In en, this message translates to:
  /// **'Copy friend code'**
  String get copyFriendCodeTooltip;

  /// Snackbar message shown when friend code is copied
  ///
  /// In en, this message translates to:
  /// **'Friend code copied!'**
  String get friendCodeCopiedMessage;

  /// Helper text explaining the friend code is the unique identifier, unlike username
  ///
  /// In en, this message translates to:
  /// **'Your unique code. Share it so a specific friend can add you exactly — even if someone else shares your username.'**
  String get friendCodeHelperText;

  /// Title for the PIN setup dialog shown to existing users
  ///
  /// In en, this message translates to:
  /// **'Set Your PIN'**
  String get setYourPinTitle;

  /// Description in the PIN setup dialog
  ///
  /// In en, this message translates to:
  /// **'Set a 4-digit PIN so friends can verify your identity when adding you to a game.'**
  String get setYourPinDescription;

  /// Button text to save PIN in setup dialog
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get savePinButtonText;

  /// Button text to send a friend request
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addFriendButtonText;

  /// Action label to block a user
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUserAction;

  /// Title for the block-user confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockUserConfirmTitle(String name);

  /// Body copy for the block-user confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'They\'ll be removed from your friends and won\'t be able to find you or send requests. They won\'t be notified.'**
  String get blockUserConfirmBody;

  /// Action label to unblock a user
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUserAction;

  /// Body of the unblock confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {name}?'**
  String unblockUserConfirmBody(String name);

  /// Title for the blocked-users management page
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsersTitle;

  /// Empty state message for the blocked-users page
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedUsersEmpty;

  /// Snackbar error shown when accepting a friend request fails because it predates current permission rules
  ///
  /// In en, this message translates to:
  /// **'This request was sent from an older version. Ask them to re-send it.'**
  String get legacyRequestAcceptError;

  /// Snackbar error shown when saving the game-over stats to the database fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the game. Check your connection and try again.'**
  String get gameSaveFailedError;

  /// Title for the change-PIN section on the profile page
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinTitle;

  /// Description for the change-PIN section on the profile page
  ///
  /// In en, this message translates to:
  /// **'Your PIN confirms your identity when friends add you to a game.'**
  String get changePinDescription;

  /// Label for the new-PIN input field on the profile page
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPinLabel;

  /// Snackbar message shown after the PIN is changed successfully
  ///
  /// In en, this message translates to:
  /// **'PIN updated!'**
  String get pinChangedMessage;

  /// Snackbar message shown after the profile is saved successfully
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSavedMessage;

  /// Snackbar error shown when saving the profile fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile. Try again.'**
  String get profileSaveFailedMessage;

  /// Label for the username field on the profile page
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Helper text under the username field explaining its purpose and that it isn't unique
  ///
  /// In en, this message translates to:
  /// **'How friends find and recognize you. Not unique — others may share this name.'**
  String get usernameHelperText;

  /// Label for the first name field on the profile page
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameLabel;

  /// Label for the last name field on the profile page
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameLabel;

  /// Label for the bio field on the profile page
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// Label for the read-only email field on the profile page
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Placeholder shown for an empty profile field when not editing
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetLabel;

  /// Button text to save profile changes when in editing mode
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfileButton;

  /// Button text to enter profile editing mode
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// Placeholder shown instead of the friend list on the customize player page when the user is anonymous
  ///
  /// In en, this message translates to:
  /// **'Sign in to link friends to players.'**
  String get signInToLinkFriends;

  /// Placeholder shown instead of the search field on the find-friends page when the user is anonymous
  ///
  /// In en, this message translates to:
  /// **'Sign in to add friends.'**
  String get signInToSearchFriends;

  /// Action label to remove a friend
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFriendAction;

  /// Title for the remove-friend confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeFriendConfirmTitle(String name);

  /// Body copy for the remove-friend confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'They won\'t be notified. You can add each other again anytime.'**
  String get removeFriendConfirmBody;

  /// Snackbar error shown when submitting the onboarding form fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile. Please try again.'**
  String get onboardingSaveFailedMessage;

  /// Error message shown when the blocked-users page fails to load or update
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your blocked list. Check your connection and try again.'**
  String get blockedUsersLoadFailedError;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
