// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get counterAppBarTitle => 'Counter';

  @override
  String get authenticationFailure => 'Authentication failure';

  @override
  String get createAccountButtonText => 'CREATE AN ACCOUNT';

  @override
  String get forgotPasswordText => 'Forgot Password?';

  @override
  String get invalidEmailInputErrorText => 'Invalid email';

  @override
  String get invalidPasswordInputErrorText => 'Invalid password';

  @override
  String get gameId => 'Game ID';

  @override
  String get loginButtonText => 'Login';

  @override
  String get logOutButtonText => 'Logout';

  @override
  String get loginWelcomeText => 'Welcome to Magic Yeti!';

  @override
  String get emailInputLabelText => 'Email';

  @override
  String get passwordInputLabelText => 'Password';

  @override
  String get resetPasswordSubmitText =>
      'If an account is registered with the provided email, we will send a link to reset your password';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get signInWithAppleButtonText => 'Sign in with Apple';

  @override
  String get signUpWithAppleButtonText => 'Sign up with Apple';

  @override
  String get signInWithGoogleButtonText => 'Sign in with Google';

  @override
  String get signUpWithGoogleButtonText => 'Sign up with Google';

  @override
  String get signUpAppBarTitle => 'Create Account';

  @override
  String get signUpButtonText => 'Sign Up';

  @override
  String get signUpFailure => 'Unable to create an account';

  @override
  String get submitButtonText => 'Submit';

  @override
  String get searchButtonText => 'Search';

  @override
  String get resultsTabResults => 'Results';

  @override
  String get resultsTabAnalysis => 'Analysis';

  @override
  String get resultsTabTimeline => 'Timeline';

  @override
  String get navigationDialogText =>
      'Are you sure you want to go to the home page? The current game progress will be lost.';

  @override
  String get exitGameDialogText => 'Exit Game?';

  @override
  String get confirmTextButton => 'Confirm';

  @override
  String get cancelTextButton => 'Cancel';

  @override
  String get resetGameDialogText => 'Reset Game?';

  @override
  String numberOfPlayers(int numberOfPlayers) {
    return '$numberOfPlayers Player';
  }

  @override
  String get searchCommanderHintText => 'Search for your commander';

  @override
  String get saveButtonText => 'Save';

  @override
  String get accountOwnershipLinkText =>
      'Link this player to your account so we know which commander you are!';

  @override
  String get accountOwnershipTitle => 'This is my commander';

  @override
  String get matchHistoryTitle => 'Match History';

  @override
  String get matchDetailsTitle => 'Match Details';

  @override
  String get matchDetailsHeading => 'Match Details';

  @override
  String winnerLabel(String name) {
    return 'Winner: $name';
  }

  @override
  String commanderLabel(String name) {
    return 'Commander: $name';
  }

  @override
  String get noCommanders => 'No Commanders found';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get startedFirst => 'was the starting player';

  @override
  String get gameDuration => 'Game Duration';

  @override
  String get viewOnScryfall => 'View on Scryfall';

  @override
  String get playersHeading => 'Players';

  @override
  String get placementColumnHeader => 'Placement';

  @override
  String get commanderColumnHeader => 'Commander';

  @override
  String get playerColumnHeader => 'Player';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendRequestsTitle => 'Friend Requests';

  @override
  String get thisIsMe => 'This is me';

  @override
  String get matchInformationHeading => 'Match Information';

  @override
  String roomIdLabel(String id) {
    return 'Room ID: $id';
  }

  @override
  String get playedOnLabel => 'Played on:';

  @override
  String changedPlayerMessage(String oldName, String newName) {
    return 'Changed your player from $oldName to $newName';
  }

  @override
  String wasPlayerMessage(String name) {
    return 'You were $name in this game';
  }

  @override
  String get gameModeTitle => 'Game Mode';

  @override
  String get statsTitle => 'Your Stats';

  @override
  String get matchHistoryLoadError => 'Failed to load match history';

  @override
  String get noMatchHistoryAvailable => 'No match history available';

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get matchOverview => 'Match Overview';

  @override
  String get winner => 'Winner';

  @override
  String get linkToMyAccount => 'Link to my account';

  @override
  String get finalStandings => 'Final Standings';

  @override
  String lifePoints(int points) {
    return 'Life: $points';
  }

  @override
  String get gameDetails => 'Game Details';

  @override
  String get whoWentFirst => 'Who went first:';

  @override
  String get accountOwner =>
      'Please select the account owner from the list to sync the game stats to their account:';

  @override
  String get notPlayingOption => 'I\'m not playing';

  @override
  String get linkedAccountBadge => 'Linked to a friend\'s account';

  @override
  String get cancel => 'Cancel';

  @override
  String get playAgain => 'Play Again';

  @override
  String get returnToHome => 'Return to Home';

  @override
  String durationFormat(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get addGameToHistoryTitle => 'Add Game to Match History';

  @override
  String get enterRoomIdHint => 'Enter room ID';

  @override
  String get addButtonText => 'Add';

  @override
  String get gameNotFoundError => 'Game not found';

  @override
  String get loginSignUpTitle => 'Login/Sign Up';

  @override
  String get winRateTitle => 'Win Rate';

  @override
  String get totalWinsTitle => 'Total Wins';

  @override
  String get totalGamesTitle => 'Total Games';

  @override
  String get shortestGameTitle => 'Shortest Game';

  @override
  String get longestGameTitle => 'Longest Game';

  @override
  String get averagePlacementTitle => 'Average\nPlacement';

  @override
  String get uniqueCommandersTitle => 'Unique\nCommanders';

  @override
  String get copiedGameId => 'Copied game ID';

  @override
  String get timesWentFirstTitle => 'Times\nWent First';

  @override
  String get avgEdhRecRankTitle => 'Average\nEDHRec Rank';

  @override
  String get mostPlayedCommanderTitle => 'Most Played\nCommander';

  @override
  String get averageGameDurationTitle => 'Average\nGame Duration';

  @override
  String get winRateWhenFirstTitle => 'Win Rate\nWhen First';

  @override
  String get bestCommanderTitle => 'Best\nCommander';

  @override
  String get currentStreakTitle => 'Current\nStreak';

  @override
  String get mostCommonOpponentTitle => 'Most Common\nOpponent';

  @override
  String get nemesisTitle => 'Nemesis';

  @override
  String get avgCommanderDamageTakenTitle => 'Avg Commander\nDamage Taken';

  @override
  String get timesKilledByCommanderTitle => 'Killed by\nCommander Dmg';

  @override
  String get bestColorComboTitle => 'Best Color\nCombo';

  @override
  String get bestSingleColorTitle => 'Best Single\nColor';

  @override
  String get underConstructionText => 'Under Construction';

  @override
  String get comingSoonText => 'Feature Coming Soon!';

  @override
  String get achievementColumnHeader => 'Achievement';

  @override
  String get youTooltip => 'You';

  @override
  String get wentFirstTooltip => 'Went First';

  @override
  String get deleteMatchDialogTitle => 'Delete Match';

  @override
  String get deleteMatchDialogContent =>
      'Are you sure you want to delete this match?';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get deleteMatchButtonLabel => 'Delete Match';

  @override
  String errorSnackbarMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get undoGameOverButtonLabel => 'Undo / Restore';

  @override
  String get gameRestoredMessage => 'Previous game restored!';

  @override
  String get pinInputLabel => '4-Digit PIN';

  @override
  String get pinInputHelper =>
      'Confirms your identity when friends add you to a game';

  @override
  String get pinInputError => 'Must be 4 digits';

  @override
  String get findFriendsTitle => 'Find Friends';

  @override
  String get friendCodeSearchHint =>
      'Search by name or friend code (e.g. A3F9K2XQ)';

  @override
  String get friendRequestSentMessage => 'Friend request sent!';

  @override
  String get noUserFoundMessage => 'No user found.';

  @override
  String get friendCodeSearchPrompt =>
      'Search by name or friend code to find players.';

  @override
  String get selectFriendLabel => 'Select an account';

  @override
  String linkedToFriend(String name) {
    return 'Linked to $name';
  }

  @override
  String get clearButtonText => 'Clear';

  @override
  String verifyFriendTitle(String name) {
    return 'Verify $name';
  }

  @override
  String get enterPinPrompt => 'Enter their 4-digit PIN to confirm identity.';

  @override
  String get verifyButtonText => 'Verify';

  @override
  String get accountOwnerOptionLabel => 'Me';

  @override
  String pinIncorrectError(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attempts',
      one: '1 attempt',
    );
    return 'Incorrect PIN. $_temp0 remaining.';
  }

  @override
  String pinLockedOutError(int minutes) {
    return 'Too many attempts. Try again in $minutes min.';
  }

  @override
  String get pinUnavailableError =>
      'Couldn\'t verify the PIN. Check your connection and try again.';

  @override
  String get pinNotSetError =>
      'This friend hasn\'t set a PIN yet. Ask them to set one in their profile.';

  @override
  String get friendCodeLabel => 'Friend Code';

  @override
  String get copyFriendCodeTooltip => 'Copy friend code';

  @override
  String get friendCodeCopiedMessage => 'Friend code copied!';

  @override
  String get friendCodeHelperText =>
      'Your unique code. Share it so a specific friend can add you exactly — even if someone else shares your username.';

  @override
  String get setYourPinTitle => 'Set Your PIN';

  @override
  String get setYourPinDescription =>
      'Set a 4-digit PIN so friends can verify your identity when adding you to a game.';

  @override
  String get savePinButtonText => 'Save PIN';

  @override
  String get addFriendButtonText => 'Add';

  @override
  String get blockUserAction => 'Block';

  @override
  String blockUserConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockUserConfirmBody =>
      'They\'ll be removed from your friends and won\'t be able to find you or send requests. They won\'t be notified.';

  @override
  String get unblockUserAction => 'Unblock';

  @override
  String unblockUserConfirmBody(String name) {
    return 'Are you sure you want to unblock $name?';
  }

  @override
  String get blockedUsersTitle => 'Blocked Users';

  @override
  String get blockedUsersEmpty => 'You haven\'t blocked anyone.';

  @override
  String get legacyRequestAcceptError =>
      'This request was sent from an older version. Ask them to re-send it.';

  @override
  String get gameSaveFailedError =>
      'Couldn\'t save the game. Check your connection and try again.';

  @override
  String get changePinTitle => 'Change PIN';

  @override
  String get changePinDescription =>
      'Your PIN confirms your identity when friends add you to a game.';

  @override
  String get newPinLabel => 'New PIN';

  @override
  String get pinChangedMessage => 'PIN updated!';

  @override
  String get profileSavedMessage => 'Profile saved';

  @override
  String get profileSaveFailedMessage =>
      'Couldn\'t save your profile. Try again.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHelperText =>
      'How friends find and recognize you. Not unique — others may share this name.';

  @override
  String get usernameRequiredError => 'Username is required';

  @override
  String get usernameTooShortError => 'Username must be at least 2 characters';

  @override
  String get usernameTooLongError => 'Username must be 30 characters or fewer';

  @override
  String get usernameInvalidMessage => 'Fix your username before saving.';

  @override
  String get searchFailedMessage =>
      'Search failed. Check your connection and try again.';

  @override
  String get firstNameLabel => 'First Name';

  @override
  String get lastNameLabel => 'Last Name';

  @override
  String get bioLabel => 'Bio';

  @override
  String get emailLabel => 'Email';

  @override
  String get notSetLabel => 'Not set';

  @override
  String get saveProfileButton => 'Save Profile';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get signInToLinkFriends => 'Sign in to link friends to players.';

  @override
  String get signInToSearchFriends => 'Sign in to add friends.';

  @override
  String get removeFriendAction => 'Remove';

  @override
  String removeFriendConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeFriendConfirmBody =>
      'They won\'t be notified. You can add each other again anytime.';

  @override
  String get onboardingSaveFailedMessage =>
      'Failed to save profile. Please try again.';

  @override
  String get blockedUsersLoadFailedError =>
      'Couldn\'t load your blocked list. Check your connection and try again.';
}
