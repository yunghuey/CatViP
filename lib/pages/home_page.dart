import 'dart:convert';
import 'package:CatViP/bloc/chat/chat_bloc.dart';
import 'package:CatViP/bloc/chat/chat_event.dart';
import 'package:CatViP/bloc/report%20case/ReportCaseCount/CaseReportCountEvent.dart';
import 'package:CatViP/bloc/report%20case/ReportCaseCount/CaseReportCountBloc.dart';
import 'package:CatViP/pages/SnackBarDesign.dart';
import 'package:CatViP/pages/chat/chatlist_view.dart';
import 'package:CatViP/pages/chat/messenger_icon.dart';
import 'package:CatViP/pages/post/comment.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_bloc.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_event.dart';
import 'package:CatViP/bloc/post/GetPost/getPost_state.dart';
import 'package:CatViP/pages/report/CaseIcon.dart';
import 'package:CatViP/pages/search/searchuser_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/post/ReportPost/reportPost_bloc.dart';
import '../bloc/post/ReportPost/reportPost_event.dart';
import '../bloc/post/ReportPost/reportPost_state.dart';
import '../model/post/post.dart';
import '../widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GetPostBloc _postBloc = GetPostBloc();
  late ReportPostBloc reportBloc;
  late ChatBloc chatBloc;
  late CaseReportCountBloc caseCountBloc;
  int? selectedPostIndex;
  late final int? postId;
  final Widgets func = Widgets();
  bool isFavorite = false;
  bool thumbsUpSelected = false;
  bool thumbsDownSelected = false;
  bool hasBeenLiked = false;
  TextEditingController reportController = TextEditingController();
  Set<int> reportedPostIds = {};
  PageController _pageController = PageController();
  late List<Post> postList;
  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 0);
  bool _isVisible = false;
  double startOffset = 0;
  late List<int> _currentPage;
  bool _isFirstLoaded = true;

  @override
  void initState() {
    chatBloc = BlocProvider.of<ChatBloc>(context);
    reportBloc = BlocProvider.of<ReportPostBloc>(context);
    caseCountBloc = BlocProvider.of<CaseReportCountBloc>(context);
    refreshPosts();
    showToTopButton();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    retrieveSharedPreference();
    return BlocProvider(
      create: (context) => _postBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/logo.png', fit: BoxFit.contain, height: 50),
              SizedBox(
                width: 8.0,
              ),
              Text('CatViP', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          backgroundColor: HexColor("#ecd9c9"),
          bottomOpacity: 0.0,
          elevation: 0.0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatListView(),
                  ),
                ).then((value) => refreshPosts());
              },
              icon: MessengerIcon(),
            ),
          ],
        ),
        body: _buildListUser(),
      ),
    );
  }

  Widget _floatingButton() {
    if (_isVisible) {
      return AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          return Visibility(
            visible: _isVisible,
            child: FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0.0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );

                setState(() {
                  _isVisible = false;
                });
              },
              child: Icon(Icons.arrow_upward),
              backgroundColor: Colors.brown,
            ),
          );
        },
      );
    }

    return MissingCaseIcon();
  }

  Future<void> refreshPosts() async {
    chatBloc.add(UnreadInitEvent());
    caseCountBloc.add(CaseCountInitEvent());
    _postBloc.add(GetPostList());
    // await Future.delayed(Duration(seconds: 2)); // Adjust the duration as needed
    _isFirstLoaded = true;
    // Retrieve the updated post list
    // final updatedState = _postBloc.state;
    // if (updatedState is GetPostLoaded) {
    //   setState(() {
    //     postList = updatedState.postList;
    //     _isVisible = false;
    //   });
    // }
  }

  void showToTopButton() {
    _scrollController.addListener(() {
      if (_scrollController.offset == _scrollController.initialScrollOffset &&
          _isVisible) {
        setState(() {
          _isVisible = false;
        });
      } else if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          _isVisible) {
        setState(() {
          _isVisible = false;
        });
      } else if (_scrollController.position.userScrollDirection ==
              ScrollDirection.forward &&
          !_isVisible) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  Widget _buildListUser() {
    return Container(
      color: HexColor("#ecd9c9"),
      child: BlocProvider(
        create: (context) => _postBloc,
        child: BlocBuilder<GetPostBloc, GetPostState>(
          builder: (context, state) {
            if (state is GetPostError) {
              refreshPosts();
              return const Center(
                child: Text("Loading..."),
              );
            } else if (state is GetPostInitial || state is GetPostLoading) {
              return Center(
                child: CircularProgressIndicator(color: HexColor("#3c1e08")),
              );
            }
            else if (state is GetPostLoaded) {

              if (_isFirstLoaded)
              {
                postList = state.postList;
                _currentPage = List<int>.filled(postList.length, 0);
                _isFirstLoaded = false;
              }

              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context)
                      .colorScheme
                      .copyWith(primary: HexColor("#3c1e08")),
                ),
                child: RefreshIndicator(
                  onRefresh: refreshPosts,
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        itemCount: postList.length,
                        itemBuilder: (context, index) {
                          final Post post = postList[index];
                          if (post.isAds == true) {
                            return displayAds(post, index);
                          } else {
                            return Card(
                              color: HexColor("#ecd9c9"),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // if (post.postImages != null &&
                                    //     post.postImages!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          if (post.isCurrentUserPost == false) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      SearchView(
                                                        userid: post.userId!,
                                                      )),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                                  Colors.transparent,
                                              backgroundImage: post
                                                          .profileImage !=
                                                      ""
                                                  ? Image.memory(base64Decode(
                                                          post.profileImage!))
                                                      .image
                                                  : AssetImage(
                                                      'assets/profileimage.png'),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      post.username!,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            post.postTypeId == 1
                                                ? Container(
                                                    color: Colors.brown,
                                                    padding: EdgeInsets.all(
                                                        4.0), // Adjust the padding as needed
                                                    child: Text(
                                                      "Daily Sharing",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  )
                                                : Container(
                                                    color: Colors.brown,
                                                    padding: EdgeInsets.all(
                                                        4.0), // Adjust the padding as needed
                                                    child: Text(
                                                      "Expert Tips",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                            post.isCurrentUserPost == false
                                                ? report(post)
                                                : Container(),
                                          ],
                                        ),
                                      ),
                                    SizedBox(height: 4.0),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                        top: 6,
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
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
                                    SizedBox(height: 4.0),
                                    displayImage(post, index),
                                    Row(
                                      children: [
                                        _FavoriteButton(
                                          postId: post.id!,
                                          actionTypeId: post.currentUserAction!,
                                          onFavoriteChanged:
                                              (bool isThumbsUpSelected) {
                                            if (post.likeCount != 0 ||
                                                isThumbsUpSelected) {
                                              setState(() {
                                                post.likeCount =
                                                    post.likeCount! +
                                                        (isThumbsUpSelected
                                                            ? 1
                                                            : -1);
                                                hasBeenLiked = true;
                                              });
                                            } else {
                                              print(
                                                  'Is Thumbs Up Selected: $isThumbsUpSelected');
                                            }
                                          },
                                        ),
                                        SizedBox(width: 4.0),
                                        IconButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Comments(postId: post.id!),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${post.likeCount.toString()} likes",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16.0,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Comments(
                                                          postId: post.id!),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: post.commentCount! > 0
                                                  ? Text(
                                                      'View all ${post.commentCount} comments',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black),
                                                    )
                                                  : SizedBox.shrink(),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Text(
                                              func.getFormattedDate(
                                                  post.dateTime!),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _floatingButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MissingCaseIcon(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget report(Post post) {
    return BlocProvider.value(
      value: reportBloc,
      child: BlocListener<ReportPostBloc, ReportPostState>(
        listener: (context, state) async {
          if (state is ReportPostSuccessState) {
            final snackBar = SnackBarDesign.customSnackBar('Report submitted successfully!');
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            // Schedule the pop operation in the next frame
            await Future.delayed(Duration.zero);
            // Check if the context is still valid before popping
            if (Navigator.of(context).canPop()) {
              setState(() {
                Navigator.of(context).pop();
              });
            }
             refreshPosts();
             reportBloc.add(StartReportPost()); 
          } else if (state is ReportPostFailState) {
            final snackBar = SnackBarDesign.customSnackBar(state.message);
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            // Schedule the pop operation in the next frame
            await Future.delayed(Duration.zero);
            // Check if the context is still valid before popping
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
        child: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Report"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: reportController,
                        decoration: InputDecoration(
                          hintText: "Enter your report...",
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color:  HexColor("#3c1e08")),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          String reportText = reportController.text;
                          reportBloc.add(
                            ReportButtonPressed(
                              postId: post.id!,
                              description: reportText,
                            ),
                          );

                          setState(() {
                            reportController.clear();
                          });

                          await Future.delayed(Duration(milliseconds: 100));
                          Navigator.of(context).pop();
                        },
                        child: Text("Report", style: TextStyle(color: HexColor("#3c1e08"))),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget displayAds(Post post, int i) {
    return Card(
      color: HexColor("#ecd9c9"),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            displayImage(post, i),
            Container(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${post.description}",
                style: TextStyle(fontSize: 16),
              ),
            )),
            SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }

  Widget displayImage(Post post, int i) {
    return Stack(
      children: [
        Container(
          height: post.postImages != null && post.postImages!.isNotEmpty
              ? MediaQuery.of(context)
                  .size
                  .width // Set height to screen width if there are images
              : 0, // Set height to 0 if postImages is null or empty
          child: post.postImages != null && post.postImages!.isNotEmpty
              ? Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: post.postImages!.length,
                        itemBuilder: (context, index) {
                          return AspectRatio(
                            aspectRatio: 1.0,
                            child: Image.memory(
                              base64Decode(post.postImages![index].image!),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage[i] = page;
                          });
                        },
                      ),
                    ),
                    post.postImages!.length > 1
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              post.postImages!.length,
                              (index) => Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage[i] == index
                                        ? HexColor(
                                            "#3c1e08") // Highlight the current page indicator
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                )
              : Container(), // Show an empty container if postImages is null or empty
        ),
        if (post.adsUrl != null)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () async {
                // Handle the click on 'Shop Now!'
                print("tekan");
                print(post.adsUrl);
                await launchUrl(Uri.parse(post.adsUrl!));
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 60, // Adjust the height as needed
                color: Colors.brown.withOpacity(0.7), // Brown background color
                padding:
                    EdgeInsets.all(16.0), // Increased padding for visibility
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Shop Now!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> retrieveSharedPreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedValue = prefs.getString(
        'token'); // Replace 'yourKey' with the key you used when saving the value

    if (savedValue != null) {
      // Use the retrieved value as needed
      print('Retrieved value: $savedValue');
    } else {
      print('Value not found in SharedPreferences');
    }
  }
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
            if (thumbsUpSelected == true) {
              _postBloc.add(UpdateActionPost(
                postId: postId,
                actionTypeId: 1,
              ));
              onFavoriteChanged(thumbsUpSelected);
            } else if (thumbsUpSelected == false) {
              _postBloc.add(DeleteActionPost(postId: postId));
              onFavoriteChanged(thumbsUpSelected);
            }
          },
          icon: Icon(
            thumbsUpSelected ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
            color: thumbsUpSelected ? HexColor("#3c1e08") : Colors.black,
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
            if (thumbsDownSelected == true) {
              _postBloc.add(UpdateActionPost(
                postId: postId,
                actionTypeId: 2,
              ));
              onFavoriteChanged(thumbsUpSelected);
            } else {
              _postBloc.add(DeleteActionPost(postId: postId));
              //onFavoriteChanged(thumbsUpSelected);
            }
          },
          icon: Icon(
            thumbsDownSelected
                ? Icons.thumb_down
                : Icons.thumb_down_alt_outlined,
            color: thumbsDownSelected ? HexColor("#3c1e08") : Colors.black,
            size: 24.0,
          ),
        ),
      ],
    );
  }
}
