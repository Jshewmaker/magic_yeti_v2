// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get counterAppBarTitle => 'Contador';

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
  String get resetPasswordSubmitText => 'If an account is registered with the provided email, we will send a link to reset your password';

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
  String get navigationDialogText => 'Are you sure you want to go to the home page? The current game progress will be lost.';

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
  String get accountOwnershipLinkText => '¡Vincula este jugador a tu cuenta para saber qué comandante eres!';

  @override
  String get accountOwnershipTitle => 'Este es mi comandante';

  @override
  String get matchHistoryTitle => 'Historial de Partidas';

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
  String get gameModeTitle => 'Modo de Juego';

  @override
  String get statsTitle => 'Tus Estadísticas';

  @override
  String get matchHistoryLoadError => 'Error al cargar el historial de partidas';

  @override
  String get noMatchHistoryAvailable => 'No hay historial de partidas disponible';

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
  String get accountOwner => 'Please select the account owner from the list to sync the game stats to their account:';

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
  String get deleteMatchDialogContent => 'Are you sure you want to delete this match?';

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get deleteMatchButtonLabel => 'Delete Match';

  @override
  String errorSnackbarMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get undoGameOverButtonLabel => 'Deshacer / Restaurar';

  @override
  String get gameRestoredMessage => '¡Juego anterior restaurado!';
}
