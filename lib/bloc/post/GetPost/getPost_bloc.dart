
import 'package:CatViP/model/post/postComment.dart';
import 'package:CatViP/repository/post_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../model/post/post.dart';
import 'getPost_event.dart';
import 'getPost_state.dart';

class GetPostBloc extends Bloc<GetPostEvent, GetPostState> {

  final PostRepository postRepository = PostRepository();

  GetPostBloc() : super(GetPostInitial()) {
    on<GetPostList>((event, emit) async {
      try {
        emit(GetPostLoading());
        final List<Post> postList = await postRepository.fetchPost();
        emit(GetPostLoaded(postList: postList));

        if (postList[0].error != null) {
          emit(GetPostError(
              error: postList[0].error));
        }
      } on http.ClientException {
        emit(const GetPostError(
            error: "Failed to fetch data in your device online"));
      }
    });

    on<StartLoadOwnPost>((event, emit) async {
      emit(GetPostLoading());
      final List<Post> postList = await postRepository.fetchMyPost();
      if (postList.length > 0) {
        emit(GetPostLoaded(postList: postList));
      } else {
        emit(GetPostEmpty());
      }
    });

    on<StartLoadSingleCatPost>((event, emit) async {
      emit(GetPostLoading());
      final List<Post> postList = await postRepository.fetchCatPost(
          event.catid);
      if (postList.length > 0) {
        emit(GetPostSingleCatLoaded(postList: postList));
      } else {
        emit(GetPostEmpty());
      }
    });

    on<GetPostComments>((event, emit) async {
      try {
        emit(GetPostCommentLoading());
        print(event.postId);
        final List<PostComment> postComments = await postRepository
            .fetchPostComments(event.postId);
        emit(GetPostCommentLoaded(postComments: postComments));

        if (postComments[0].error != null) {
          emit(GetPostCommentError(
              error: postComments[0].error));
        }
      } catch (e) {
        emit(GetPostCommentError(
            error: "Be the first to comment!"));
      }
    });

    // create new comment
    on<StartNewComment>((event, emit) {
      emit(NewCommentInitState());
    });

    on<PostCommentPressed>((event, emit) async {
      emit(NewCommentLoadingState());
      try {
        bool isCreated = await postRepository.newComment(
            event.description, event.postId);
        if (isCreated) {
          final List<PostComment> updatedCommentList = await postRepository
              .fetchPostComments(event.postId);
          emit(NewCommentSuccessState());
          emit(GetPostCommentLoaded(postComments: updatedCommentList));
        } else if (event.description == "") {
          final List<PostComment> updatedCommentList = await postRepository
              .fetchPostComments(event.postId);
          emit(NewCommentSuccessState());
          emit(GetPostCommentLoaded(postComments: updatedCommentList));
        } else {
          emit(NewCommentFailState(message: "Failed to create comment"));
        }
      } catch (e) {
        emit(NewCommentFailState(message: "Failed to create comment"));
      }
    });

    // update action post
    on<StartActionPost>((event, emit) {
      emit(ActionPostInitState());
    });

    on<UpdateActionPost>((event, emit) async {
      try {
        // Attempt to post a new comment
        bool isUpdated = await postRepository.actionPost(
            event.postId, event.actionTypeId);
        if (isUpdated) {
          emit(ActionPostSuccessState());
        }
      } catch (e) {
        emit(ActionPostFailState(message: "Failed to update action"));
      }
     });
    on<StartDeleteActionPost>((event, emit) {
      emit(DeleteActionPostInitState());
    });

    on<DeleteActionPost>((event, emit) async {
      try {
        bool isUpdated = await postRepository.deleteActPost(event.postId);
      } catch (e) {
        emit(ActionPostFailState(message: "Failed to update action"));
      }
    });
  }
}
