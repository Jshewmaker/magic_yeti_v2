// Cloud Functions entry point. Each function lives in its own module and
// is re-exported here so the Firebase CLI discovers it.
export { validatePin } from './validate-pin';
export { onGameCreated } from './on-game-created';
export { searchByFriendCode } from './search-by-friend-code';
