import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/model/VendorModel.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class AccountDetailsScreen extends StatefulWidget {
 // final User user;
  final VendorModel vendor;

  AccountDetailsScreen({Key? key, /*required this.user,*/ required this.vendor})
      : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState();
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
   VendorModel? vendor;
  GlobalKey<FormState> _key = new GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  List<dynamic> _mediaFiles = [];
  final ImagePicker _imagePicker = ImagePicker();
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  @override
  void initState() {
    super.initState();
      vendor = widget.vendor;
      if (vendor!.photos.isNotEmpty == true) {
        _mediaFiles.addAll(widget.vendor.photos);
      }

    FireStoreUtils.getCurrentUser(MyAppState.currentUser!.userID).then((value){
      setState(() {
        _mediaFiles.addAll(value!.photos);
        firstName.text = MyAppState.currentUser!.firstName;
        lastName.text = MyAppState.currentUser!.lastName;
        email.text = MyAppState.currentUser!.email;
        mobile.text = MyAppState.currentUser!.phoneNumber;
      });
    }).whenComplete((){
      _mediaFiles.add(null);
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Account Details'.tr(),
            style: TextStyle(
              color:
                  isDarkMode(context) ? Color(0xFFFFFFFF) : Color(0Xff333333),
            ),
          ),
          automaticallyImplyLeading: false,
          leading: GestureDetector(
              onTap: (){
                Navigator.pop(context,true);
              },
              child: Icon(Icons.arrow_back,color: Colors.black,)),
        ),
        body:Form(
          key: _key,
          autovalidateMode: _validate,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16, bottom: 8, top: 24),
                  child: Text(
                    'PUBLIC INFO'.tr(),
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey),
                  ).tr(),
                ),
                Material(
                    elevation: 2,
                    color: isDarkMode(context)
                        ? Colors.black12
                        : Colors.white,
                    child: ListView(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: ListTile.divideTiles(
                            context: context,
                            tiles: [
                              ListTile(
                                title: Text(
                                  'First Name'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ).tr(),
                                trailing: ConstrainedBox(
                                  constraints:
                                  BoxConstraints(maxWidth: 100),
                                  child: TextFormField(
                                    controller: firstName,
                                    validator: validateName,
                                    textInputAction:
                                    TextInputAction.next,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black),
                                    cursorColor: Color(COLOR_ACCENT),
                                    textCapitalization:
                                    TextCapitalization.words,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'First Name'.tr(),
                                        contentPadding:
                                        EdgeInsets.symmetric(
                                            vertical: 5)),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Last Name'.tr(),
                                  style: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black),
                                ).tr(),
                                trailing: ConstrainedBox(
                                  constraints:
                                  BoxConstraints(maxWidth: 100),
                                  child: TextFormField(
                                    controller: lastName,
                                    validator: validateName,
                                    textInputAction:
                                    TextInputAction.next,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black),
                                    cursorColor: Color(COLOR_ACCENT),
                                    textCapitalization:
                                    TextCapitalization.words,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Last Name'.tr(),
                                        contentPadding:
                                        EdgeInsets.symmetric(
                                            vertical: 5)),
                                  ),
                                ),
                              ),
                            ]).toList())),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16, bottom: 8, top: 24),
                  child: Text(
                    'PRIVATE DETAILS'.tr(),
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey),
                  ).tr(),
                ),
                Material(
                  elevation: 2,
                  color: isDarkMode(context)
                      ? Colors.black12
                      : Colors.white,
                  child: ListView(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: ListTile.divideTiles(
                        context: context,
                        tiles: [
                          ListTile(
                            title: Text(
                              'Email Address'.tr(),
                              style: TextStyle(
                                  color: isDarkMode(context)
                                      ? Colors.white
                                      : Colors.black),
                            ).tr(),
                            trailing: ConstrainedBox(
                              constraints:
                              BoxConstraints(maxWidth: 200),
                              child: TextFormField(
                                controller: email,
                                validator: validateEmail,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.end,
                                enabled: false,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                                cursorColor: Color(COLOR_ACCENT),
                                keyboardType:
                                TextInputType.emailAddress,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Email Address'.tr(),
                                    contentPadding:
                                    EdgeInsets.symmetric(
                                        vertical: 5)),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'phoneNumber'.tr(),
                              style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
                            ).tr(),
                            trailing: InkWell(
                              onTap: () {
                                showAlertDialog(context);
                              },
                              child: Text(MyAppState.currentUser!.phoneNumber),
                            ),
                          ),
                        ],
                      ).toList()),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16, bottom: 8, top: 24),
                  child: Text(
                    'ADD STORE PHOTOS'.tr(),
                    style:
                    TextStyle(fontSize: 16, color: Colors.grey),
                  ).tr(),
                ),
                ConstrainedBox(
                    constraints: const BoxConstraints(
                        minWidth: double.infinity),
                    child: Material(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, top: 8, right: 8, bottom: 20),
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              itemCount: _mediaFiles.length,
                              itemBuilder: (context, index) =>
                                  _imageBuilder(_mediaFiles[index]),
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                            ),
                          ),
                        ))),
                Padding(
                    padding:
                    const EdgeInsets.only(top: 32.0, bottom: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          minWidth: double.infinity),
                      child: Material(
                        elevation: 2,
                        color: isDarkMode(context)
                            ? Colors.black12
                            : Colors.white,
                        child: CupertinoButton(
                          color: Color(0xFFFEDF00),
                          padding: const EdgeInsets.all(12.0),
                          onPressed: () async {
                            _validateAndSave(context);
                          },
                          child: Text(
                            'Save'.tr(),
                            style: TextStyle(
                                fontSize: 18,
                                color:Colors.black),
                          ).tr(),
                        ),
                      ),
                    )),
              ]),
        ));
  }

  Widget _imageBuilder(dynamic image) {
    bool isLastItem = image == null;
    return GestureDetector(
      onTap: () {
        isLastItem ? _pickImage() : _viewOrDeleteImage(image);
      },
      child: Container(
        width: 100,
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          color: isLastItem
              ? Color(0xFFFEDF00)
              : isDarkMode(context)
                  ? Colors.black
                  : Colors.white,
          child: isLastItem
              ? Icon(
                  CupertinoIcons.camera,
                  size: 40,
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image is File
                      ? Image.file(
                          image,
                          fit: BoxFit.cover,
                        )
                      : displayImage(image),
                ),
        ),
      ),
    );
  }

  _viewOrDeleteImage(dynamic image) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () async {
            Navigator.pop(context);
            _mediaFiles.removeLast();
            if (image is File) {
              _mediaFiles.removeWhere(
                  (value) => value is File && value.path == image.path);
            } else {
              _mediaFiles
                  .removeWhere((value) => value is String && value == image);
            }
            _mediaFiles.add(null);
            setState(() {});
          },
          child: Text('Remove picture').tr(),
          isDestructiveAction: true,
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            push(
                context,
                image is File
                    ? FullScreenImageViewer(imageFile: image)
                    : FullScreenImageViewer(imageUrl: image));
          },
          isDefaultAction: true,
          child: Text('View picture').tr(),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel').tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _pickImage() {
    final action = CupertinoActionSheet(
      message: Text(
        'Add Picture'.tr(),
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('Choose image from gallery').tr(),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              _mediaFiles.removeLast();
              _mediaFiles.add(File(image.path));
              _mediaFiles.add(null);
              setState(() {});
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture').tr(),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              _mediaFiles.removeLast();
              _mediaFiles.add(File(image.path));
              _mediaFiles.add(null);
              setState(() {});
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel').tr(),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _validateAndSave(BuildContext buildContext) async {
    if (_key.currentState?.validate() ?? false) {
      _key.currentState?.save();
      await showProgress(context, 'Saving details...'.tr(), false);
      await _updateUser(buildContext);
    } else {
      setState(() {
        _validate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  _updateUser(BuildContext buildContext) async {
    MyAppState.currentUser!.firstName = firstName.text;
    MyAppState.currentUser!.lastName = lastName.text;
    MyAppState.currentUser!.email = email.text;
    MyAppState.currentUser!.phoneNumber = mobile.text;
    var updatedUser = await FireStoreUtils.updateCurrentUser(MyAppState.currentUser!);

    if(MyAppState.currentUser!.vendorID.isNotEmpty){
      List<String> mediaFilesURLs = _mediaFiles
          .where((element) => element is String)
          .toList()
          .cast<String>();
      List<File> imagesToUpload =
      _mediaFiles.where((element) => element is File).toList().cast<File>();
      if (imagesToUpload.isNotEmpty) {
        updateProgress(
          'Uploading Store Images {} of {}'
              .tr(args: ['1', '${imagesToUpload.length}']),
        );
        for (int i = 0; i < imagesToUpload.length; i++) {
          if (i != 0)
            updateProgress(
              'Uploading Store Images {} of {}'.tr(
                args: ['${i + 1}', '${imagesToUpload.length}'],
              ),
            );
          String url = await fireStoreUtils.uploadProductImage(
            imagesToUpload[i],
            'Uploading Store Images {} of {}'.tr(
              args: ['${i + 1}', '${imagesToUpload.length}'],
            ),
          );
          mediaFilesURLs.add(url);
        }
      }
      vendor!.photos = mediaFilesURLs;
      var updatedVendor = await FireStoreUtils.updateVendor(vendor!);
    }

    if (updatedUser != null ) {
      hideProgress();
      ScaffoldMessenger.of(buildContext).showSnackBar(SnackBar(
          content: Text(
        'Details saved successfully',
        style: TextStyle(fontSize: 17),
      ).tr()));
    } else {
      hideProgress();
      ScaffoldMessenger.of(buildContext).showSnackBar(SnackBar(
          content: Text(
            "Couldn't save details, Please try again.",
        style: TextStyle(fontSize: 17),
      ).tr()));
    }
  }


  bool _isPhoneValid = false;
  String? _phoneNumber = "";

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel").tr(),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("continue").tr(),
      onPressed: () {
        if(_isPhoneValid){
          setState(() {
            MyAppState.currentUser!.phoneNumber = _phoneNumber.toString();
            mobile.text = _phoneNumber.toString();
          });
          Navigator.pop(context);
        }
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Change Phone Number").tr(),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), shape: BoxShape.rectangle, border: Border.all(color: Colors.grey.shade200)),
        child: InternationalPhoneNumberInput(
          onInputChanged: (value) {
            _phoneNumber = "${value.phoneNumber}";
          },
          onInputValidated: (bool value) => _isPhoneValid = value,
          ignoreBlank: true,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          inputDecoration: InputDecoration(
            hintText: 'Phone Number'.tr(),
            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            isDense: true,
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
          ),
          inputBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          initialValue: PhoneNumber(isoCode: 'MY'),
          selectorConfig: const SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG),
        ),
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

}
