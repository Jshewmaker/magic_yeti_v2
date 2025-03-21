part of 'match_details_bloc.dart';

sealed class MatchDetailsState extends Equatable {
  const MatchDetailsState();

  @override
  List<Object> get props => [];
}

final class MatchDetailsInitial extends MatchDetailsState {}

final class MatchDetailsSuccess extends MatchDetailsState {}

final class MatchDetailsLoading extends MatchDetailsState {}

final class MatchDetailsDeleted extends MatchDetailsState {}

final class MatchDetailsError extends MatchDetailsState {
  const MatchDetailsError(this.error);
  final String error;
}
