import 'dart:async';
import 'dart:convert';

import 'package:CatViP/bloc/post/GetPost/getPost_event.dart';
import 'package:CatViP/model/post/postComment.dart';
import 'package:CatViP/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../bloc/post/GetPost/getPost_bloc.dart';
import '../../bloc/post/GetPost/getPost_state.dart';
import '../../bloc/post/new_post/new_post_bloc.dart';
import '../home_page.dart';

class Comments extends StatefulWidget {
  final int postId;

  const Comments({Key? key, required this.postId}) : super(key: key);

  @override
  State<Comments> createState() => _CommentsState(postId: postId);
}

class _CommentsState extends State<Comments> {
  final GetPostBloc _postBloc = GetPostBloc();
  late PostComment postComment;
  final int postId;
  final Widgets func = Widgets();
  //Controllers for input
  TextEditingController commentController = TextEditingController();

  _CommentsState({required this.postId});

  @override
  void initState() {
    _postBloc.add(GetPostComments(postId: postId));
    super.initState();

  }

  @override
  void dispose() {
    _postBloc.close(); // Make sure to close the bloc when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments", style: Theme.of(context).textTheme.bodyLarge),
        backgroundColor: HexColor("#ecd9c9"),
      ),
      body: CommentCard(),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          padding: const EdgeInsets.only(left: 16,right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/addImage.png'),
                  radius: 10,
              ),
              Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16,right: 8.0),
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Comment as username',
                        border: InputBorder.none,
                      ),
                    ),
                  )
              ),
              InkWell(
                onTap: () async {
                    _postBloc.add(
                        PostCommentPressed(
                            description: commentController.text.trim(),
                            postId: postId
                        )
                    );
                    commentController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.brown,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget CommentCard () {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16,),
      child: BlocProvider(
        create: (context) => _postBloc,
        child: BlocBuilder<GetPostBloc,GetPostState>(
          builder: (context, state) {
          if (state is GetPostCommentError) {
          return Center(
            child: Text(state.error!),
          );
          } else if (state is GetPostCommentInitial) {
          return Center(
            child: CircularProgressIndicator(color:  HexColor("#3c1e08"),),
          );
          } else if (state is GetPostCommentLoading) {
          return Center(
            child: CircularProgressIndicator(color:  HexColor("#3c1e08"),),
          );
          } else if (state is GetPostCommentLoaded) {
            List<PostComment> reversedComments = List.from(state.postComments.reversed);
            return ListView.builder(
                itemCount: reversedComments.length,
                itemBuilder: (context, index) {
                  PostComment postComment = reversedComments[index];
                  print("Post: ${postComment.toJson()}");
                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: postComment.profileImage != ""
                            ? Image.memory(base64Decode(postComment.profileImage!)).image
                            : AssetImage('assets/profileimage.png'),
                        radius: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16,),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: postComment.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      )
                                  ),
                                  TextSpan(
                                    text: ' ',
                                  ),
                                  TextSpan(
                                      text: postComment.description,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      )
                                  )
                                ]
                            ),),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                func.getFormattedDate(DateTime.parse(postComment.dateTime!)),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  );
                },
            );
          } else {
            return Container(

            );
          }
        }
        ),
      ),

    );
  }
}
