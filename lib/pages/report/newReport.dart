import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Add this import
import 'package:CatViP/bloc/post/OwnCats/ownCats_bloc.dart';
import 'package:CatViP/bloc/post/OwnCats/ownCats_event.dart';
import 'package:CatViP/bloc/post/OwnCats/ownCats_state.dart';
import 'package:CatViP/bloc/post/new_post/new_post_bloc.dart';
import 'package:CatViP/bloc/report%20case/new%20report%20case/newCase_bloc.dart';
import 'package:CatViP/bloc/report%20case/new%20report%20case/newCase_event.dart';
import 'package:CatViP/pages/SnackBarDesign.dart';
import 'package:CatViP/pages/report/current_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bloc/post/new_post/new_post_state.dart';
import '../../bloc/report case/new report case/newCase_state.dart';
import '../../model/cat/cat_model.dart';

class NewReport extends StatefulWidget {
  const NewReport({Key? key}) : super(key: key);

  @override
  State<NewReport> createState() => _NewReportState();
}

class _NewReportState extends State<NewReport> {
  //Controllers for input
  TextEditingController captionController = TextEditingController();
  TextEditingController postTypeController = TextEditingController();
  TextEditingController catIdController = TextEditingController();

  List<CatModel> cats = [];
  late NewPostBloc createBloc;
  late OwnCatsBloc catBloc;
  late NewCaseBloc caseBloc;
  int? selectedCatId;
  File? image;
  bool showSpinner = false;
  late final String message;
  final TextEditingController addressController = TextEditingController();
  //String address = 'Get your location';
  double longitude = 0.0;
  double latitude = 0.0;
  List<XFile> selectedImages = [];
  List<String> base64Images = [];
  bool canAddImage = true;

  Future<void> pickImages(ImageSource source, {int maxImages = 5}) async {
    Navigator.pop(context);
    if (selectedImages.length >= maxImages) {
      final snackBar = SnackBarDesign.customSnackBar('Maximum $maxImages images allowed.');
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    try {
      List<XFile>? images;

      if (source == ImageSource.camera) {
        // If the source is the camera, use pickImage to capture a single image
        XFile? image = await ImagePicker().pickImage(
          imageQuality: 70,
          maxWidth: 800,
          source: source,
        );

        if (image != null) {
          String? base64String = await _getImageBase64(File(image.path));

          if (base64String != null) {
            base64Images.add(base64String);
          }

          setState(() {
            if (selectedImages.length < maxImages) {
              selectedImages = List.from(selectedImages)..addAll([image]);
            } else {
              // Display a snackbar or alert message when the limit is exceeded
              final snackBar = SnackBarDesign.customSnackBar('Maximum $maxImages images allowed.');
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          });
        }
      } else {
        // If the source is not the camera, use pickMultiImage
        images = await ImagePicker().pickMultiImage(
          imageQuality: 70,
          maxWidth: 800,
        );

        if (images != null && images.isNotEmpty) {
          List<XFile> newImages = [];

          for (XFile image in images) {
            String? base64String = await _getImageBase64(File(image.path));

            if (base64String != null) {
              base64Images.add(base64String);
            }

            newImages.add(image);
          }

          setState(() {
            if (selectedImages.length + newImages.length <= maxImages) {
              selectedImages = List.from(selectedImages)..addAll(newImages);
            } else {
              // Display a snackbar or alert message when the limit is exceeded
              final snackBar = SnackBarDesign.customSnackBar('Maximum $maxImages images allowed.');
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          });
        }
      }

      // Now base64Images list contains all base64-encoded strings of the selected images
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  Future<String> getMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String message = prefs.getString('message') ?? '';

    return message;
  }

  Future<String?> _getImageBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(Uint8List.fromList(imageBytes));
      print(base64Encode(Uint8List.fromList(imageBytes)));
      //return base64String;
      return base64Encode(Uint8List.fromList(imageBytes));
    } catch (e) {
      print("Error reading image as bytes: $e");
      return null;
    }
  }

  late var msg = Container();
  late final status = BlocBuilder<NewPostBloc, NewPostState>(
    builder: (context, state) {
      if (state is NewPostLoadingState) {
        return Center(
            child: CircularProgressIndicator(
              color: HexColor("#3c1e08"),
            ));
      }
      return Container();
    },
  );

  @override
  void initState() {
    super.initState();
    caseBloc = BlocProvider.of<NewCaseBloc>(context);
    catBloc = BlocProvider.of<OwnCatsBloc>(context);
  }

  late final formstatus = BlocBuilder<NewCaseBloc, NewCaseState>(
    builder: (context, state){
      if (state is NewCaseLoadingState){
        return Center(child: CircularProgressIndicator(color:  HexColor("#3c1e08"),));
      }
      return Container();
    },
  );
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NewCaseBloc, NewCaseState>(
          listener: (context, state) {
            if (state is NewCaseSuccessState) {
              final snackBar = SnackBarDesign.customSnackBar('Successfully Report');
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              Navigator.pop(context, true);
            } else if (state is NewCaseFailState) {
              getMessage().then((message) {
                final snackBar = SnackBarDesign.customSnackBar(message);
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              });
            }
          },
        ),
      ],
      child: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Report Case",
                style: Theme.of(context).textTheme.bodyLarge),
            backgroundColor: HexColor("#ecd9c9"),
            bottomOpacity: 0.0,
            elevation: 0.0,
            automaticallyImplyLeading: true,
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: Column(
                      children: <Widget>[
                        insertImage(context),
                        SizedBox(height: 8.0,),
                        caption(),
                        SizedBox(height: 8.0,),
                        OwnCats(),
                        SizedBox(height: 8.0,),
                        getLocationTextField(),
                        SizedBox(height: 8.0,),
                        formstatus,
                        reportButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomSheet(BuildContext context) {
    return Container(
      height: 100.0,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: <Widget>[
          Text(
            "Choose Image",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
          SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton.icon(
                icon: Icon(Icons.camera, color: HexColor("#3c1e08")),
                onPressed: () {
                  pickImages(ImageSource.camera);
                },
                label: Text(
                  "Camera",
                  style: TextStyle(color: HexColor("#3c1e08")),
                ),
              ),
              SizedBox(
                width: 20.0,
              ),
              TextButton.icon(
                icon: Icon(Icons.image, color: HexColor("#3c1e08")),
                onPressed: () {
                  pickImages(ImageSource.gallery);
                },
                label: Text(
                  "Gallery",
                  style: TextStyle(color: HexColor("#3c1e08")),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget insertImage(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: ((builder) => bottomSheet(context)),
              );
            },
            child: Container(
              width: 300, // Set your desired width for the square box
              height: 300, // Set your desired height for the square box
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.brown,
                  width: 2.0,
                ),
              ),
              child: ImageView(),
            ),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: ((builder) => bottomSheet(context)),
                );
              },
              child: canAddImage == true
                  ? const Icon(Icons.add,color: Colors.brown, size: 28.0,)
                  : Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget ImageView() {
    if (selectedImages.isEmpty) {
      return Center(
        child: Text("Pick an Image"),
      );
    } else {
      return PageView.builder(
        itemCount: selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 300,
                height: 300,
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: FutureBuilder<String?>(
                    future: _getImageBase64(File(selectedImages[index].path)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Image.memory(
                          base64Decode(snapshot.data!),
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        );
                      } else {
                        return Center(
                          child: Text('Loading Image'),
                        );
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImages.removeAt(index);
                      base64Images.removeAt(index);

                      if (selectedImages.length < 5){
                        canAddImage = true;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(Icons.delete,color: Colors.white,),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget reportButton() {
    return Padding(
      padding: const EdgeInsets.all(17.0),
      child: SizedBox(
        width: 400.0,
        height: 55.0,
        child: ElevatedButton(
          onPressed: () async {
            print(captionController.text);
            //if(_formKey.currentState!.validate()){
            if (base64Images.isNotEmpty) {
              if (captionController.text.isEmpty ||
                  addressController.text.isEmpty) {
                final snackBar = SnackBarDesign.customSnackBar('Description and address must be filled up');
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return;
              }
              caseBloc.add(CaseReportButtonPressed(
                  description: captionController.text,
                  address: addressController.text,
                  longitude: longitude,
                  latitude: latitude,
                  image: base64Images,
                  catId: selectedCatId ?? 0));
            } else {
              print("image is null");
              caseBloc.add(CaseReportButtonPressed(
                  description: captionController.text,
                  address: addressController.text,
                  longitude: longitude,
                  latitude: latitude,
                  image: base64Images,
                  catId: selectedCatId ?? 0));
            }
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                )),
            backgroundColor:
            MaterialStateProperty.all<HexColor>(HexColor("#3c1e08")),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'REPORT',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget caption() {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: TextFormField(
        controller: captionController,
        decoration: InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(color: HexColor("#3c1e08")),
          focusColor: HexColor("#3c1e08"),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: HexColor("#a4a4a4")),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: HexColor("#3c1e08")),
          ),
          prefixIcon: Icon(
            Icons.description, // Change the icon as needed
            color: HexColor("#3c1e08"),
          ),
        ),
      ),
    );
  }

  Widget getLocationTextField() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.location_on), // You can change the icon as needed
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => CurrentLocation()))
                .then((value) => {
                  if(value != null)
                  {
                    latitude = value['latitude'],
                    longitude = value['longitude'],
                    addressController.text = value['address'],
                  }
            });
            print('Location icon pressed');
          },
        ),
        Expanded(
          child: TextField(
            readOnly: true,
            controller: addressController,
            decoration: InputDecoration(
              labelText: "Location",
              hintText: "Click on icon to pick location",
              labelStyle: TextStyle(color: HexColor("#3c1e08")),
              focusColor: HexColor("#3c1e08"),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: HexColor("#a4a4a4")),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: HexColor("#3c1e08")),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget OwnCats() {
    catBloc.add(GetOwnCats());

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: BlocBuilder<OwnCatsBloc, OwnCatsState>(
        builder: (context, state) {
          if (state is GetOwnCatsLoading) {
            // You can perform side-effects here if needed
          } else if (state is GetOwnCatsError) {
            // You can perform side-effects here if needed
            final snackBar = SnackBarDesign.customSnackBar('Error: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } else if (state is GetOwnCatsLoaded) {
            // Use the fetched data to populate the drop-down menu
            cats = state.cats;
            print("success");
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'My cat:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Radio<int>(
                      value: 1,
                      groupValue: selectedCatId == null ? 0 : 1,
                      activeColor: HexColor('#3c1e08'),
                      onChanged: (value) {
                        setState(() {
                          selectedCatId = value == 1
                              ? (cats.isNotEmpty ? cats.first.id : null)
                              : null;

                          if (selectedCatId == null) {
                            Future.delayed(Duration.zero, () {
                              final snackBar = SnackBarDesign.customSnackBar('No cats available');
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            });
                          }
                        });
                      },
                    ),
                    Text('Yes'),
                    Radio<int>(
                      value: 0,
                      activeColor: HexColor('#3c1e08'),
                      groupValue: selectedCatId == null ? 0 : 1,
                      onChanged: (value) {
                        setState(() {
                          selectedCatId = value == 0 ? null : cats.first.id;
                        });
                      },
                    ),
                    Text('No'),
                  ],
                ),
                if (selectedCatId == 1 && cats.isNotEmpty)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Cat',
                      labelStyle: TextStyle(color: HexColor("#3c1e08")),
                      focusColor: HexColor("#3c1e08"),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: HexColor("#a4a4a4")),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: HexColor("#3c1e08")),
                      ),
                      prefixIcon: Icon(
                        Icons.pets,
                        color: HexColor("#3c1e08"),
                      ),
                    ),
                    child: DropdownButtonFormField<int>(
                      value: selectedCatId,
                      onChanged: (value) {
                        setState(() {
                          selectedCatId = value;
                        });
                      },
                      items: cats.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name! ?? "no data"),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          } else {
            return Container(); // Return an empty container or any fallback widget
          }
          return Container(); // Return an empty container or any fallback widget
        },
      ),
    );
  }
}
