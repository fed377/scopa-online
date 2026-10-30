/// The signed-in player.
class UserState {
  const UserState({required this.uid, required this.nickname, required this.imgUrl});

  final String uid;
  final String nickname;
  final String imgUrl;
}
