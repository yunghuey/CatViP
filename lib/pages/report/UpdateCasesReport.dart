import 'dart:convert';
import 'dart:io';
import 'package:CatViP/bloc/report%20case/EditCaseReport/editCaseReport_bloc.dart';
import 'package:CatViP/model/caseReport/caseReport.dart';
import 'package:CatViP/model/caseReport/caseReportImages.dart';
import 'package:CatViP/pages/SnackBarDesign.dart';
import 'package:CatViP/pages/report/CaseReportComment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/post/EditPost/editPost_bloc.dart';
import '../../bloc/post/EditPost/editPost_state.dart';
import '../../bloc/report case/EditCaseReport/editCaseReport_event.dart';
import '../../bloc/report case/RevokeCaseReport/revokeCase_bloc.dart';
import '../../bloc/report case/RevokeCaseReport/revokeCase_event.dart';
import '../post/own_post.dart';
import 'getOwnReport.dart';

class UpdateCasesReport extends StatefulWidget {
  final CaseReport caseReport;
  const UpdateCasesReport({super.key, required this.caseReport});

  @override
  State<UpdateCasesReport> createState() => _UpdateCasesReportState();
}

class _UpdateCasesReportState extends State<UpdateCasesReport> {
  late final CaseReport caseReport;
  File? image;
  List<String> base64image = [];
  int id = 0;
  String username = '';
  String profileImage = '';
  String description = '';
  List<CaseReportImage> images = [];
  final _picker = ImagePicker();
  late CompleteCaseBloc completeCaseBloc;
  late RevokeCaseBloc revokeCaseBloc;
  int _currentPage = 0;

  //
  // Future<Uint8List?> _getImageBytes(File imageFile) async {
  //   try {
  //     List<int> imageBytes = await imageFile.readAsBytes();
  //     return Uint8List.fromList(imageBytes);
  //   } catch (e) {
  //     print("Error reading image as bytes: $e");
  //     return null;
  //   }
  // }

  @override
  void initState() {
    caseReport = widget.caseReport;
    images = caseReport.caseReportImages!;
    id = caseReport.id!;
    description = caseReport.description!;
    completeCaseBloc = BlocProvider.of<CompleteCaseBloc>(context);
    revokeCaseBloc = BlocProvider.of<RevokeCaseBloc>(context);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EditPostBloc, EditPostState>(
      listener: (context, state) {
        if (state is EditPostSuccessState) {
          Navigator.pop(context);
        } else if (state is EditPostFailState) {
          print('Failed to save post');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Update Case Report",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          backgroundColor: HexColor("#ecd9c9"),
        ),
        body: SingleChildScrollView(
          child: Form(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  caseReportImage(),
                  const SizedBox(height: 4.0),
                  descriptionText(),
                  const SizedBox(height: 16.0),
                  Buttons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget caseReportImage() {
    return Container(
        // Set height to 0 if postImages is null or empty
        child: Column(
      children: [
        Container(
          height: images.isNotEmpty
              ? MediaQuery.of(context)
                  .size
                  .width // Set height to screen width if there are images
              : 0,
          child: caseReport.caseReportImages != null &&
                  caseReport.caseReportImages!.isNotEmpty
              ? PageView.builder(
                  itemCount: caseReport.caseReportImages!.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.memory(
                        base64Decode(
                            caseReport.caseReportImages![index].images!),
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                )
              : Container(),
        ),
        caseReport.caseReportImages!.length > 1
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  caseReport.caseReportImages!.length,
                  (index) => Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
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
        // Show an empty container if postImages is null or empty
        );
  }

  Widget descriptionText() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CaseReportCommentView(caseReportId: id!),
                ),
              ),
              icon: const Icon(
                Icons.comment_bank_outlined,
                color: Colors.black,
                size: 24.0,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description:',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              width: 4.0,
            ),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget Buttons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () async {
              completeCaseBloc.add(CompleteButtonPressed(postId: id));
              await Future.delayed(const Duration(milliseconds: 500));
              Navigator.pop(context);
              final snackBar = SnackBarDesign.customSnackBar('Report completed');
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            style: TextButton.styleFrom(
              backgroundColor: HexColor("#3c1e08"),
              padding: const EdgeInsets.all(16),
            ),
            child: const Text(
              'Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 4.0), // This will create a small space between the buttons
        Expanded(
          child: TextButton(
            onPressed: () {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Revoke Post'),
                  content: const Text('Are you sure to revoke this report?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: Text('Cancel',
                          style: TextStyle(color: HexColor('#3c1e08'))),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<HexColor>(
                                (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return HexColor("#ecd9c9");
                          return HexColor("#F2EFEA");
                        }),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(10.0)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0))),
                      ),
                    ),
                    TextButton(
                      child: const Text('Yes', style: TextStyle(color: Colors.white)),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<HexColor>(
                            HexColor("#3c1e08")),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.all(10.0)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0))),
                      ),
                      onPressed: () async {
                        revokeCaseBloc.add(RevokeCaseButtonPressed(postId: id));
                        await Future.delayed(const Duration(milliseconds: 500));
                        Navigator.pop(context);
                        Navigator.pop(context);
                        final snackBar = SnackBarDesign.customSnackBar('Report revoked');
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                    ),
                  ],
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(HexColor("#ecd9c9")),
              padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
              side: MaterialStateProperty.all(
                  BorderSide(color: HexColor("#3c1e08"))), // Add border color
            ),
            child: Text(
              'Revoke',
              style: TextStyle(color: HexColor("#3c1e08")),
            ),
          ),
        ),
      ],
    );
  }
}
