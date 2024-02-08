//GOOGLE_API_KEY

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/model/SectionModel.dart';
import 'package:nocstore/model/VendorModel.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/container/ContainerScreen.dart';
import 'package:nocstore/ui/ordersScreen/OrdersScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:place_picker/entities/entities.dart';
import 'package:place_picker/place_picker.dart';
import 'package:uuid/uuid.dart';

import '../../constants.dart';

class StoreLocationScreen extends StatefulWidget {
  final desc, phonenumber, filter, catid, restname, pic, deliveryChargeModel, cat;
  SectionModel sectionModel;
  VendorModel? vendor;

  StoreLocationScreen({Key? key, this.desc, this.phonenumber, this.catid, this.pic, this.filter, this.restname, this.vendor, required this.sectionModel, this.cat, this.deliveryChargeModel})
      : super(key: key);

  @override
  _StoreLocationScreenState createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  var downloadUrl;
  final _formKey = GlobalKey<FormState>();
  var latValue = 0.0, longValue = 0.0;
  var query = "";

  ////current location

  VendorModel? vendor;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  var mapName = TextEditingController();
  var mapName1 = TextEditingController();
  var mapAddress = TextEditingController();
  var mapAddress1 = TextEditingController();
  var city = TextEditingController();
  var city1 = TextEditingController();
  var state = TextEditingController();
  var state1 = TextEditingController();
  final country = TextEditingController();
  final country1 = TextEditingController();

  var auth, authname, authpic;
  var add;

  @override
  void initState() {
    super.initState();
    auth = MyAppState.currentUser!.userID;
    authname = MyAppState.currentUser!.firstName;
    authpic = MyAppState.currentUser!.photos.isEmpty ? ' ' : MyAppState.currentUser!.photos.first;
    print(widget.filter);
    // vendor = widget.vendor;
    //////////////////////////////////////////////
    // if (mapName.text.isEmpty) {
    // mapName.text = add[0];
    // }
    // if (mapAddress.text.isEmpty) {
    //   mapAddress.text = add[1];
    // }
    // if (city.text.isEmpty) {
    //   city.text = add[2];
    // }
    // if (state.text.isEmpty) {
    //   state.text = add[3];
    // }
    // if (country.text.isEmpty) {
    //   country.text = add[4];
    // }
    // _getUserLocation();

    print(widget.cat.toString() + " +++++  " + widget.catid.toString() + " ");
  }

  @override
  void dispose() {
    mapName.dispose();
    mapAddress.dispose();
    city.dispose();
    state.dispose();
    country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.vendor != null ? add = widget.vendor!.location.split(',') : null;

    // if (vendor != null) {
    //   if (mapName.text.isEmpty) {
    // mapName.text = add[0];
    //   }
    //   if (mapAddress.text.isEmpty) {
    //     mapAddress.text = add[1];
    //   }
    //   if (city.text.isEmpty) {
    //     city.text = add[2];
    //   }
    //   if (state.text.isEmpty) {
    //     state.text = add[3];
    //   }
    //   if (country.text.isEmpty) {
    //     country.text = add[4];
    //   }
    // }
    // mapName.text.isEmpty ? mapName.text = vendor!.location[0] : mapName.text ='kk';
    if (widget.vendor != null) {
      mapName.text = add[0] == null ? "" : add[0];
      if (add.length > 0) {
        mapAddress.text = add[1] == null ? "" : add[1];
        if (add.length > 1) {
          city.text = add[2] == null ? "" : add[2];
          if (add.length > 2) {
            state.text = add[3] == null ? "" : add[3];
            if (add.length > 3) {
              country.text = add[4] == null ? "" : add[4];
            }
          }
        }
      }
    }
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text('Store Location').tr(),
        centerTitle: false,
        iconTheme: IconThemeData(color: isDarkMode(context) ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              autovalidateMode: _autoValidateMode,
              child: Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Column(children: [
                    Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Address".tr(),
                          style: TextStyle(fontSize: 15, fontFamily: "Poppinsl", color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
                        )),
                    Container(
                      padding: const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
                      child: TextFormField(
                          controller: mapName1.text.isEmpty ? mapName : mapName1,
                          // widget.vendor == null ? mapName : null,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,

                          // onChanged: (text)=>  text=mapName.text ,
                          onSaved: (text) => mapName.text = text!,
                          style: TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue: widget.vendor == null
                          //     ? null
                          // : widget.vendor!.location.split(',')[0],
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            hintText: 'Address'.tr(),
                            hintStyle: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0Xff333333), fontSize: 17, fontFamily: "Poppinsm"),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                            ),

                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFCCD6E2)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          )),
                    ),
                    Container(
                        padding: EdgeInsets.only(top: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Apartment,suite,etc.".tr(),
                          style: TextStyle(fontSize: 15, fontFamily: "Poppinsl", color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
                        )),
                    Container(
                        padding: const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
                        child: TextFormField(
                            controller: mapAddress1.text.isEmpty ? mapAddress : mapAddress1,
                            // vendor == null ? mapAddress : null,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            // validator: validateEmptyField,
                            onSaved: (text) => mapAddress.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            validator: validateEmptyField,
                            // initialValue: widget.vendor == null ? null : add[1],
                            // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              hintText: 'Apartment,suite,etc.'.tr(),
                              hintStyle: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0Xff333333), fontSize: 17, fontFamily: "Poppinsm"),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFCCD6E2)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ))),
                    Container(
                        padding: EdgeInsets.only(top: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "City".tr(),
                          style: TextStyle(fontSize: 15, fontFamily: "Poppinsl", color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
                        )),
                    Container(
                        padding: const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
                        child: TextFormField(
                            controller: city1.text.isEmpty ? city : city1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            // validator: validateEmptyField,
                            onSaved: (text) => city.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            validator: validateEmptyField,
                            // initialValue: widget.vendor == null ? null : add[2],
                            // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              hintText: 'City'.tr(),
                              hintStyle: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0Xff333333), fontSize: 17, fontFamily: "Poppinsm"),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFCCD6E2)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ))),
                    Container(
                        padding: EdgeInsets.only(top: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "State".tr(),
                          style: TextStyle(fontSize: 15, fontFamily: "Poppinsl", color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
                        )),
                    Container(
                        padding: const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
                        child: TextFormField(
                            controller: state1.text.isEmpty ? state : state1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            // validator: validateEmptyField,
                            onSaved: (text) => state.text = text!,
                            // initialValue: vendor == null ? null : add[3],
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            validator: validateEmptyField,
                            // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              hintText: 'State'.tr(),
                              hintStyle: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0Xff333333), fontSize: 17, fontFamily: "Poppinsm"),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFCCD6E2)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ))),
                    Container(
                        padding: EdgeInsets.only(top: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Country".tr(),
                          style: TextStyle(fontSize: 15, fontFamily: "Poppinsl", color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
                        )),
                    Container(
                        padding: const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
                        child: TextFormField(
                            controller: country1.text.isEmpty ? country : country1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            // initialValue: vendor == null ? null : add[4],
                            validator: validateEmptyField,
                            onSaved: (text) => country.text = text!,
                            style: TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              hintText: 'Country'.tr(),
                              hintStyle: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0Xff333333), fontSize: 17, fontFamily: "Poppinsm"),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),

                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFCCD6E2)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ))),
                    Card(
                      child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageIcon(
                                AssetImage('assets/images/current_location1.png'),
                                size: 23,
                                color: Color(COLOR_PRIMARY),
                              ),
                              // Icon(
                              //   Icons.location_searching_rounded,
                              //   color: Color(COLOR_PRIMARY),
                              // ),
                            ],
                          ),
                          title: Text(
                            "Current Location".tr(),
                            style: TextStyle(color: Color(COLOR_PRIMARY)),
                          ),
                          subtitle: Text(
                            "Using GPS".tr(),
                            style: TextStyle(color: Color(COLOR_PRIMARY)),
                          ),
                          onTap: () async {
                            LocationResult? result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlacePicker(GOOGLE_API_KEY)));
                            if (result != null) {
                              latValue = result.latLng!.latitude;
                              longValue = result.latLng!.longitude;

                              mapName1.text = result.name.toString();
                              mapAddress1.text = result.subLocalityLevel1!.name == null ? result.subLocalityLevel2!.name.toString() : result.subLocalityLevel1!.name.toString();
                              city1.text = result.city!.name.toString();
                              state1.text = '${result.administrativeAreaLevel1!.name.toString()}';
                              country1.text = '${result.country!.name.toString()}';
                              setState(() {});
                            }

                            // mapName.clear();
                            // push(
                            //   context,
                            //   SafeArea(
                            //     child: Scaffold(
                            //       body: Stack(
                            //         children: [
                            //           MapPicker(
                            //             // pass icon widget
                            //             iconWidget: Image.asset(
                            //               "assets/images/select_pin3.png",
                            //               height: 40,
                            //             ),
                            //             //add map picker controller
                            //             mapPickerController: mapPickerController,
                            //             child: GoogleMap(
                            //               myLocationEnabled: true,
                            //               zoomControlsEnabled: true,
                            //               // hide location button
                            //               myLocationButtonEnabled: true,
                            //
                            //               mapType: MapType.normal,
                            //               //  camera position
                            //               initialCameraPosition: cameraPosition,
                            //               // CameraPosition(
                            //               //   target: _initialPosition!,
                            //               //   zoom: 14.4746,
                            //               // ),
                            //               onMapCreated:
                            //                   (GoogleMapController controller) {
                            //                 _controller.complete(controller);
                            //               },
                            //               onCameraMoveStarted: () {
                            //                 // notify map is moving
                            //                 mapPickerController.mapMoving!();
                            //                 mapName1.text = 'Checking...'.tr();
                            //                 mapAddress1.text = 'Checking...'.tr();
                            //               },
                            //               onCameraMove: (cameraPosition1) {
                            //                 // _onCameraMove(cameraPosition);
                            //                 this.cameraPosition = cameraPosition1;
                            //
                            //                 latValue = cameraPosition1.target.latitude;
                            //                 longValue = cameraPosition1.target.longitude;
                            //
                            //               print(latValue.toString());
                            //               print(longValue.toString());
                            //             },
                            //             onCameraIdle: () async {
                            //                 List<Placemark> placemarks = await placemarkFromCoordinates(
                            //                   cameraPosition.target.latitude,
                            //                   cameraPosition.target.longitude,
                            //                 );
                            //
                            //                 // update the ui with the address
                            //                 mapName1.text = '${placemarks.first.street}';
                            //                 mapAddress1.text = '${placemarks.first.subLocality}';
                            //                 city1.text = '${placemarks.first.locality}';
                            //                 state1.text = '${placemarks.first.administrativeArea}';
                            //                 country1.text = '${placemarks.first.country}';
                            //                 // List<Placemark> newPlace =
                            //                 //     await placemarkFromCoordinates(
                            //                 //         52.2165157, 6.9437819);
                            //                 // print(newPlace);
                            //                 // Placemark placeMark = newPlace[0];
                            //                 // print(placeMark.name.toString());
                            //               },
                            //           ),
                            //         ),
                            //         Align(
                            //           alignment: Alignment.bottomCenter,
                            //
                            //             // shape: BorderRadius.only(
                            //             //     topLeft: Radius.circular(15),
                            //             //     topRight: Radius.circular(15)),
                            //
                            //             //state == SearchingState.Searching
                            //             //     ? Center(
                            //             //         child: CircularProgressIndicator())
                            //             child: Card(
                            //               shape: RoundedRectangleBorder(
                            //                 borderRadius: BorderRadius.only(
                            //                     topLeft: Radius.circular(10),
                            //                     topRight: Radius.circular(10)),
                            //               ),
                            //               child: Container(
                            //                 decoration: BoxDecoration(
                            //                   color: Colors.white,
                            //                   borderRadius: BorderRadius.only(
                            //                     topRight: Radius.circular(10.0),
                            //                     topLeft: Radius.circular(10.0),
                            //                   ),
                            //                 ),
                            //                 height: 250,
                            //                 padding: const EdgeInsets.only(
                            //                     left: 20,
                            //                     right: 20,
                            //                     top: 10,
                            //                     bottom: 10),
                            //                 child: Column(
                            //                   crossAxisAlignment:
                            //                       CrossAxisAlignment.start,
                            //                   // mainAxisAlignment: MainAxisAlignment.center,
                            //                   children: [
                            //                     ListTile(
                            //                         // contentPadding:
                            //                         //     EdgeInsets.only(bottom: 5),
                            //                         title: Text(
                            //                       "Select location".tr(),
                            //                       style: TextStyle(
                            //                           fontFamily: 'Poppinsr',
                            //                           color: Color(0xFF333333)),
                            //                     )),
                            //                     ListTile(
                            //                       leading: ImageIcon(
                            //                         AssetImage(
                            //                             "assets/images/select_location.png"),
                            //                         size: 20,
                            //                         color: Color(COLOR_PRIMARY),
                            //                       ),
                            //                       minLeadingWidth: 1,
                            //                       title: TextField(
                            //                         maxLines: 1,
                            //                         textAlign: TextAlign.left,
                            //                         readOnly: true,
                            //                         style: TextStyle(
                            //                             fontFamily: 'Poppinsm',
                            //                             color: Color(0xFF333333)),
                            //                         decoration:
                            //                             const InputDecoration(
                            //                                 contentPadding:
                            //                                     EdgeInsets.zero,
                            //                                 border:
                            //                                     InputBorder.none),
                            //                         controller: mapName1,
                            //                       ),
                            //                     ),
                            //                     ListTile(
                            //                       title: TextField(
                            //                         maxLines: 2,
                            //                         textAlign: TextAlign.left,
                            //                         readOnly: true,
                            //                         style: TextStyle(
                            //                             fontFamily: 'Poppinsr',
                            //                             color: Color(0xFF333333)),
                            //                         decoration:
                            //                             const InputDecoration(
                            //                                 contentPadding:
                            //                                     EdgeInsets.zero,
                            //                                 border:
                            //                                     InputBorder.none),
                            //                         controller: mapAddress1,
                            //                       ),
                            //                     ),
                            //
                            //                     SizedBox(
                            //                       height: 50,
                            //                       width: MediaQuery.of(context)
                            //                           .size
                            //                           .width,
                            //                       child: ElevatedButton(
                            //                         style:
                            //                             ElevatedButton.styleFrom(
                            //                           // padding: EdgeInsets.symmetric(
                            //                           //     vertical: 15),
                            //                           shape: RoundedRectangleBorder(
                            //                             borderRadius: BorderRadius.circular(10.0),
                            //                             side: BorderSide(
                            //                               color: Color(COLOR_PRIMARY),
                            //                             ),
                            //                           ),
                            //                           backgroundColor: Color(COLOR_PRIMARY),
                            //                         ),
                            //                         child: Text(
                            //                           "CONFIRM LOCATION".tr(),
                            //                           style: TextStyle(
                            //                               fontSize: 17,
                            //                               color: Colors.white,
                            //                               fontFamily: 'Poppinsm'),
                            //                         ),
                            //                         onPressed: () {
                            //                           print(mapAddress1.text.toString()+"====LOCATION");
                            //                           Navigator.pop(context);
                            //                           setState(() {});
                            //                         },
                            //                       ),
                            //                     ),
                            //                     // ),
                            //                   ],
                            //                 ),
                            //               ),
                            //             ),
                            //           )
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // );
                          }),
                    ),
                  ])))),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: Color(COLOR_PRIMARY),
              ),
            ),
            backgroundColor: Color(COLOR_PRIMARY),
          ),
          onPressed: () => {
            MyAppState.currentUser!.vendorID == ''
                ? latValue == 0.0 && longValue == 0.0
                    ? showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            content: Text('Please select current address using GPS location. Move pin to exact location'.tr()),
                            actions: [
                              // FlatButton(
                              //   onPressed: () => Navigator.pop(
                              //       context, false), // passing false
                              //   child: Text('No'),
                              // ),
                              TextButton(
                                onPressed: () {
                                  hideProgress();
                                  Navigator.pop(context, true);
                                }, // passing true
                                child: Text('OK'.tr()),
                              ),
                            ],
                          );
                        })
                    : addStore()
                : (widget.vendor!.latitude == 0.0 && widget.vendor!.longitude == 0.0 && latValue == 0.0 && longValue == 0.0)
                    ? showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            content: Text('Please select current address using GPS location. Move pin to exact location'.tr()),
                            actions: [
                              // FlatButton(
                              //   onPressed: () => Navigator.pop(
                              //       context, false), // passing false
                              //   child: Text('No'),
                              // ),
                              TextButton(
                                onPressed: () {
                                  hideProgress();
                                  Navigator.pop(context, true);
                                }, // passing true
                                child: Text('OK'.tr()),
                              ),
                            ],
                          );
                        })
                    : updateStore(add)
          },
          child: Text(
            MyAppState.currentUser!.vendorID == '' ? 'DONE'.tr() : 'UPDATE'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode(context) ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  addStore() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      try {
        await showProgress(context, 'Adding Store...'.tr(), false);

        var uniqueID = Uuid().v4();
        Reference upload = FirebaseStorage.instance.ref().child(STORAGE_ROOT +
            '/store/productImages/$uniqueID'
                '.png');
        UploadTask uploadTask = upload.putFile(widget.pic);
        uploadTask.whenComplete(() {}).catchError((onError) {
          print((onError as PlatformException).message);
        });
        var storageRef = (await uploadTask.whenComplete(() {})).ref;
        var downloadUrl = await storageRef.getDownloadURL();
        downloadUrl.toString();
        GeoFirePoint myLocation = GeoFlutterFire().point(latitude: latValue, longitude: longValue);
        VendorModel vendors = VendorModel(
            author: auth,
            authorName: authname,
            authorProfilePic: authpic,
            categoryID: widget.catid,
            categoryTitle: widget.cat,
            section_id: widget.filter,
            createdAt: Timestamp.now(),
            geoFireData: GeoFireData(geohash: myLocation.hash, geoPoint: GeoPoint(latValue, longValue)),
            description: widget.desc,
            phonenumber: widget.phonenumber,
            reststatus: true,
            latitude: latValue,
            longitude: longValue,
            location: mapName.text + "," + mapAddress.text + "," + city.text + "," + state.text + "," + country.text,
            photo: downloadUrl,
            dine_in_active: widget.sectionModel.dineInActive!,
            DeliveryCharge: widget.deliveryChargeModel,
            fcmToken: MyAppState.currentUser!.fcmToken,
            title: widget.restname);
        await FireStoreUtils.firebaseCreateNewVendor(vendors);
        await FireStoreUtils.updateUserCate(MyAppState.currentUser!.userID, widget.filter);

        print('sending...');
        await hideProgress();
        showAlertDialogNew(this.context);
        return vendors;
      } catch (e) {
        showAlertDialog(context, 'Error'.tr(), "${e.toString()}", true);
      }
      // Navigator.popr(context, MaterialPageRoute(builder: (context)=> OrdersScreen());
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  updateStore(add) async {
    print(mapName.text);
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      await showProgress(context, 'Updating Store...'.tr(), false);
      query = mapName.text + "," + mapAddress.text + "," + city.text + "," + state.text + "," + country.text;
      print(query.toString() + "===LAAA");
      if ((latValue == 0.0 && longValue == 0.0) && (widget.vendor!.latitude == 0.0 && widget.vendor!.longitude == 0.0)) {
        hideProgress();
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) {
              return AlertDialog(
                content: Text('Please select current address using GPS location. Move pin to exact location'.tr()),
                actions: [
                  // FlatButton(
                  //   onPressed: () => Navigator.pop(
                  //       context, false), // passing false
                  //   child: Text('No'),
                  // ),
                  TextButton(
                    onPressed: () {
                      hideProgress();
                      Navigator.pop(context, true);
                    }, // passing true
                    child: Text('OK'.tr()),
                  ),
                ],
              );
            });
        return;
      }
      if (latValue != 0) {
        widget.vendor!.latitude = latValue;
      }
      if (longValue != 0) {
        widget.vendor!.longitude = longValue;
      }

      VendorModel vendors = VendorModel(
        id: MyAppState.currentUser!.vendorID,
        author: auth,
        authorName: authname,
        authorProfilePic: authpic,
        categoryID: widget.catid,
        section_id: widget.filter,
        categoryTitle: widget.cat,
        createdAt: Timestamp.now(),
        geoFireData: GeoFireData(
            geohash: GeoFlutterFire().point(latitude: widget.vendor!.latitude, longitude: widget.vendor!.longitude).hash, geoPoint: GeoPoint(widget.vendor!.latitude, widget.vendor!.longitude)),
        description: widget.desc,
        phonenumber: widget.phonenumber,
        dine_in_active: widget.sectionModel.dineInActive!,
        location: mapName.text + "," + mapAddress.text + "," + city.text + "," + state.text + "," + country.text,
        latitude: widget.vendor!.latitude,
        longitude: widget.vendor!.longitude,
        photo: downloadUrl ?? widget.pic,
        restaurantCost: widget.vendor!.restaurantCost,
        openDineTime: widget.vendor!.openDineTime,
        closeDineTime: widget.vendor!.closeDineTime,
        restaurantMenuPhotos: widget.vendor!.restaurantMenuPhotos,
        enabledDiveInFuture: widget.vendor!.enabledDiveInFuture,
        DeliveryCharge: widget.deliveryChargeModel,
        title: widget.restname,
        reviewsCount: widget.vendor!.reviewsCount,
        reviewsSum: widget.vendor!.reviewsSum,
        fcmToken: MyAppState.currentUser!.fcmToken,
        workingHours: widget.vendor != null ? widget.vendor!.workingHours : [],
        specialDiscount: widget.vendor != null ? widget.vendor!.specialDiscount : [],
        specialDiscountEnable: widget.vendor != null ? widget.vendor!.specialDiscountEnable : false,
      );
      print(latValue.toString() + "===LAT");
      print(longValue.toString() + "===LONG");
      await FireStoreUtils.updateVendor(vendors);
      await FireStoreUtils.updateUserCate(MyAppState.currentUser!.userID, widget.filter);

      print('sending...');
      await hideProgress();
      showUpdateDialog(this.context);
      return vendors;
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  showAlertDialogNew(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        pushAndRemoveUntil(
            context,
            ContainerScreen(
              user: MyAppState.currentUser!,
              currentWidget: OrdersScreen(),
              appBarTitle: 'Orders'.tr(),
              drawerSelection: DrawerSelection.Orders,
            ),
            false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Adding Store".tr()),
      content: Text("Data is saved to database.".tr()),
      actions: [
        okButton,
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

  showUpdateDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        pushAndRemoveUntil(
            context,
            ContainerScreen(
              user: MyAppState.currentUser!,
              currentWidget: OrdersScreen(),
              appBarTitle: 'Orders'.tr(),
              drawerSelection: DrawerSelection.Orders,
            ),
            false);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Updating Store...".tr()),
      content: Text("Data is updated in database.".tr()),
      actions: [
        okButton,
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
