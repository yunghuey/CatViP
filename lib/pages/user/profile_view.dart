import 'dart:convert';
import 'package:CatViP/bloc/authentication/logout/logout_bloc.dart';
import 'package:CatViP/bloc/authentication/logout/logout_event.dart';
import 'package:CatViP/bloc/authentication/logout/logout_state.dart';
import 'package:CatViP/bloc/cat/catprofile_bloc.dart';
import 'package:CatViP/bloc/cat/catprofile_event.dart';
import 'package:CatViP/bloc/cat/catprofile_state.dart';
import 'package:CatViP/bloc/expert/expert_bloc.dart';
import 'package:CatViP/bloc/expert/expert_event.dart';
import 'package:CatViP/bloc/post/DeletePost/deletePost_bloc.dart';
import 'package:CatViP/bloc/post/DeletePost/deletePost_event.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_bloc.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_event.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_state.dart';
import 'package:CatViP/bloc/user/userprofile_bloc.dart';
import 'package:CatViP/bloc/user/userprofile_event.dart';
import 'package:CatViP/bloc/user/userprofile_state.dart';
import 'package:CatViP/model/cat/cat_model.dart';
import 'package:CatViP/model/post/post.dart';
import 'package:CatViP/model/user/user_model.dart';
import 'package:CatViP/pageRoutes/bottom_navigation_bar.dart';
import 'package:CatViP/pages/authentication/login_view.dart';
import 'package:CatViP/pages/cat/catprofile_view.dart';
import 'package:CatViP/pages/cat/createcat_view.dart';
import 'package:CatViP/pages/expert/expertIntro_view.dart';
import 'package:CatViP/pages/expert/expertcheck_view.dart';
import 'package:CatViP/pages/expert/expertform_view.dart';
import 'package:CatViP/pages/expert/expertprofile_view.dart';
import 'package:CatViP/pages/post/comment.dart';
import 'package:CatViP/pages/post/own_post.dart';
import 'package:CatViP/pages/search/searchuser_view.dart';
import 'package:CatViP/pages/user/editpost_view.dart';
import 'package:CatViP/pages/user/editprofile_view.dart';
import 'package:CatViP/repository/user_repo.dart';
import 'package:CatViP/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late LogoutBloc logoutbloc;
  late UserProfileBloc userBloc;
  late CatProfileBloc catBloc;
  late GetPostBloc postBloc;
  late ExpertBloc expertBloc;
  final Widgets func = Widgets();
  late DeletePostBloc deleteBloc;

  @override
  void initState() {
    logoutbloc = BlocProvider.of<LogoutBloc>(context);
    userBloc = BlocProvider.of<UserProfileBloc>(context);
    userBloc.add(StartLoadProfile());
    catBloc = BlocProvider.of<CatProfileBloc>(context);
    catBloc.add(StartLoadCat());
    postBloc = BlocProvider.of<GetPostBloc>(context);
    postBloc.add(StartLoadOwnPost());
    deleteBloc = BlocProvider.of<DeletePostBloc>(context);
    super.initState();
  }
  late final msg = BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state){
        if (state is UserProfileLoadingState){
          return Center(child: CircularProgressIndicator(color:  HexColor("#3c1e08"),));
        }
        return Container();
      }
  );

  late List<CatModel> cats;
  late List<Post> listPost;
  late UserModel user;
  String message = "Welcome";
  final String applyExpert = "Apply as Expert";
  final String checkExpert = "Check application status";
  final String viewExpert = "You are an expert!";
  String expertMsg = "Apply as Expert";

  //  need to get all cat of this user and all post by this user
  // when tap on cat, should be able to get the index
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state){
            if (state is UserProfileLoadedState) {
              final username = state.user?.username ?? "Welcome";
              return Text(
                username,
                style: Theme.of(context).textTheme.bodyLarge,
              );
            } else {
              return Text( "Welcome", style: Theme.of(context).textTheme.bodyLarge,);
            }
          },
        ),
        backgroundColor: HexColor("#ecd9c9"),
        bottomOpacity: 0.0,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: HexColor("#3c1e08"),),
            onPressed: (){
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context){
                  return _menu();
                },
              ); // showModalbottomsheet
            },
          )
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LogoutBloc, LogoutState>(
            listener: (context, state){
              if (state is LogoutSuccessState){
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(
                    builder: (context) => LoginView()), (Route<dynamic> route) => false
                );
              }
            },
          ),
          BlocListener<UserProfileBloc, UserProfileState>(
              listener: (context, state){
                if (state is UserProfileErrorState){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message))
                  );
                }
              }
          )
        ],
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileLoadingState) {
              return Center(child: CircularProgressIndicator(color:  HexColor("#3c1e08"),));
            }
            else if (state is UserProfileLoadedState) {
              user = state.user;
              expertMsg = user.validToApply! == 1 ? viewExpert : user.validToApply! == 0 ? applyExpert : checkExpert;
              message = user.username ?? "Welcome";
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _userDetails(),
                    BlocBuilder<CatProfileBloc, CatProfileState>(
                      builder: (context, state) {
                        if (state is CatProfileLoadingState) {
                          return Center(child: CircularProgressIndicator(color: HexColor("#3c1e08")));
                        }
                        else if (state is CatProfileLoadedState) {
                          cats = state.cats;
                          return _getAllCats();
                        }
                        else {
                          return Container(child: const Text("Add your own cat now!", style: TextStyle(fontSize: 16))); // Handle other cases
                        }
                      },
                    ),
                    BlocBuilder<GetPostBloc, GetPostState>(
                      builder: (context, state) {
                        if (state is GetPostLoading) {
                          return Center(child: CircularProgressIndicator(color: HexColor("#3c1e08")));
                        } else if (state is GetPostLoaded) {
                          listPost = state.postList;
                          return _getAllPosts();
                        } else {
                          return Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                child: Text("Create your first post today!",style: TextStyle(fontSize: 16)),
                              )
                          ); // Handle other cases
                        }
                      },
                    ),
                    // _getAllPosts(),
                  ],
                ),
              );
            } else {
              return Container(); // Handle other cases
            }
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }

  Widget _profileImage(){
      return Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape:BoxShape.circle,
          image: DecorationImage(
          image: user.profileImage != ""
                ? MemoryImage(base64Decode(user!.profileImage!)) as ImageProvider<Object>
                : AssetImage('assets/profileimage.png'),
          fit: BoxFit.cover,
          ),
        )
      );
  }

  Widget _menu(){
    return Container(
      color: HexColor("#ecd9c9"),
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("Edit profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileView()),
              ).then((result) {
                if (result == true) {
                  Navigator.pop(context);
                  userBloc.add(StartLoadProfile());
                  catBloc.add(StartLoadCat());
                  postBloc.add(StartLoadOwnPost());
                } else{
                  Navigator.pop(context);
                }
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("Register cat"),
            onTap: (){
              Navigator.push(
                  context,MaterialPageRoute(builder: (context) => CreateCatView(),)
              ).then((result) {
                if (result == true){
                  Navigator.pop(context);
                  catBloc.add(StartLoadCat());
                } else{
                  Navigator.pop(context);

                }
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.grade_rounded),
            title: Text(expertMsg),
            onTap: (){
              // not an expert and nvr apply before
                if (!user.isExpert! && user.validToApply! == 0){
                  // go to introduction page and then apply page
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpertIntro())
                  ).then((result) {
                    Navigator.pop(context);
                    userBloc.add(StartLoadProfile());
                  });
                //   not expert and not valid to apply -- got pending
                }
                else if (user.isExpert!){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpertProfileView())
                  ).then((result) {
                    Navigator.pop(context);
                    userBloc.add(StartLoadProfile());
                  });
                }
                else {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpertCheckView(formstatus: user.validToApply!))
                  ).then((result) {
                    Navigator.pop(context);
                    userBloc.add(StartLoadProfile());
                  });
                }
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: (){
              logoutbloc.add(LogoutButtonPressed());
            },
          )
        ],
      )
    );
  }

  Widget _followers(){
      return Column(
        children: [
          Text(user.follower.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
          Text("Followers"),
        ],
      );
  }

  Widget _following(){
    return Column(
      children: [
        Text(user.following.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
        Text("Following"),
      ],
    );
  }

  Widget _tipsPost(){
    if (user.isExpert == true){
      return Column(
        children: [
          Text(user.expertTips.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
          Text("Tips"),
        ],
      );
    } else {
      return Column();
    }
  }

  Widget _userDetails(){
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _profileImage(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _followers(),
                _following(),
                _tipsPost(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                padding: EdgeInsets.all(5),
                child: ElevatedButton(
                    onPressed: (){},
                    child: Text("Follow"),
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(BorderSide(color: HexColor("#3c1e08"), width: 1)),
                      backgroundColor: MaterialStateProperty.all<HexColor>(HexColor("#ecd9c9")),
                      foregroundColor: MaterialStateProperty.all<HexColor>(HexColor("#3c1e08")),
                    ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                padding: EdgeInsets.all(5),
                child: ElevatedButton(
                    onPressed: (){},
                    child: Text("Message"),
                    style: ButtonStyle(
                      side: MaterialStateProperty.all(BorderSide(color: HexColor("#3c1e08"), width: 1)),
                      backgroundColor: MaterialStateProperty.all<HexColor>(HexColor("#ecd9c9")),
                      foregroundColor: MaterialStateProperty.all<HexColor>(HexColor("#3c1e08")),
                    ),),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAllCats(){
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: Container(
        height: 120,
        child: ListView.builder(
          itemCount:cats.length,
          reverse: true,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final cat = cats[index];
            return Row(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InkWell(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CatProfileView(currentcat: cats[index],fromOwner: true,)))
                              .then((value) {
                                  catBloc.add(StartLoadCat());
                                  postBloc.add(StartLoadOwnPost());
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: HexColor("#3c1e08"),
                          radius: 40,
                          child: CircleAvatar(
                            radius: 38,
                            backgroundImage: cats[index].profileImage != ""
                                ? MemoryImage(base64Decode(cats[index].profileImage))  as ImageProvider<Object>
                                : AssetImage('assets/profileimage.png'),
                          ),
                        ),
                      ),
                    ),
                    Text(cats[index].name),
                  ],
                ),
              ],
            );
          },

        ),
      ),
    );
  }

  Widget _getAllPosts(){
    return Card(
      color: HexColor("#ecd9c9"),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: ListView.builder(
          shrinkWrap: true, // Added shrinkWrap
          physics: NeverScrollableScrollPhysics(), // Disable scrolling for the ListView
          itemCount: listPost.length,
          itemBuilder: (context, index) {
            final Post post = listPost[index];
            print("Post: ${post.toJson()}");
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.postImages != null && post.postImages!.isNotEmpty)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.transparent,
                        backgroundImage: post.profileImage != ""
                            ? Image.memory(base64Decode(post.profileImage!)).image
                            : AssetImage('assets/profileimage.png'),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.username!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shrinkWrap: true,
                                children: [
                                  'Edit',
                                  'Delete'
                                ]
                                    .map(
                                      (e) => InkWell(
                                    onTap: () async {
                                      if (e == 'Edit') {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => EditPost(currentPost: post))
                                        ).then((result) {});
                                      } else if (e == 'Delete') {
                                        deleteBloc.add(DeleteButtonPressed(postId: post.id!));
                                        await Future.delayed(Duration(milliseconds: 100));
                                        Navigator.pop(context);
                                        postBloc.add(StartLoadOwnPost());
                                        //Navigator.push(context, MaterialPageRoute(builder: (context) => OwnPosts()));

                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      child: Text(e),
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                SizedBox(height: 4.0),
                AspectRatio(
                  aspectRatio: 1.0, // Set the aspect ratio (adjust as needed)
                  child: Image.memory(
                    base64Decode(post.postImages![0].image!),
                    fit: BoxFit.cover,
                  ),
                ),
                Row(
                  children: [
                    _FavoriteButton(
                      postId: post.id!,
                      actionTypeId: post.currentUserAction!,
                      onFavoriteChanged: (bool isThumbsUpSelected) {
                        setState(() {
                          post.likeCount = post.likeCount! + (isThumbsUpSelected ? 1 : -1);
                        });
                        print('Is Thumbs Up Selected: $isThumbsUpSelected');
                      },
                    ),
                    SizedBox(width: 4.0),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Comments(postId: post.id!),
                        ),
                      ),
                      icon: Icon(
                        Icons.comment_bank_outlined,
                        color: Colors.black,
                        size: 24.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${post.likeCount.toString()} likes",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.0,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 8),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: post.mentionedCats?[0].catName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                              ),
                              TextSpan(
                                text: post.description.toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Comments(postId: post.id!),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: post.commentCount! > 0
                              ? Text(
                            'View all ${post.commentCount} comments',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          )
                              : SizedBox.shrink(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          func.getFormattedDate(post.dateTime!),
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  /*
  * return GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  childAspectRatio: 1/1,
  crossAxisSpacing: 2,
  mainAxisSpacing: 2,
  ),
  itemBuilder: (context, index){
  final post = listPost[index];

  return GestureDetector(
  onTap: (){
  //   handle one image
  //   new page
  //   wait for wafir's code

  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnPosts()));

  },
  child: Container(
  color: Colors.grey,
  child: post.postImages != null && post.postImages!.isNotEmpty ?
  Image(image: MemoryImage(base64Decode(post.postImages![0].image!)),fit: BoxFit.cover,) : Container(),
  ),
  );
  },
  itemCount: listPost.length,
  );*/

}


class _FavoriteButton extends StatefulWidget {
  final int postId;
  final int actionTypeId;
  final ValueChanged<bool> onFavoriteChanged;

  const _FavoriteButton({
    Key? key,
    required this.postId,
    required this.actionTypeId,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState(
    postId: postId,
    actionTypeId: actionTypeId,
    onFavoriteChanged: onFavoriteChanged,
  );
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool isFavorite = false;
  final GetPostBloc _postBloc = GetPostBloc();
  final int postId;
  final int actionTypeId;
  bool thumbsUpSelected = false;
  bool thumbsDownSelected = false;
  final ValueChanged<bool> onFavoriteChanged;

  _FavoriteButtonState({
    required this.postId,
    required this.actionTypeId,
    required this.onFavoriteChanged,
  });
  @override
  void initState() {
    super.initState();

    // Initialize the state based on the provided actionTypeId
    if (actionTypeId == 1) {
      thumbsUpSelected = true;
    } else if (actionTypeId == 2) {
      thumbsDownSelected = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              thumbsUpSelected = !thumbsUpSelected;
              if (thumbsUpSelected) {
                thumbsDownSelected = false;
              }
            });

            // Update the action type for the specific post
            if(thumbsUpSelected == true) {
              int newActionTypeId = 1;
              _postBloc.add(UpdateActionPost(
                postId: postId,
                actionTypeId: newActionTypeId,
              ));
              onFavoriteChanged(thumbsUpSelected);
            } else if(thumbsUpSelected == false) {
              int newActionTypeId = 2;
              _postBloc.add(UpdateActionPost(
                postId: postId,
                actionTypeId: newActionTypeId,
              ));
              onFavoriteChanged(thumbsUpSelected);
            }
          },
          icon: Icon(
            thumbsUpSelected ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: thumbsUpSelected ? Colors.blue : Colors.black,
            size: 24.0,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              thumbsDownSelected = !thumbsDownSelected;
              if (thumbsDownSelected) {
                thumbsUpSelected = false;
              }
            });

            // Update the action type for the specific post
            if(thumbsDownSelected == true) {
              _postBloc.add(UpdateActionPost(
                postId: postId,
                actionTypeId: 2,
              ));
              onFavoriteChanged(thumbsUpSelected);
            }
          },
          icon: Icon(
            thumbsDownSelected ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
            color: thumbsDownSelected ? Colors.red : Colors.black,
            size: 24.0,
          ),
        ),
      ],
    );
  }
}

