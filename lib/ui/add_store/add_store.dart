import 'dart:io';

import 'package:barcode_image/barcode_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/model/DeliveryChargeModel.dart';
import 'package:nocstore/model/VendorModel.dart';
import 'package:nocstore/model/categoryModel.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/QrCodeGenerator/QrCodeGenerator.dart';
import 'package:nocstore/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:nocstore/ui/store_location/store_location.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as ImageVar;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../constants.dart';
import '../../model/SectionModel.dart';

class AddStoreScreen extends StatefulWidget {
  AddStoreScreen({Key? key}) : super(key: key);

  @override
  _AddStoreScreenState createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends State<AddStoreScreen> {
  final storeName = TextEditingController();
  final description = TextEditingController();
  final phonenumber = TextEditingController();
  final deliverChargeKm = TextEditingController();
  final minDeliveryCharge = TextEditingController();
  final minDeliveryChargewkm = TextEditingController();
  List<String>? mediaFilesURLs;
  final _formKey = GlobalKey<FormState>();
  late Future<List<SectionModel>> categoriesSection;
  List<VendorCategoryModel> categoryLst = [];
  VendorCategoryModel? selectedCategory;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  DeliveryChargeModel? deliveryChargeModel;
  var lat;
  var long;

  @override
  void dispose() {
    storeName.dispose();
    description.dispose();
    phonenumber.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    FireStoreUtils.getDelivery().then((value) {
      setState(() {
        deliveryChargeModel = value;
        if (deliveryChargeModel != null &&
            !deliveryChargeModel!.vendor_can_modify) {
          deliverChargeKm.text =
              deliveryChargeModel!.delivery_charges_per_km.toString();
          minDeliveryCharge.text =
              deliveryChargeModel!.minimum_delivery_charges.toString();
          minDeliveryChargewkm.text = deliveryChargeModel!
              .minimum_delivery_charges_within_km
              .toString();
        }
      });
    });

    categoriesSection = FireStoreUtils.getSections();

    categoriesSection.then((value) {
      sectionsVal!.clear();
      value.forEach((element) {
        if (element.serviceTypeFlag == "ecommerce-service" ||
            element.serviceTypeFlag == "delivery-service") {
          sectionsVal!.add(element);
        }
      });
      setState(() {});
    });
    getVendorData();
  }

  final ImagePicker _imagePicker = ImagePicker();
  List<dynamic> _mediaFiles = [];
  List<SectionModel>? sectionsVal = [];
  SectionModel? selectedModel;

  String selectCategoryName = "";

  VendorModel? vendorData;
  bool isLoading = true;

  getVendorData() async {
    if (MyAppState.currentUser!.vendorID != '') {
      await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)!
          .then((value) async {
        vendorData = value;

        print(vendorData!.toJson());
        VendorCategoryModel vendorCategoryModel = VendorCategoryModel(
            id: vendorData!.categoryID, title: vendorData!.categoryTitle);

        await FireStoreUtils.getVendorCategoryById(value!.section_id)
            .then((value) {
          categoryLst.clear();
          categoryLst.addAll(value);

          if (sectionsVal != null) {
            for (SectionModel sectionvalute in sectionsVal!) {
              if (vendorData!.section_id == sectionvalute.id) {
                selectedModel = sectionvalute;
              }
            }
          }
          for (int a = 0; a < value.length; a++) {
            if (value[a].id == vendorCategoryModel.id &&
                vendorData!.section_id == value[a].section_id) {
              selectedCategory = value[a];
            }
          }
          if (selectedCategory != null) {
            for (VendorCategoryModel vendorCategoryModel in categoryLst) {
              if (vendorCategoryModel.id == selectedCategory!.id) {
                selectedCategory = vendorCategoryModel;
              }
            }
          }
        });

        if (deliveryChargeModel != null &&
            deliveryChargeModel!.vendor_can_modify &&
            vendorData!.DeliveryCharge != null) {
          deliverChargeKm.text =
              vendorData!.DeliveryCharge!.delivery_charges_per_km.toString();
          minDeliveryCharge.text =
              vendorData!.DeliveryCharge!.minimum_delivery_charges.toString();
          minDeliveryChargewkm.text = vendorData!
              .DeliveryCharge!.minimum_delivery_charges_within_km
              .toString();
        }

        storeName.text = vendorData!.title;
        description.text = vendorData!.description;
        phonenumber.text = vendorData!.phonenumber;

        isLoading = false;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : null,
      body: SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Form(
                key: _formKey,
                autovalidateMode: _autoValidateMode,
                child: MyAppState.currentUser!.vendorID == ''
                    ? Column(
                        children: [
                          Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Store Name".tr(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: "Poppinsl",
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(0Xff696A75)),
                              )),
                          Container(
                            padding: const EdgeInsetsDirectional.only(
                                start: 2, end: 10, bottom: 10),
                            child: TextFormField(
                                controller: storeName,
                                textAlignVertical: TextAlignVertical.center,
                                textInputAction: TextInputAction.next,
                                validator: validateEmptyField,
                                // onSaved: (text) => line1 = text,
                                style: TextStyle(fontSize: 18.0),
                                keyboardType: TextInputType.streetAddress,
                                cursorColor: Color(COLOR_PRIMARY),
                                // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                decoration: InputDecoration(
                                  // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                  contentPadding:
                                      EdgeInsets.fromLTRB(10, 2, 10, 2),
                                  hintText: 'Store Name'.tr(),
                                  hintStyle: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Color(0Xff333333),
                                      fontSize: 17,
                                      fontFamily: "Poppinsm"),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(7.0),
                                      borderSide: BorderSide(
                                          color: Color(COLOR_PRIMARY),
                                          width: 2.0)),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).errorColor),
                                    borderRadius: BorderRadius.circular(7.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context).errorColor),
                                    borderRadius: BorderRadius.circular(7.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(7.0),
                                  ),
                                )),
                          ),
                          Container(
                              padding: EdgeInsets.only(top: 10),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Sections".tr(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: "Poppinsl",
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(0Xff696A75)),
                              )),
                          Container(
                            height: 60,
                            child: DropdownButtonFormField<SectionModel>(
                                decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(10, 2, 10, 2),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                validator: (value) => value == null
                                    ? 'field required'.tr()
                                    : null,
                                value: selectedModel,
                                onChanged: (value) {
                                  setState(() async {
                                    if (value != selectedModel) {
                                      categoryLst.clear();
                                    }
                                    selectedModel = value;
                                    selectedCategory = null;
                                    selectCategoryName = "";
                                    categoryLst = await FireStoreUtils
                                        .getVendorCategoryById(
                                            selectedModel!.id.toString());
                                    setState(() {
                                      if (categoryLst.length > 0) {
                                      } else {
                                        final snackBar = SnackBar(
                                          content: Text(
                                            'No category for this section'.tr(),
                                            style: TextStyle(
                                                color: !isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black),
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);
                                      }
                                    });
                                  });
                                },
                                hint: Text('Select Section'.tr()),
                                items: sectionsVal!.map((SectionModel item) {
                                  return DropdownMenuItem<SectionModel>(
                                    child: Text(item.name.toString() +
                                        " (${item.serviceType})"),
                                    value: item,
                                  );
                                }).toList()),
                          ),
                          Container(
                              padding: EdgeInsets.only(top: 10, bottom: 10),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Categories".tr(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: "Poppinsl",
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(0Xff696A75)),
                              )),
                          Container(
                            height: 60,
                            child: DropdownButtonFormField<VendorCategoryModel>(
                                decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(10, 2, 10, 2),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey, width: 1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                value: selectedCategory,
                                validator: (value) => value == null
                                    ? 'field required'.tr()
                                    : null,
                                disabledHint: Text("Select Category".tr()),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value;
                                    selectCategoryName =
                                        value!.title.toString();
                                  });
                                },
                                hint: Text('Select Category'.tr()),
                                items:
                                    categoryLst.map((VendorCategoryModel item) {
                                  return DropdownMenuItem<VendorCategoryModel>(
                                    child: Text(item.title.toString()),
                                    value: item,
                                  );
                                }).toList()),
                          ),
                          Container(
                              padding: EdgeInsets.only(top: 10),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Description".tr(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: "Poppinsl",
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(0Xff696A75)),
                              )),
                          Container(
                            padding: const EdgeInsetsDirectional.only(
                                end: 20, bottom: 10),
                            child: TextFormField(
                                controller: description,
                                textAlignVertical: TextAlignVertical.center,
                                textInputAction: TextInputAction.next,
                                validator: validateEmptyField,
                                // onSaved: (text) => line1 = text,
                                style: TextStyle(fontSize: 18.0),
                                keyboardType: TextInputType.streetAddress,
                                cursorColor: Color(COLOR_PRIMARY),
                                // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                decoration: InputDecoration(
                                  // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                  hintText: 'Description'.tr(),
                                  hintStyle: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Color(0Xff333333),
                                      fontSize: 17,
                                      fontFamily: "Poppinsm"),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(COLOR_PRIMARY)),
                                  ),

                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0XFFB1BCCA)),
                                    // borderRadius: BorderRadius.circular(8.0),
                                  ),
                                )),
                          ),
                          Container(
                              padding: EdgeInsets.only(top: 5),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Phone Number".tr(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: "Poppinsl",
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Color(0Xff696A75)),
                              )),
                          Container(
                            padding: const EdgeInsetsDirectional.only(
                                end: 20, bottom: 10),
                            child: TextFormField(
                                controller: phonenumber,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]')),
                                ],
                                textAlignVertical: TextAlignVertical.center,
                                textInputAction: TextInputAction.next,
                                validator: validateEmptyField,
                                // onSaved: (text) => line1 = text,
                                style: TextStyle(fontSize: 18.0),
                                keyboardType: TextInputType.number,
                                cursorColor: Color(COLOR_PRIMARY),
                                // initialValue: MyAppState.currentUser!.shippingAddress.line1,
                                decoration: InputDecoration(
                                  // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                  hintText: 'Phone Number'.tr(),
                                  hintStyle: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Color(0Xff333333),
                                      fontSize: 17,
                                      fontFamily: "Poppinsm"),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(COLOR_PRIMARY)),
                                  ),

                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0XFFB1BCCA)),
                                    // borderRadius: BorderRadius.circular(8.0),
                                  ),
                                )),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          selectedModel != null &&
                                  selectedModel!.serviceTypeFlag ==
                                      "ecommerce-service"
                              ? Container()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwitchListTile.adaptive(
                                      dense: true,
                                      activeColor: Color(COLOR_ACCENT),
                                      title: Text(
                                        'Delivery Settings'.tr(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black,
                                            fontFamily: "Poppinsm"),
                                      ),
                                      value: deliveryChargeModel != null
                                          ? deliveryChargeModel!
                                              .vendor_can_modify
                                          : false,
                                      onChanged: (value) {},
                                    ),
                                    Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Delivery Charge Per km".tr(),
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: "Poppinsl",
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Color(0Xff696A75)),
                                        )),
                                    Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 20, bottom: 10),
                                      child: TextFormField(
                                          controller: deliverChargeKm,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            print("value os $value");
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Invalid value".tr();
                                            }
                                            return null;
                                          },
                                          enabled: deliveryChargeModel != null
                                              ? deliveryChargeModel!
                                                  .vendor_can_modify
                                              : false,
                                          onSaved: (text) =>
                                              deliverChargeKm.text = text!,
                                          style: TextStyle(fontSize: 18.0),
                                          keyboardType: TextInputType.number,
                                          cursorColor: Color(COLOR_PRIMARY),
                                          // initialValue: vendor.phonenumber,
                                          decoration: InputDecoration(
                                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                            hintText:
                                                'Delivery Charge Per km'.tr(),
                                            hintStyle: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Color(0Xff333333),
                                                fontSize: 17,
                                                fontFamily: "Poppinsm"),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(COLOR_PRIMARY)),
                                            ),

                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0XFFB1BCCA)),
                                              // borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          )),
                                    ),
                                    Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Min Delivery Charge".tr(),
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: "Poppinsl",
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Color(0Xff696A75)),
                                        )),
                                    Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 20, bottom: 10),
                                      child: TextFormField(
                                          enabled: deliveryChargeModel != null
                                              ? deliveryChargeModel!
                                                  .vendor_can_modify
                                              : false,
                                          controller: minDeliveryCharge,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Invalid value".tr();
                                            }
                                            return null;
                                          },
                                          onSaved: (text) =>
                                              minDeliveryCharge.text = text!,
                                          style: TextStyle(fontSize: 18.0),
                                          keyboardType: TextInputType.number,
                                          cursorColor: Color(COLOR_PRIMARY),
                                          // initialValue: vendor.phonenumber,
                                          decoration: InputDecoration(
                                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                            hintText:
                                                'Min Delivery Charge'.tr(),
                                            hintStyle: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Color(0Xff333333),
                                                fontSize: 17,
                                                fontFamily: "Poppinsm"),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(COLOR_PRIMARY)),
                                            ),

                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0XFFB1BCCA)),
                                              // borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          )),
                                    ),
                                    Container(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Min Delivery Charge within km".tr(),
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: "Poppinsl",
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Color(0Xff696A75)),
                                        )),
                                    Container(
                                      padding: const EdgeInsetsDirectional.only(
                                          end: 20, bottom: 10),
                                      child: TextFormField(
                                          controller: minDeliveryChargewkm,
                                          enabled: deliveryChargeModel != null
                                              ? deliveryChargeModel!
                                                  .vendor_can_modify
                                              : false,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Invalid value".tr();
                                            }
                                            return null;
                                          },
                                          onSaved: (text) =>
                                              minDeliveryChargewkm.text = text!,
                                          style: TextStyle(fontSize: 18.0),
                                          keyboardType: TextInputType.number,
                                          cursorColor: Color(COLOR_PRIMARY),
                                          // initialValue: vendor.phonenumber,
                                          decoration: InputDecoration(
                                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                                            hintText:
                                                'Min Delivery Charge within km'
                                                    .tr(),
                                            hintStyle: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Color(0Xff333333),
                                                fontSize: 17,
                                                fontFamily: "Poppinsm"),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(COLOR_PRIMARY)),
                                            ),

                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Color(0XFFB1BCCA)),
                                              // borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                          SizedBox(
                            height: 10,
                          ),
                          _mediaFiles.isEmpty == true
                              ? InkWell(
                                  onTap: () {
                                    _pickImage();
                                  },
                                  child: Image(
                                    image:
                                        AssetImage("assets/images/add_img.png"),
                                    width:
                                        MediaQuery.of(context).size.width * 1,
                                    height: MediaQuery.of(context).size.height *
                                        0.2,
                                  ))
                              : _imageBuilder(_mediaFiles.first)
                        ],
                      )
                    : isLoading == true
                        ? Container(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator.adaptive(
                              valueColor:
                                  AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                            ),
                          )
                        : buildrow())),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(
                    color: Color(0xFFFEDF00),
                  ),
                ),
                backgroundColor: Color(0xFFFEDF00),
              ),
              onPressed: () {
                validate();
              },
              child: Text(
                'CONTINUE'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Visibility(
              visible: MyAppState.currentUser!.vendorID != '',
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: BorderSide(
                        color: Color(0xFFFEDF00),
                      ),
                    ),
                    backgroundColor: Color(0xFFFEDF00),
                  ),
                  onPressed: () async {
                    final image = ImageVar.Image(600, 600);
                    ImageVar.fill(image, ImageVar.getColor(255, 255, 255));
                    drawBarcode(image, Barcode.qrCode(),
                        '{"vendorid":"${MyAppState.currentUser!.vendorID}","vendorname":"${vendorData!.title}","sectionid":"${vendorData!.section_id}"}',
                        font: ImageVar.arial_24);

                    // Save the image
                    Directory appDocDir =
                        await getApplicationDocumentsDirectory();
                    String appDocPath = appDocDir.path;

                    print("path $appDocPath");
                    File file = File(
                        '$appDocPath/barcode${MyAppState.currentUser!.vendorID}.png');
                    if (!await file.exists()) {
                      await file.create();
                    } else {
                      await file.delete();
                      await file.create();
                    }
                    file.writeAsBytesSync(ImageVar.encodePng(image));
                    push(context, QrCodeGenerator(vendorModel: vendorData!));
                  },
                  child: Text(
                    'Generate QR Code'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildrow() {
    print("draw vieww");

    return Column(children: [
      Container(
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Store Name".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: "Poppinsl",
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding:
            const EdgeInsetsDirectional.only(start: 2, end: 20, bottom: 10),
        child: TextFormField(
            controller: storeName,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateEmptyField,
            onSaved: (text) => storeName.text = text!,
            style: TextStyle(fontSize: 18.0),
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            decoration: InputDecoration(
              hintText: 'Store Name'.tr(),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),
              hintStyle: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Color(0Xff696A75),
                  fontSize: 17,
                  fontFamily: "Poppinsm"),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            "Sections".tr(),
            style: TextStyle(
                fontSize: 17,
                fontFamily: "Poppinsl",
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        height: 60,
        child: DropdownButtonFormField<SectionModel>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            validator: (value) => value == null ? 'field required' : null,
            value: selectedModel,
            onChanged: (value) async {
              if (value != selectedModel) {
                categoryLst.clear();
              }
              selectedModel = value;
              selectedCategory = null;
              selectCategoryName = "";
              categoryLst = await FireStoreUtils.getVendorCategoryById(
                  selectedModel!.id.toString());
              setState(() {
                if (categoryLst.length > 0) {
                } else {
                  final snackBar = SnackBar(
                    content: Text(
                      'No category for this section'.tr(),
                      style: TextStyle(
                          color: !isDarkMode(context)
                              ? Colors.white
                              : Colors.black),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              });
              setState(() {});
            },
            hint: Text('Select Section'.tr()),
            items: sectionsVal!.map((SectionModel item) {
              return DropdownMenuItem<SectionModel>(
                child: Text(item.name.toString() + " (${item.serviceType})"),
                value: item,
              );
            }).toList()),
      ),
      Container(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            "Categories".tr(),
            style: TextStyle(
                fontSize: 17,
                fontFamily: "Poppinsl",
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        height: 60,
        child: DropdownButtonFormField<VendorCategoryModel>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(10, 2, 10, 2),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            value: selectedCategory,
            validator: (value) => value == null ? 'field required' : null,
            disabledHint: Text("Select category First".tr()),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                selectCategoryName = value!.title.toString();
              });
            },
            hint: Text('Select category'.tr()),
            items: categoryLst.map((VendorCategoryModel item) {
              return DropdownMenuItem<VendorCategoryModel>(
                child: Text(item.title.toString()),
                value: item,
              );
            }).toList()),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Description".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: "Poppinsl",
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(end: 20, bottom: 10),
        child: TextFormField(
            controller: description,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateEmptyField,
            onSaved: (text) => description.text = text!,
            style: TextStyle(fontSize: 18.0),
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            // initialValue: vendor.description,
            decoration: InputDecoration(
              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
              hintText: 'Description'.tr(),
              hintStyle: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Color(0Xff333333),
                  fontSize: 17,
                  fontFamily: "Poppinsm"),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),

              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      Container(
          padding: EdgeInsets.only(top: 10),
          width: MediaQuery.of(context).size.width,
          child: Text(
            "Phone Number".tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 17,
                fontFamily: "Poppinsl",
                color: isDarkMode(context) ? Colors.white : Color(0Xff696A75)),
          )),
      Container(
        padding: const EdgeInsetsDirectional.only(end: 20, bottom: 10),
        child: TextFormField(
            controller: phonenumber,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: TextInputAction.next,
            validator: validateMobile,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            onSaved: (text) => phonenumber.text = text!,
            style: TextStyle(fontSize: 18.0),
            keyboardType: TextInputType.streetAddress,
            cursorColor: Color(COLOR_PRIMARY),
            // initialValue: vendor.phonenumber,
            decoration: InputDecoration(
              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
              hintText: 'Phone Number'.tr(),
              hintStyle: TextStyle(
                  color: isDarkMode(context) ? Colors.white : Color(0Xff333333),
                  fontSize: 17,
                  fontFamily: "Poppinsm"),
              contentPadding: new EdgeInsets.only(left: 8, right: 8),

              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7.0),
                  borderSide:
                      BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).errorColor),
                borderRadius: BorderRadius.circular(7.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(7.0),
              ),
            )),
      ),
      SizedBox(
        height: 10,
      ),
      selectedModel != null &&
              selectedModel!.serviceTypeFlag == "ecommerce-service"
          ? Container()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  dense: true,
                  activeColor: Color(0xFFFEDF00),
                  title: Text(
                    'Delivery Settings'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkMode(context) ? Colors.white : Colors.black,
                        fontFamily: "Poppinsm"),
                  ),
                  value: deliveryChargeModel != null
                      ? deliveryChargeModel!.vendor_can_modify
                      : false,
                  onChanged: (value) {},
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Delivery Charge Per km".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: "Poppinsl",
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding:
                      const EdgeInsetsDirectional.only(end: 20, bottom: 10),
                  child: TextFormField(
                      controller: deliverChargeKm,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        print("value os $value");
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      onSaved: (text) => deliverChargeKm.text = text!,
                      style: TextStyle(fontSize: 18.0),
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                        // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        hintText: 'Delivery Charge Per km'.tr(),
                        hintStyle: TextStyle(
                            color: isDarkMode(context)
                                ? Colors.white
                                : Color(0Xff333333),
                            fontSize: 17,
                            fontFamily: "Poppinsm"),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                        ),

                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                          // borderRadius: BorderRadius.circular(8.0),
                        ),
                      )),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Min Delivery Charge".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: "Poppinsl",
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding:
                      const EdgeInsetsDirectional.only(end: 20, bottom: 10),
                  child: TextFormField(
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      controller: minDeliveryCharge,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      onSaved: (text) => minDeliveryCharge.text = text!,
                      style: TextStyle(fontSize: 18.0),
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                        // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        hintText: 'Min Delivery Charge'.tr(),
                        hintStyle: TextStyle(
                            color: isDarkMode(context)
                                ? Colors.white
                                : Color(0Xff333333),
                            fontSize: 17,
                            fontFamily: "Poppinsm"),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                        ),

                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                          // borderRadius: BorderRadius.circular(8.0),
                        ),
                      )),
                ),
                Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Min Delivery Charge within km".tr(),
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: "Poppinsl",
                          color: isDarkMode(context)
                              ? Colors.white
                              : Color(0Xff696A75)),
                    )),
                Container(
                  padding:
                      const EdgeInsetsDirectional.only(end: 20, bottom: 10),
                  child: TextFormField(
                      controller: minDeliveryChargewkm,
                      enabled: deliveryChargeModel != null
                          ? deliveryChargeModel!.vendor_can_modify
                          : false,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Invalid value".tr();
                        }
                        return null;
                      },
                      onSaved: (text) => minDeliveryChargewkm.text = text!,
                      style: TextStyle(fontSize: 18.0),
                      keyboardType: TextInputType.number,
                      cursorColor: Color(COLOR_PRIMARY),
                      // initialValue: vendor.phonenumber,
                      decoration: InputDecoration(
                        // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        hintText: 'Min Delivery Charge within km'.tr(),
                        hintStyle: TextStyle(
                            color: isDarkMode(context)
                                ? Colors.white
                                : Color(0Xff333333),
                            fontSize: 17,
                            fontFamily: "Poppinsm"),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                        ),

                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                          // borderRadius: BorderRadius.circular(8.0),
                        ),
                      )),
                ),
              ],
            ),
      SizedBox(
        height: 10,
      ),
      _mediaFiles.isEmpty == true
          ? InkWell(
              onTap: () {
                changeimg();
              },
              child: Image(
                image: NetworkImage(vendorData!.photo),
                width: 150,
              ))
          : _imageBuilder(_mediaFiles.first)
    ]);
    // return selectedModel == null
    //     ? Container()
    //     : FutureBuilder<List<VendorCategoryModel>>(
    //         future: FireStoreUtils.getVendorCategoryById(selectedModel!.sectionId),
    //         builder: (context, AsyncSnapshot<List<VendorCategoryModel>> value) {
    //           if (value.connectionState != ConnectionState.done) {
    //             return Container();
    //           }
    //           categoryLst.clear();
    //           categoryLst.addAll(value.data!);
    //           if (!isReselect) {
    //             print("cat cahnge");
    //             for (int a = 0; a < value.data!.length; a++) {
    //               if (value.data![a].id == vendorCategoryModel.id && selectedModel!.sectionId == value.data![a].section_id) {
    //                 selectedCategory = value.data![a];
    //               }
    //             }
    //           }
    //
    //           isReselect = false;
    //           if (selectedCategory != null) {
    //             for (VendorCategoryModel vendorCategoryModel in categoryLst) {
    //               if (vendorCategoryModel.id == selectedCategory!.id) {
    //                 selectedCategory = vendorCategoryModel;
    //               }
    //             }
    //           }
    //
    //
    //         });
  }

  changeimg() {
    final action = CupertinoActionSheet(
      message: Text(
        'Change Picture'.tr(),
        style: TextStyle(fontSize: 15.0),
      ),
      actions: [
        CupertinoActionSheetAction(
          child: Text('Choose image from gallery'.tr()),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              // _mediaFiles.removeLast();
              setState(() {
                _mediaFiles.add(File(image.path));
              });

              // _mediaFiles.add(null);
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture'.tr()),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              // _mediaFiles.removeLast();
              _mediaFiles.add(File(image.path));
              // _mediaFiles.add(null);
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Store Field".tr()),
      content: Text("Please Select Image to Continue.".tr()),
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

  validate() async {
    if (MyAppState.currentUser!.vendorID != '') {
      if (_formKey.currentState?.validate() ?? false) {
        // catselect();
        // filter();
        if (_mediaFiles.isNotEmpty) {
          await showProgress(context, 'Updating Photo...'.tr(), false);

          var uniqueID = Uuid().v4();
          Reference upload = FirebaseStorage.instance.ref().child(STORAGE_ROOT +
              '/store/productImages/$uniqueID'
                  '.png');
          UploadTask uploadTask = upload.putFile(_mediaFiles.first);
          uploadTask.whenComplete(() {}).catchError((onError) {
            print((onError as PlatformException).message);
          });
          var storageRef = (await uploadTask.whenComplete(() {})).ref;
          String downloadUrl = await storageRef.getDownloadURL();
          downloadUrl.toString();
          await hideProgress();

          if (selectedModel!.serviceTypeFlag != "ecommerce-service") {
            deliveryChargeModel!.vendor_can_modify = true;
            deliveryChargeModel!.delivery_charges_per_km =
                num.parse(deliverChargeKm.text);
            deliveryChargeModel!.minimum_delivery_charges =
                num.parse(minDeliveryCharge.text);
            deliveryChargeModel!.minimum_delivery_charges_within_km =
                num.parse(minDeliveryChargewkm.text);
          }

          push(
              context,
              StoreLocationScreen(
                  restname: storeName.text,
                  catid: selectedCategory!.id,
                  filter: selectedModel!.id,
                  cat: selectedCategory!.title,
                  desc: description.text,
                  phonenumber: phonenumber.text,
                  pic: downloadUrl,
                  sectionModel: selectedModel!,
                  vendor: vendorData,
                  deliveryChargeModel: deliveryChargeModel));
        } else {
          if (selectedModel!.serviceTypeFlag != "ecommerce-service") {
            deliveryChargeModel!.vendor_can_modify = true;
            deliveryChargeModel!.delivery_charges_per_km =
                num.parse(deliverChargeKm.text);
            deliveryChargeModel!.minimum_delivery_charges =
                num.parse(minDeliveryCharge.text);
            deliveryChargeModel!.minimum_delivery_charges_within_km =
                num.parse(minDeliveryChargewkm.text);
          }
          push(
            context,
            StoreLocationScreen(
                restname: storeName.text,
                catid: selectedCategory!.id,
                filter: selectedModel!.id,
                cat: selectedCategory!.title,
                desc: description.text,
                phonenumber: phonenumber.text,
                pic: vendorData!.photo,
                sectionModel: selectedModel!,
                vendor: vendorData,
                deliveryChargeModel: deliveryChargeModel),
          );
        }
      }
    } else if (_formKey.currentState?.validate() ?? false) {
      if (_mediaFiles.isEmpty) {
        showimgAlertDialog(context, 'Please add Image'.tr(),
            'Add Image to continue'.tr(), true);
      } else if (phonenumber.text.isEmpty) {
        showimgAlertDialog(context, 'Please enter valid number'.tr(),
            'Add phone no. to continue'.tr(), true);
      } else {
        _formKey.currentState!.save();

        if (selectedModel!.serviceTypeFlag != "ecommerce-service") {
          deliveryChargeModel!.vendor_can_modify = true;
          deliveryChargeModel!.delivery_charges_per_km =
              num.parse(deliverChargeKm.text);
          deliveryChargeModel!.minimum_delivery_charges =
              num.parse(minDeliveryCharge.text);
          deliveryChargeModel!.minimum_delivery_charges_within_km =
              num.parse(minDeliveryChargewkm.text);
        }

        push(
          context,
          StoreLocationScreen(
            restname: storeName.text,
            catid: selectedCategory!.id,
            filter: selectedModel!.id,
            cat: selectedCategory!.title.toString(),
            desc: description.text,
            phonenumber: phonenumber.text,
            pic: _mediaFiles.first,
            vendor: vendorData,
            sectionModel: selectedModel!,
            deliveryChargeModel: deliveryChargeModel,
          ),
        );
      }
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  _pickImage() {
    final action = CupertinoActionSheet(
      message: Text(
        'Add Picture'.tr(),
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text('Choose image from gallery'.tr()),
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              // _mediaFiles.removeLast();
              _mediaFiles.add(File(image.path));
              // _mediaFiles.add(null);
              setState(() {});
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text('Take a picture'.tr()),
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              // _mediaFiles.removeLast();
              _mediaFiles.add(File(image.path));
              // _mediaFiles.add(null);
              setState(() {});
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _imageBuilder(dynamic image) {
    // bool isLastItem = image == null;
    return GestureDetector(
      onTap: () {
        _viewOrDeleteImage(image);
      },
      child: Container(
        width: 100,
        child: Card(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDarkMode(context) ? Colors.black : Colors.white,
          child: ClipRRect(
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
            // _mediaFiles.removeLast();
            if (image is File) {
              _mediaFiles.removeWhere(
                  (value) => value is File && value.path == image.path);
            } else {
              _mediaFiles
                  .removeWhere((value) => value is String && value == image);
            }
            // _mediaFiles.add(null);
            setState(() {});
          },
          child: Text('Remove picture'.tr()),
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
          child: Text('View picture'.tr()),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  bool isPhoneNoValid(String? phoneNo) {
    if (phoneNo == null) return false;
    final regExp = RegExp(r'(^(?:[+0]9)?[0-9]{10,12}$)');
    return regExp.hasMatch(phoneNo);
  }

  showimgAlertDialog(
      BuildContext context, String title, String content, bool addOkButton) {
    Widget? okButton;
    if (addOkButton) {
      okButton = TextButton(
        child: Text('OK'.tr()),
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }

    if (Platform.isIOS) {
      CupertinoAlertDialog alert = CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [if (okButton != null) okButton],
      );
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return alert;
          });
    } else {
      AlertDialog alert = AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [if (okButton != null) okButton]);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }

  showAlertDialog1(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr()),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("My title".tr()),
      content: Text("This is my message.".tr()),
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
