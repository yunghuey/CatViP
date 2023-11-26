import 'dart:convert';

import 'package:CatViP/bloc/authentication/logout/logout_bloc.dart';
import 'package:CatViP/bloc/authentication/logout/logout_event.dart';
import 'package:CatViP/bloc/authentication/logout/logout_state.dart';
import 'package:CatViP/bloc/user/userprofile_bloc.dart';
import 'package:CatViP/bloc/user/userprofile_event.dart';
import 'package:CatViP/bloc/user/userprofile_state.dart';
import 'package:CatViP/model/user/user_model.dart';
import 'package:CatViP/pageRoutes/bottom_navigation_bar.dart';
import 'package:CatViP/pages/authentication/login_view.dart';
import 'package:CatViP/pages/cat/catprofile_view.dart';
import 'package:CatViP/pages/cat/createcat_view.dart';
import 'package:CatViP/pages/user/editprofile_view.dart';
import 'package:CatViP/repository/user_repo.dart';
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
  List<Map<String, String>> listPost = [
    {
      'images': 'assets/sunset.jpg',
    },
    {
      'images': 'assets/hk2.jpg',
    },
    {
      'images': 'assets/sunset.jpg'
    },
    {
      'images': 'assets/mountain.jpg'
    },
    {
      'images': 'assets/hk1.jpg',
    },
    {
      'images': 'assets/hk2.jpg',
    },
    {
      'images': 'assets/sunset.jpg'
    },
    {
      'images': 'assets/mountain.jpg'
    },
    {
      'images': 'assets/hk1.jpg',
    },
    {
      'images': 'assets/hk2.jpg',
    },
    {
      'images': 'assets/sunset.jpg'
    },
  ];

  List<Map<String, String>> listCat = [
    {
      'name': 'Tabby',
      'image': 'assets/Dinosaur.png'
    },
    {
      'name': 'Daisy',
      'image': 'assets/meow.jpg'
    }
  ];


  @override
  void initState() {
    logoutbloc = BlocProvider.of<LogoutBloc>(context);
    userBloc = BlocProvider.of<UserProfileBloc>(context);
    userBloc.add(StartLoadProfile());
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
  late UserModel user;
  String message = "Welcome";
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
            } else if (state is UserProfileLoadedState) {
              user = state.user;
              // setState(() {
              message = user.username ?? "Welcome";              // });
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _userDetails(),
                    // _buttons(),
                    _getAllCats(),
                    _getAllPosts(),
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
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context) => EditProfileView(),));
            },
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text("Register Cat"),
            onTap: (){
              Navigator.push(context,MaterialPageRoute(builder: (context) => CreateCatView(),));
            },
          ),
          ListTile(
            leading: Icon(Icons.grade_rounded),
            title: Text("Apply for expert"),
            onTap: (){},
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
          Text(user!.follower.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
          Text("Followers"),
        ],
      );
  }

  Widget _following(){
    return Column(
      children: [
        Text(user!.following.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
        Text("Following"),
      ],
    );
  }

  Widget _tipsPost(){
    if (user!.isExpert == true){
      return Column(
        children: [
          Text(user!.expertTips.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
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
          itemCount:listCat.length,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final cat = listCat[index];
            return Row(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: InkWell(
                        onTap: (){
                          Navigator.push(context,MaterialPageRoute(builder: (context) => CatProfileView(),));
                        },
                        child: CircleAvatar(
                          backgroundColor: HexColor("#3c1e08"),
                          radius: 40,
                          child: CircleAvatar(
                            radius: 38,
                            backgroundImage: ResizeImage(AssetImage(cat['image']!), width: 170),
                          ),
                        ),
                      ),
                    ),
                    Text(cat['name']!),
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
    return GridView.builder(
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
          },
          child: Container(
            color: Colors.grey,
            child: Image.asset(
              post['images']!,
              fit: BoxFit.cover,),
          ),
        );
      },
      itemCount: listPost.length,
    );
  }
}
