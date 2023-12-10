import 'package:CatViP/bloc/user/userprofile_bloc.dart';
import 'package:CatViP/bloc/user/userprofile_event.dart';
import 'package:CatViP/bloc/user/userprofile_state.dart';
import 'package:CatViP/model/user/user_model.dart';
import 'package:CatViP/pageRoutes/bottom_navigation_bar.dart';
import 'package:CatViP/pages/search/searchuser_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  late UserProfileBloc userBloc;
  TextEditingController nameController = TextEditingController();
  late List<UserModel> searchList;
  @override
  void initState() {
    userBloc = BlocProvider.of<UserProfileBloc>(context);

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor("#ecd9c9"),
        bottomOpacity: 0.0,
        elevation: 0.0,
        automaticallyImplyLeading: false,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            margin: EdgeInsets.only(top: 15),
            color: HexColor("#D0D4CA"),
            child: Row(
              children: [
                nameField(),
                IconButton(onPressed: (){
                  if (nameController.text.length > 0){
                    userBloc.add(SearchUserPressed(name: nameController.text.trim()));
                  }
                }, icon: Icon(Icons.search)),
              ],
            ),
          ),
        ),
      ),
      body: Container(
      //   list view
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state){
            if (state is SearchFailState){
              return Container(
                margin: const EdgeInsets.all(18.0),
                padding: const EdgeInsets.all(5.0),
                child: Text(state.message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17),
                ),
              );
            } else if (state is SearchSuccessState){
              print('inside success state');
              searchList = state.searchList;
              return resultList();
            } else if (state is UserProfileLoadingState){
              return Center(child: CircularProgressIndicator(color: HexColor("#3c1e08")));
            }
            return Container();
          }
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),

    );
  }

  Widget nameField(){
    return Container(
      margin: EdgeInsets.only(left: 10),
      width: 270,
      child: TextFormField(
        controller: nameController,
        decoration: InputDecoration(
          hintText: "Search",
          focusColor: HexColor("#3c1e08"),
        ),
      ),
    );
  }

  Widget resultList(){
    print("in list function");
    print("list: ${searchList.length}");
    return 
      Padding(
      padding: const EdgeInsets.all(15),
      child: Expanded(
        child: ListView.builder(
          itemCount: searchList.length,
          itemBuilder: (context,index){
            var user = searchList[index];
            return InkWell(
              onTap: (){
                int userid = user.id ?? 0;
                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchView(userid: userid)));
              },
              child: Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(user.username),
                  subtitle: Text(user.fullname),
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}