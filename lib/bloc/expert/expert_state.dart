import 'package:CatViP/model/expert/expert_model.dart';
import 'package:equatable/equatable.dart';

class ExpertState extends Equatable{
  @override
  List<Object> get props => [];
}

class ExpertProfileInitState extends ExpertState {}

class ExpertLoadingState extends ExpertState {}

class AppliedSuccessState extends ExpertState {}

class AppliedFailState extends ExpertState {
  String message;
  AppliedFailState({ required this.message});
}

class LoadedFormState extends ExpertState {
  ExpertApplyModel form;
  LoadedFormState({ required this.form });
}

class EmptyFormState extends ExpertState{}

class RevokeSuccessState extends ExpertState {}

class RevokeFailState extends ExpertState {}