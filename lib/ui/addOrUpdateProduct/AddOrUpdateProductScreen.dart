import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/model/AttributesModel.dart';
import 'package:nocstore/model/BrandsModel.dart';
import 'package:nocstore/model/ItemAttributes.dart';
import 'package:nocstore/model/ProductModel.dart';
import 'package:nocstore/model/SectionModel.dart';
import 'package:nocstore/model/categoryModel.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:uuid/uuid.dart';

import '../manageProductsScreen/ManageProductsScreen.dart';

class AddOrUpdateProductScreen extends StatefulWidget {
  ProductModel? product;

  AddOrUpdateProductScreen({Key? key, this.product}) : super(key: key);

  @override
  _AddOrUpdateProductScreenState createState() =>
      _AddOrUpdateProductScreenState();
}

class _AddOrUpdateProductScreenState extends State<AddOrUpdateProductScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  GlobalKey<FormState> _key = GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  String? title, desc = "";
  List<dynamic> _mediaFiles = [];
  late bool publish;
  var catid, section_id;
  SectionModel? sectionModel;
  var _cal = 0;
  var _grm = 0;
  var _fats = 0;
  var _pro = 0;
  bool veg = false;
  bool nonVeg = false;
  bool takeaway = false;
  List<VendorCategoryModel>? categorys;
  late Future<List<VendorCategoryModel>> category;
  var categoryName;
  var img;
  List<VendorCategoryModel> categoryLst = [];
  VendorCategoryModel? selectedCategory;
  TextEditingController rprice = new TextEditingController();
  TextEditingController disprice = TextEditingController();
  TextEditingController quantityController = TextEditingController(text: "-1");
  TextEditingController _attributesValueController = TextEditingController();
  var lstAddOnsTitle = [], lstAddOnPrice = [], listAddPrice = [];

  Set<String> listAddTitle = {};

  //listAddPrice = {};

  bool isDiscountedPriceOk = false;

  late Map<String, dynamic>? adminCommission;
  String? adminCommissionValue = "";

  Map<String, dynamic> specification = {};

  List<SpecificationModel> specificationList = [];
  ItemAttributes? itemAttributes = ItemAttributes(attributes: [], variants: []);

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    quantityController.text = int.parse("-1").toString();
    getAttributes();
    fireStoreUtils.getAdminCommission().then((value) {
      if (value != null) {
        setState(() {
          adminCommission = value;
          adminCommissionValue = adminCommission!["adminCommission"].toString();
        });
      }
    });

    if (widget.product != null) {
      print(widget.product!.id);
      _mediaFiles.addAll(widget.product!.photos);

      publish = widget.product!.publish;
      catid = widget.product!.categoryID;
      rprice.text = widget.product!.price.toString();
      disprice.text = widget.product!.disPrice.toString();
      quantityController.text = widget.product!.quantity.toString();
      listAddPrice.clear();
      listAddTitle.clear();
      lstAddOnsTitle.addAll(widget.product!.addOnsTitle);
      lstAddOnPrice.addAll(widget.product!.addOnsPrice);
      takeaway = widget.product!.takeaway;
      isDiscountedPriceOk = false;

      itemAttributes = widget.product!.itemAttributes;
      specification = widget.product!.specification;
      _cal = widget.product!.calories;
      _grm = widget.product!.grams;
      _fats = widget.product!.fats;
      _pro = widget.product!.proteins;
      veg = widget.product!.veg;
      nonVeg = widget.product!.nonveg;

      specification.forEach((key, value) {
        specificationList.add(SpecificationModel(lable: key, value: value));
      });

      if (widget.product!.isDigitalProduct == true) {
        digitalProductFileName =
            getFileName(widget.product!.digitalProduct.toString());
        selectedDigital =
            widget.product!.isDigitalProduct == true ? "Yes" : "No";
      }
    }
    _mediaFiles.add(null);
    super.initState();
  }

  List<AttributesModel> attributesList = [];
  List<AttributesModel> selectedAttributesList = [];

  List<BrandsModel> brandModelList = [];
  List<String> digitalProduct = ["Yes", "No"];
  String? selectedDigital = "No";
  String? digitalProductFileName = "No";
  BrandsModel? selectedBrandModel;

  bool isLoading = true;

  File? digitalFile;

  getAttributes() async {
    await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)
        ?.then((value) {
      section_id = value!.section_id;
      category = FireStoreUtils.getVendorCategoryById(section_id);
      category.then((value) {
        categoryLst.addAll(value);
        if (widget.product != null) {
          for (int a = 0; a < categoryLst.length; a++) {
            if (widget.product!.categoryID == categoryLst[a].id) {
              selectedCategory = categoryLst[a];
              catid = categoryLst[a].id;
            }
          }
        }
        setState(() {});
      });
    });

    await FireStoreUtils.getSections().then((value) {
      for (SectionModel sectionModel in value) {
        if (sectionModel.id == section_id) {
          setState(() {
            this.sectionModel = sectionModel;
          });
        }
      }
    });

    await FireStoreUtils.getAttributes().then((value) {
      setState(() {
        attributesList = value;
      });
    });

    await FireStoreUtils.getBrands().then((value) {
      setState(() {
        brandModelList = value;
      });
    });

    if (widget.product != null) {
      brandModelList.forEach((element) {
        if (widget.product!.brandID == element.id) {
          setState(() {
            selectedBrandModel = element;
          });
        }
      });

      if (widget.product!.itemAttributes != null) {
        widget.product!.itemAttributes!.attributes!.forEach((element) {
          AttributesModel attributesModel = attributesList
              .firstWhere((product) => product.id == element.attributesId);
          print("------->" + attributesModel.toJson().toString());
          setState(() {
            selectedAttributesList.add(attributesModel);
          });
        });
      }
    }

    setState(() {
      isLoading = false;
    });
    print("------->" + selectedAttributesList.toString());
  }

  final myKey1 = GlobalKey<DropdownSearchState<AttributesModel>>();
  late Widget _currentWidget;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {
            Navigator.of(context).pop();
          }, icon: Icon(Icons.arrow_back,color: isDarkMode(context) ? Colors.white : Colors.black)),
          title: Text(
        widget.product == null ? 'Add Product'.tr() : 'Edit Product'.tr(),
        style: TextStyle(
          color: isDarkMode(context) ? Color(0xFFFFFFFF) : Color(0Xff333333),
        ),
      )),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _key,
                autovalidateMode: _validate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Admin Commission:'.tr(),
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    amountShow(amount: adminCommissionValue!),
                                    style: TextStyle(
                                        color: isDarkMode(context) ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                'Title'.tr(),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            TextFormField(
                              initialValue: widget.product?.name ?? '',
                              textAlign: TextAlign.start,
                              textInputAction: TextInputAction.next,
                              onSaved: (val) => title = val,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(fontSize: 18.0),
                              cursorColor: Color(COLOR_PRIMARY),
                              validator: validateEmptyField,
                              decoration: InputDecoration(
                                contentPadding:
                                    new EdgeInsets.only(left: 8, right: 8),
                                hintText: 'Name of the product'.tr(),
                                border: InputBorder.none,
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
                              ),
                            ),
                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                'Description'.tr(),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            TextFormField(
                              initialValue: widget.product?.description ?? '',
                              textAlign: TextAlign.start,
                              textInputAction: TextInputAction.next,
                              onSaved: (val) => desc = val,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(fontSize: 18.0),
                              cursorColor: Color(COLOR_PRIMARY),
                              validator: validateEmptyField,
                              decoration: InputDecoration(
                                contentPadding:
                                    new EdgeInsets.only(left: 8, right: 8),
                                hintText:
                                    'Short description of the product'.tr(),
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
                              ),
                            ),

                            Visibility(
                              visible: sectionModel != null &&
                                  sectionModel!.serviceTypeFlag ==
                                      "ecommerce-service",
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 16),
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Text(
                                      'Select Brand'.tr(),
                                      style: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  DropdownButtonFormField<BrandsModel>(
                                      decoration: InputDecoration(
                                        contentPadding: new EdgeInsets.only(
                                            left: 8, right: 8),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        focusedErrorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                            borderSide: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                                width: 2.0)),
                                        // filled: true,
                                        //fillColor: Colors.blueAccent,
                                      ),
                                      //dropdownColor: Colors.blueAccent,
                                      value: selectedBrandModel,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedBrandModel = value;
                                        });
                                      },
                                      hint: Text('Select brand'.tr()),
                                      items: brandModelList
                                          .map((BrandsModel item) {
                                        return DropdownMenuItem<BrandsModel>(
                                          child: Text(item.title.toString()),
                                          value: item,
                                        );
                                      }).toList()),
                                ],
                              ),
                            ),

                            sectionModel!.serviceTypeFlag == "ecommerce-service"
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          'This is digital product'.tr(),
                                          style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            contentPadding: new EdgeInsets.only(
                                                left: 8, right: 8),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_PRIMARY),
                                                    width: 2.0)),
                                            errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_PRIMARY),
                                                    width: 2.0)),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                    borderSide: BorderSide(
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                        width: 2.0)),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_PRIMARY),
                                                    width: 2.0)),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                                borderSide: BorderSide(
                                                    color: Color(COLOR_PRIMARY),
                                                    width: 2.0)),
                                            // filled: true,
                                            //fillColor: Colors.blueAccent,
                                          ),
                                          //dropdownColor: Colors.blueAccent,
                                          value: selectedDigital,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedDigital = value;
                                            });
                                          },
                                          hint: Text(
                                              'This is digital product'.tr()),
                                          items: digitalProduct.map((item) {
                                            return DropdownMenuItem(
                                              child: Text(item.toString()),
                                              value: item,
                                            );
                                          }).toList()),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      selectedDigital == "Yes"
                                          ? Row(
                                              children: [
                                                Expanded(
                                                    child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          "File type : ".tr(),
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                        Text(
                                                          "jpg, jpeg, png, gif, zip, pdf",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                        "${"File Name : ".tr()}$digitalProductFileName ",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.black)),
                                                  ],
                                                )),
                                                InkWell(
                                                  onTap: () async {
                                                    FilePickerResult? result =
                                                        await FilePicker
                                                            .platform
                                                            .pickFiles(
                                                      type: FileType.custom,
                                                      allowedExtensions: [
                                                        'jpg',
                                                        'jpeg',
                                                        'zip',
                                                        'png',
                                                        'gif',
                                                        'pdf'
                                                      ],
                                                    );

                                                    if (result != null) {
                                                      double sizeInMb = result
                                                              .files
                                                              .single
                                                              .size /
                                                          (1024 * 1024);
                                                      print(sizeInMb);
                                                      print(sizeInMb);
                                                      if (sizeInMb <=
                                                          double.parse(
                                                              fileSize)) {
                                                        setState(() {
                                                          digitalFile = File(
                                                              result.files
                                                                  .single.path
                                                                  .toString());
                                                          digitalProductFileName =
                                                              digitalFile !=
                                                                      null
                                                                  ? digitalFile!
                                                                      .path
                                                                      .split(
                                                                          '/')
                                                                      .last
                                                                  : "";
                                                        });
                                                      } else {
                                                        final snackBar =
                                                            SnackBar(
                                                          content: Text(
                                                                  '${"Please select less than ".tr()}${fileSize.toString()}  ${"mb file.".tr()}')
                                                              .tr(),
                                                        );
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                snackBar);
                                                      }
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(SnackBar(
                                                              content: Text(
                                                                  "Please select zip file!".tr())));
                                                      // User canceled the picker
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Color(
                                                                COLOR_PRIMARY),
                                                            width: 2),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    8))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Text("Upload Zip".tr()),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Container(),
                                    ],
                                  )
                                : Container(),

                            Visibility(
                              visible: selectedDigital == "No",
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Text(
                                        'Select Attribute'.tr(),
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    DropdownSearch<
                                        AttributesModel>.multiSelection(
                                      items: attributesList,
                                      key: myKey1,
                                      dropdownButtonProps: DropdownButtonProps(
                                        focusColor: Color(COLOR_PRIMARY),
                                        color: Color(COLOR_PRIMARY),
                                      ),
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            InputDecoration(
                                                contentPadding:
                                                    new EdgeInsets.only(
                                                        left: 8, right: 8),
                                                focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0),
                                                    borderSide: BorderSide(
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                        width: 2.0)),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .errorColor),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Theme.of(context)
                                                          .errorColor),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.grey.shade400),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                ),
                                                fillColor: Theme.of(context)
                                                    .inputDecorationTheme
                                                    .fillColor,
                                                focusColor:
                                                    Color(COLOR_PRIMARY),
                                                iconColor: Color(COLOR_PRIMARY),
                                                hintText:
                                                    'Select Attributes'.tr()),
                                      ),
                                      compareFn: (i1, i2) =>
                                          i1.title == i2.title,
                                      popupProps: PopupPropsMultiSelection
                                          .modalBottomSheet(
                                        fit: FlexFit.loose,
                                        showSelectedItems: true,
                                        listViewProps: ListViewProps(
                                            physics: BouncingScrollPhysics(),
                                            padding: EdgeInsets.only(left: 20)),
                                        itemBuilder:
                                            (context, item, isSelected) {
                                          return ListTile(
                                            selectedColor: Color(COLOR_PRIMARY),
                                            selected: isSelected,
                                            title: Text(item.title.toString()),
                                            onTap: () {
                                              myKey1.currentState
                                                  ?.popupValidate([item]);
                                              print(item.title);
                                            },
                                          );
                                        },
                                      ),
                                      itemAsString: (AttributesModel u) =>
                                          u.title.toString(),
                                      selectedItems: selectedAttributesList,
                                      onSaved: (data) {},
                                      onChanged: (data) {
                                        if (itemAttributes != null) {
                                          selectedAttributesList.clear();
                                          itemAttributes!.attributes!.clear();
                                          itemAttributes!.variants!.clear();
                                        } else {
                                          itemAttributes = ItemAttributes(
                                              attributes: [], variants: []);
                                        }
                                        selectedAttributesList.addAll(data);

                                        selectedAttributesList
                                            .forEach((element) {
                                          itemAttributes!.attributes!.add(
                                              Attributes(
                                                  attributesId: element.id,
                                                  attributeOptions: []));
                                        });
                                        setState(() {});
                                      },
                                    ),
                                  ]),
                            ),

                            itemAttributes == null ||
                                    itemAttributes!.attributes!.isEmpty
                                ? Container()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        "Attribute value".tr(),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      ListView.builder(
                                        itemCount:
                                            itemAttributes!.attributes!.length,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          String title = "";
                                          for (var element in attributesList) {
                                            if (itemAttributes!
                                                    .attributes![index]
                                                    .attributesId ==
                                                element.id) {
                                              title = element.title.toString();
                                            }
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        _displayTextInputDialog(
                                                            context,
                                                            index,
                                                            itemAttributes!
                                                                .attributes![
                                                                    index]
                                                                .attributesId
                                                                .toString());
                                                      },
                                                      child: Icon(
                                                        Icons.add,
                                                        color: Color(
                                                            COLOR_PRIMARY),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                Wrap(
                                                  spacing: 6.0,
                                                  runSpacing: 6.0,
                                                  children: List.generate(
                                                    itemAttributes!
                                                        .attributes![index]
                                                        .attributeOptions!
                                                        .length,
                                                    (i) {
                                                      return InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              itemAttributes!
                                                                  .attributes![
                                                                      index]
                                                                  .attributeOptions!
                                                                  .removeAt(i);

                                                              // itemAttributes!.variants!.clear();
                                                              List<List<dynamic>>
                                                                  listArary =
                                                                  [];
                                                              for (int i = 0;
                                                                  i <
                                                                      itemAttributes!
                                                                          .attributes!
                                                                          .length;
                                                                  i++) {
                                                                // main Attribute loop
                                                                if (itemAttributes!
                                                                    .attributes![
                                                                        i]
                                                                    .attributeOptions!
                                                                    .isNotEmpty)
                                                                  listArary.add(
                                                                      itemAttributes!
                                                                          .attributes![
                                                                              i]
                                                                          .attributeOptions!);
                                                              }

                                                              if (listArary
                                                                      .length >
                                                                  0) {
                                                                List<Variants>?
                                                                    variantsTemp =
                                                                    [];
                                                                List<dynamic>
                                                                    list =
                                                                    getCombination(
                                                                        listArary);
                                                                list.forEach(
                                                                    (element) {
                                                                  bool _productIsInList = itemAttributes!
                                                                      .variants!
                                                                      .any((product) =>
                                                                          product
                                                                              .variant_sku ==
                                                                          element);
                                                                  if (_productIsInList) {
                                                                    Variants variant = itemAttributes!
                                                                        .variants!
                                                                        .firstWhere((product) =>
                                                                            product.variant_sku ==
                                                                            element);
                                                                    Variants variantsModel = Variants(
                                                                        variant_sku:
                                                                            variant
                                                                                .variant_sku,
                                                                        variant_id:
                                                                            variant
                                                                                .variant_id,
                                                                        variant_image:
                                                                            variant
                                                                                .variant_image,
                                                                        variant_price:
                                                                            variant
                                                                                .variant_price,
                                                                        variant_quantity:
                                                                            variant.variant_quantity);
                                                                    variantsTemp
                                                                        .add(
                                                                            variantsModel);
                                                                  }
                                                                });
                                                                itemAttributes!
                                                                    .variants!
                                                                    .clear();
                                                                itemAttributes!
                                                                    .variants!
                                                                    .addAll(
                                                                        variantsTemp);
                                                              }
                                                            });
                                                          },
                                                          child: _buildChip(
                                                              itemAttributes!
                                                                  .attributes![
                                                                      index]
                                                                  .attributeOptions![i],
                                                              index,
                                                              i));
                                                    },
                                                  ).toList(),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                            itemAttributes == null ||
                                    itemAttributes!.variants!.isEmpty
                                ? Container()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Variant".tr(),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Variant Price".tr(),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Variant Quantity".tr() + " ",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              "Variant Image".tr(),
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      ListView.builder(
                                        itemCount:
                                            itemAttributes!.variants!.length,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        itemAttributes!
                                                            .variants![index]
                                                            .variant_sku
                                                            .toString(),
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Expanded(
                                                      child: TextFormField(
                                                        maxLength: 5,
                                                        textInputAction:
                                                            TextInputAction
                                                                .done,
                                                        initialValue:
                                                            itemAttributes!
                                                                .variants![
                                                                    index]
                                                                .variant_price,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            itemAttributes!
                                                                    .variants![
                                                                        index]
                                                                    .variant_price =
                                                                val;
                                                          });
                                                        },
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .allow(RegExp(
                                                                  r'^\d+\.?\d{0,2}')),
                                                        ],
                                                        style: TextStyle(
                                                            fontSize: 18.0),
                                                        cursorColor: Color(
                                                            COLOR_PRIMARY),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText: "Price",
                                                          contentPadding:
                                                              new EdgeInsets
                                                                      .only(
                                                                  left: 8,
                                                                  right: 8),
                                                          counterText: '',
                                                          errorStyle:
                                                              TextStyle(),
                                                          focusedBorder: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7.0),
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      COLOR_PRIMARY),
                                                                  width: 2.0)),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .errorColor),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .errorColor),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Expanded(
                                                      child: TextFormField(
                                                        maxLength: 5,
                                                        textInputAction:
                                                            TextInputAction
                                                                .done,
                                                        initialValue:
                                                            itemAttributes!
                                                                .variants![
                                                                    index]
                                                                .variant_quantity,
                                                        onChanged: (val) {
                                                          setState(() {
                                                            itemAttributes!
                                                                    .variants![
                                                                        index]
                                                                    .variant_quantity =
                                                                val;
                                                          });
                                                        },
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: TextStyle(
                                                            fontSize: 18.0),
                                                        cursorColor: Color(
                                                            COLOR_PRIMARY),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText: "Quantity",
                                                          contentPadding:
                                                              new EdgeInsets
                                                                      .only(
                                                                  left: 8,
                                                                  right: 8),
                                                          counterText: '',
                                                          errorStyle:
                                                              TextStyle(),
                                                          focusedBorder: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7.0),
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      COLOR_PRIMARY),
                                                                  width: 2.0)),
                                                          errorBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .errorColor),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                          focusedErrorBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .errorColor),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Expanded(
                                                      child: itemAttributes!
                                                                      .variants![
                                                                          index]
                                                                      .variant_image !=
                                                                  null &&
                                                              itemAttributes!
                                                                  .variants![
                                                                      index]
                                                                  .variant_image!
                                                                  .isNotEmpty
                                                          ? InkWell(
                                                              onTap: () {
                                                                _onCameraClick(
                                                                    index);
                                                              },
                                                              child:
                                                                  CachedNetworkImage(
                                                                height: 50,
                                                                width: 30,
                                                                imageUrl: itemAttributes!
                                                                    .variants![
                                                                        index]
                                                                    .variant_image!,
                                                                imageBuilder:
                                                                    (context,
                                                                            imageProvider) =>
                                                                        Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                    image: DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover),
                                                                  ),
                                                                ),
                                                                placeholder: (context,
                                                                        url) =>
                                                                    Center(
                                                                        child: CircularProgressIndicator
                                                                            .adaptive(
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation(
                                                                          Color(
                                                                              COLOR_PRIMARY)),
                                                                )),
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            )
                                                          : InkWell(
                                                              onTap: () {
                                                                _onCameraClick(
                                                                    index);
                                                              },
                                                              child: Icon(Icons
                                                                  .cloud_upload)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                            SizedBox(height: 16),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  'Price'.tr(),
                                  style: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                )),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Regular Price'.tr(),
                                          style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 17),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.3,
                                          child: TextFormField(
                                            maxLength: 5,
                                            textInputAction:
                                                TextInputAction.done,
                                            controller: rprice,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d+\.?\d{0,2}')),
                                            ],
                                            style: TextStyle(fontSize: 18.0),
                                            cursorColor: Color(COLOR_PRIMARY),
                                            validator: validateEmptyField,
                                            decoration: InputDecoration(
                                              hintText: "0",
                                              contentPadding:
                                                  new EdgeInsets.only(
                                                      left: 8, right: 8),
                                              counterText: '',
                                              errorStyle: TextStyle(),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Color(COLOR_PRIMARY),
                                                      width: 2.0)),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade400),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Discounted Price'.tr(),
                                          style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 17),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          padding: EdgeInsets.only(right: 5),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              2.25,
                                          child: TextFormField(
                                            maxLength: 5,
                                            textInputAction:
                                                TextInputAction.done,
                                            controller: disprice,
                                            onChanged: (val) {
                                              setState(() {
                                                var regularPrice = double.parse(
                                                    rprice.text.toString());
                                                var discountedPrice =
                                                    double.parse(disprice.text
                                                        .toString());

                                                if (discountedPrice >
                                                    regularPrice) {
                                                  isDiscountedPriceOk = true;
                                                  final snackBar = SnackBar(
                                                    content: Text(
                                                      'Please enter valid discount price'
                                                          .tr(),
                                                      style: TextStyle(
                                                          color: !isDarkMode(
                                                                  context)
                                                              ? Colors.white
                                                              : Colors.black),
                                                    ),
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(snackBar);
                                                } else {
                                                  isDiscountedPriceOk = false;
                                                }
                                              });
                                            },
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d+\.?\d{0,2}')),
                                            ],
                                            style: TextStyle(fontSize: 18.0),
                                            cursorColor: Color(COLOR_PRIMARY),
                                            //validator: validateEmptyField,
                                            decoration: InputDecoration(
                                              hintText: "0",
                                              contentPadding:
                                                  new EdgeInsets.only(
                                                      left: 8, right: 8),
                                              counterText: '',
                                              errorStyle: TextStyle(),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0),
                                                  borderSide: BorderSide(
                                                      color:
                                                          Color(COLOR_PRIMARY),
                                                      width: 2.0)),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color:
                                                        Colors.grey.shade400),
                                                borderRadius:
                                                    BorderRadius.circular(7.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ])
                                ],
                              ),
                            ),
                            Visibility(
                              visible: rprice.text.toString().isNotEmpty,
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        disprice.text.toString().trim().isEmpty
                                            ? amountShow(amount: "0")
                                            : amountShow(amount: disprice.text),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 18),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        rprice.text.toString().trim().isEmpty
                                            ? amountShow(amount: "0")
                                            : amountShow(amount: rprice.text),
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.grey,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: 18),
                                      ),
                                    ],
                                  )),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  'Your item Price will be display like this.'
                                      .tr(),
                                  style: TextStyle(
                                      color: isDarkMode(context)
                                          ? Colors.white
                                          : Colors.grey,
                                      fontSize: 14),
                                )),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Quantity'.tr(),
                                      style: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 17),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                          2.3,
                                      child: TextFormField(
                                        maxLength: 5,
                                        textInputAction: TextInputAction.done,
                                        controller: quantityController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                signed: true, decimal: true),
                                        style: TextStyle(fontSize: 18.0),
                                        cursorColor: Color(COLOR_PRIMARY),
                                        validator: validateEmptyField,
                                        decoration: InputDecoration(
                                          hintText: "0",
                                          contentPadding: new EdgeInsets.only(
                                              left: 8, right: 8),
                                          counterText: '',
                                          errorStyle: TextStyle(),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7.0),
                                              borderSide: BorderSide(
                                                  color: Color(COLOR_PRIMARY),
                                                  width: 2.0)),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .errorColor),
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .errorColor),
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade400),
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.only(
                                            left: 8, bottom: 8, top: 10),
                                        child: Text(
                                          '-1 to your product quantity is unlimited'
                                              .tr(),
                                          style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontSize: 14),
                                        )),
                                  ]),
                            ),

                            SizedBox(
                              height: 10,
                            ),
                            Visibility(
                              visible: (sectionModel != null &&
                                  sectionModel!.dineInActive == true),
                              child: Column(
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: Text(
                                        'Product Details'.tr(),
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      )),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Calories'.tr(),
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 18),
                                          )),
                                      Container(
                                          height: 150,
                                          child: NumberPicker(
                                              minValue: 0,
                                              maxValue: 1000,
                                              value: widget.product != null
                                                  ? widget.product!.calories
                                                  : _cal,
                                              onChanged: (value) => setState(
                                                  () => widget.product != null
                                                      ? widget.product!
                                                          .calories = value
                                                      : _cal = value))),
                                      Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Grams'.tr(),
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 18),
                                          )),
                                      Container(
                                          height: 150,
                                          child: NumberPicker(
                                              minValue: 0,
                                              maxValue: 1000,
                                              value: widget.product != null
                                                  ? widget.product!.grams
                                                  : _grm,
                                              onChanged: (value) => setState(
                                                  () => widget.product != null
                                                      ? widget.product!.grams =
                                                          value
                                                      : _grm = value)))
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Proteins'.tr(),
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 18),
                                          )),
                                      Container(
                                          height: 150,
                                          child: NumberPicker(
                                              minValue: 0,
                                              maxValue: 1000,
                                              value: widget.product != null
                                                  ? widget.product!.proteins
                                                  : _pro,
                                              onChanged: (value) => setState(
                                                  () => widget.product != null
                                                      ? widget.product!
                                                          .proteins = value
                                                      : _pro = value))),
                                      Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Fats'.tr(),
                                            style: TextStyle(
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 18),
                                          )),
                                      Container(
                                          height: 150,
                                          child: NumberPicker(
                                              minValue: 0,
                                              maxValue: 1000,
                                              value: widget.product != null
                                                  ? widget.product!.fats
                                                  : _fats,
                                              onChanged: (value) => setState(
                                                  () => widget.product != null
                                                      ? widget.product!.fats =
                                                          value
                                                      : _fats = value)))
                                    ],
                                  ),
                                  Divider(
                                    thickness: 8,
                                    height: 16,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Product Type'.tr(),
                                      style: TextStyle(
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Flexible(
                                          child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SwitchListTile.adaptive(
                                              activeColor: Color(0xFFFEDF00),
                                              title: Text('Veg'.tr(),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: isDarkMode(context)
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: "Poppinsl")),
                                              value: veg,
                                              onChanged: (bool newValue) async {
                                                veg = newValue;
                                                veg == true
                                                    ? nonVeg = false
                                                    : null;
                                                setState(() {});
                                              })
                                        ],
                                      )),
                                      Image(
                                        image: AssetImage(
                                            "assets/images/verti_divider.png"),
                                        height: 25,
                                      ),
                                      Flexible(
                                          child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SwitchListTile.adaptive(
                                              activeColor: Color(0xFFFEDF00),
                                              title: Text('Non-veg'.tr(),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      color: isDarkMode(context)
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontFamily: "Poppins")),
                                              value: nonVeg,
                                              onChanged: (bool newValue) async {
                                                nonVeg = newValue;
                                                nonVeg == true
                                                    ? veg = false
                                                    : null;
                                                setState(() {});
                                              })
                                        ],
                                      ))
                                    ],
                                  ),
                                  Divider(
                                    thickness: 8,
                                    height: 16,
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                  SizedBox(height: 16),
                                ],
                              ),
                            ),

                            sectionModel != null &&
                                    sectionModel!.serviceTypeFlag ==
                                        "ecommerce-service"
                                ? Container()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: Text(
                                          'Enable Takeaway Option'.tr(),
                                          style: TextStyle(
                                              color: isDarkMode(context)
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                      ),
                                      SwitchListTile.adaptive(
                                          activeColor: Color(COLOR_PRIMARY),
                                          title: Text('Takeaway Option'.tr(),
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: isDarkMode(context)
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontFamily: "Poppinsl")),
                                          value: takeaway,
                                          onChanged: (bool newValue) async {
                                            setState(() {
                                              takeaway = newValue;
                                            });
                                          }),
                                    ],
                                  ),

                            SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                'Add Photos'.tr(),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
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
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                'Product Category'.tr(),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),

                            SizedBox(height: 5),
                            Container(
                              height: 60,
                              child: DropdownButtonFormField<
                                      VendorCategoryModel>(
                                  validator: (date) => (date == null ||
                                          selectedCategory!.title ==
                                              'Select Product Category')
                                      ? 'Please select a category.'.tr()
                                      : null,
                                  decoration: InputDecoration(
                                    contentPadding:
                                        new EdgeInsets.only(left: 8, right: 8),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color:Color(0xFFFEDF00),
                                            width: 2.0)),
                                    errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0)),
                                    focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0)),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                        borderSide: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                            width: 2.0)),
                                    // filled: true,
                                    //fillColor: Colors.blueAccent,
                                  ),
                                  //dropdownColor: Colors.blueAccent,
                                  value: selectedCategory,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategory = value;
                                      catid = value!.id;
                                    });
                                  },
                                  hint: Text('Select product Category.'.tr()),
                                  items: categoryLst
                                      .map((VendorCategoryModel item) {
                                    return DropdownMenuItem<
                                        VendorCategoryModel>(
                                      child: Text(item.title.toString()),
                                      value: item,
                                    );
                                  }).toList()),
                            ),

                            SizedBox(
                              height: 10,
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Specification'.tr(),
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(right: 15),
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDarkMode(context)
                                                ? Colors.grey.shade700
                                                : Colors.grey,
                                            width: 0.8,
                                          ),
                                          shape: BoxShape.circle),
                                      child: IconButton(
                                        icon: Icon(Icons.add),
                                        color: Color(0xFFFEDF00),
                                        iconSize: 25,
                                        padding: EdgeInsets.only(bottom: 0),
                                        onPressed: () {
                                          setState(() {
                                            specificationList.add(
                                                SpecificationModel(
                                                    lable: '', value: ''));
                                          });
                                          // specification.addEntries([MapEntry(reviewAttributeList[index].id.toString(), rate)]);
                                        },
                                      ),
                                    )),
                              ],
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: specificationList.length,
                              padding: EdgeInsets.only(bottom: 10),
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          textAlign: TextAlign.start,
                                          initialValue:
                                              specificationList[index].lable,
                                          textInputAction: TextInputAction.done,
                                          onChanged: (value) {
                                            setState(() {
                                              specificationList[index].lable =
                                                  value;
                                            });
                                          },
                                          keyboardType: TextInputType.text,
                                          style: TextStyle(fontSize: 18.0),
                                          cursorColor: Color(COLOR_PRIMARY),
                                          //validator: validateEmptyField,
                                          decoration: InputDecoration(
                                              counterText: '',
                                              hintText: 'Title'.tr(),
                                              errorStyle: TextStyle(),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Color(
                                                              COLOR_PRIMARY))),
                                              errorBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey.shade400))),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          textAlign: TextAlign.start,
                                          initialValue:
                                              specificationList[index].value,
                                          textInputAction: TextInputAction.done,
                                          onChanged: (value) {
                                            setState(() {
                                              specificationList[index].value =
                                                  value;
                                            });
                                          },
                                          keyboardType: TextInputType.text,
                                          style: TextStyle(fontSize: 18.0),
                                          cursorColor: Color(COLOR_PRIMARY),
                                          //validator: validateEmptyField,
                                          decoration: InputDecoration(
                                              counterText: '',
                                              hintText: 'Value'.tr(),
                                              errorStyle: TextStyle(),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Color(
                                                              COLOR_PRIMARY))),
                                              errorBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .errorColor),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .grey.shade400))),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Addons'.tr(),
                                    style: TextStyle(
                                        color: isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.only(right: 15),
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isDarkMode(context)
                                                ? Colors.grey.shade700
                                                : Colors.grey,
                                            width: 0.8,
                                          ),

                                          // color: Color(0xff000000),
                                          shape: BoxShape.circle),

                                      // radius: 20,
                                      child: IconButton(
                                        icon: Icon(Icons.add),
                                        color: Color(0xFFFEDF00),
                                        iconSize: 25,
                                        padding: EdgeInsets.only(bottom: 0),
                                        onPressed: () {
                                          setState(() {
                                            lstAddOnsTitle.length++;
                                            lstAddOnPrice.length++;
                                          });
                                        },
                                      ),
                                    ))
                              ],
                            ),
                            Container(
                                width: MediaQuery.of(context).size.width * 1,
                                height: lstAddOnsTitle.length == 1
                                    ? 120
                                    : MediaQuery.of(context).size.height *
                                        (lstAddOnsTitle.length / 7.2),
                                child: ListView.builder(
                                    itemCount: lstAddOnsTitle.length,
                                    padding: EdgeInsets.only(bottom: 10),
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Column(children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.3,
                                                child: TextFormField(
                                                  textAlign: TextAlign.start,
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onSaved: (val) {
                                                    setState(() {
                                                      if (lstAddOnsTitle[
                                                                  index] ==
                                                              null ||
                                                          lstAddOnsTitle[index]
                                                              .toString()
                                                              .isEmpty) {
                                                        lstAddOnsTitle[index] =
                                                            val;
                                                      } else {
                                                        lstAddOnsTitle[index] =
                                                            val;
                                                      }
                                                    });
                                                  },
                                                  keyboardType:
                                                      TextInputType.text,
                                                  initialValue:
                                                      lstAddOnsTitle[index],
                                                  style:
                                                      TextStyle(fontSize: 18.0),
                                                  cursorColor:
                                                      Color(COLOR_PRIMARY),
                                                  //validator: validateEmptyField,
                                                  decoration: InputDecoration(
                                                      // contentPadding:
                                                      //     new EdgeInsets.only(left: 8, right: 8),
                                                      counterText: '',
                                                      hintText:
                                                          'Add title'.tr(),
                                                      errorStyle: TextStyle(),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      COLOR_PRIMARY))),
                                                      errorBorder:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .errorColor),
                                                      ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade400))),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 25,
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(right: 0),
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    2.3,
                                                child: TextFormField(
                                                  maxLength: 5,
                                                  initialValue:
                                                      lstAddOnPrice[index],
                                                  textAlign: TextAlign.start,
                                                  textInputAction:
                                                      TextInputAction.done,
                                                  onSaved: (val) {
                                                    print(lstAddOnsTitle[index]
                                                            .toString() +
                                                        "***");

                                                    if (lstAddOnPrice[index] ==
                                                            null ||
                                                        lstAddOnPrice[index]
                                                            .toString()
                                                            .isEmpty) {
                                                      lstAddOnPrice[index] =
                                                          val;
                                                    } else {
                                                      lstAddOnPrice[index] =
                                                          val;
                                                    }
                                                  },
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'^\d+\.?\d{0,2}')),
                                                  ],
                                                  style:
                                                      TextStyle(fontSize: 18.0),
                                                  cursorColor:
                                                      Color(COLOR_PRIMARY),
                                                  //validator: validateEmptyField,
                                                  decoration: InputDecoration(
                                                      // contentPadding:
                                                      //     new EdgeInsets.only(left: 8, right: 8),
                                                      counterText: '',
                                                      hintText: '0',
                                                      errorStyle: TextStyle(),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      COLOR_PRIMARY))),
                                                      errorBorder:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .errorColor),
                                                      ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade400))),
                                                ),
                                              ),
                                            ),
                                            /* Expanded(
                                          flex: 1,
                                          child: Container(
                                            height: 35,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDarkMode(context)
                                                      ? Colors.grey.shade700
                                                      : Colors.grey,
                                                  width: 0.8,
                                                ),

                                                // color: Color(0xff000000),
                                                shape: BoxShape.circle),

                                            // radius: 20,
                                            child: IconButton(
                                              icon: Text("-",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold,color: Color(COLOR_PRIMARY)),),
                                              color: Color(COLOR_PRIMARY),
                                              iconSize: 20,
                                              padding: EdgeInsets.only(bottom: 0),
                                              onPressed: () {
                                                setState(() {
                                                  print(index.toString()+"||||||||");
                                                  //lstAddSize.removeAt(index);
                                                  //lstAddSizePrice.removeAt(index);
                                                  //lstAddSize.remove(lstAddSize[index]);
                                                  //lstAddSize.remove(lstAddSize[index]);
                                                });
                                              },
                                            ),
                                          ),
                                        )*/
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                      ]);
                                    })),
                            // : Container(),
                            widget.product != null
                                ? ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        minWidth: double.infinity),
                                    child: SwitchListTile.adaptive(
                                        activeColor: Color(COLOR_PRIMARY),
                                        title: Text(
                                          'Publish'.tr(),
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ).tr(),
                                        value: publish,
                                        onChanged: (bool newValue) {
                                          publish = newValue;
                                          setState(() {});
                                        }))
                                : Container(),
                            widget.product != null
                                ? Padding(
                                    padding: EdgeInsets.only(
                                        left: 20, top: 20, right: 20),
                                    child: InkWell(
                                        onTap: () => showProductOptionsSheet(
                                            widget.product!),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Delete Product".tr(),
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: isDarkMode(context)
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ).tr(),
                                            Image(
                                              image: AssetImage(
                                                  "assets/images/delete.png"),
                                              width: 30,
                                            )
                                          ],
                                        )))
                                : Center(),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.only(top: 12, bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: BorderSide(
                              color: Color(0xFFFEDF00),
                            ),
                          ),
                          backgroundColor: Color(0xFFFEDF00),
                        ),
                        onPressed: () => submit(),
                        child: Text(
                          widget.product == null
                              ? 'Add Product'.tr()
                              : 'Edit Product'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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

  _onCameraClick(int index) {
    final action = CupertinoActionSheet(
      message: const Text(
        'Upload image',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? singleImage =
                await ImagePicker().pickImage(source: ImageSource.gallery);
            if (singleImage != null) {
              await showProgress(context, 'Image Upload...'.tr(), false);

              String image = await FireStoreUtils.uploadUserImageToFireStorage(
                  File(singleImage.path),
                  itemAttributes!.variants![index].variant_id.toString() ?? '');
              hideProgress();
              itemAttributes!.variants![index].variant_image = image;
              setState(() {});
            }
          },
          child: const Text('Choose image from gallery').tr(),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            final XFile? singleImage =
                await ImagePicker().pickImage(source: ImageSource.camera);
            if (singleImage != null) {
              await showProgress(context, 'Image Upload...'.tr(), false);

              String image = await FireStoreUtils.uploadUserImageToFireStorage(
                  File(singleImage.path),
                  itemAttributes!.variants![index].variant_id.toString() ?? '');
              hideProgress();
              itemAttributes!.variants![index].variant_image = image;
              setState(() {});
            }
          },
          child: const Text('Take a picture'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text(
          'Cancel',
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Future<void> _displayTextInputDialog(
      BuildContext context, int index, String attributeId) async {
    for (var element in attributesList) {
      if (itemAttributes!.attributes![index].attributesId == element.id) {
        title = element.title.toString();
      }
    }
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('$title' 'Attributes value'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {},
                  controller: _attributesValueController,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z a]")),
                  ],
                  maxLength: 15,
                  decoration: InputDecoration(hintText: "Add Attributes".tr()),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel".tr(),
                          style: TextStyle(color: Colors.red),
                        )),
                    SizedBox(
                      width: 20,
                    ),
                    InkWell(
                        onTap: () {
                          if (_attributesValueController.text.isEmpty) {
                            showAlertDialog(context, 'Error'.tr(),
                                "Please enter attribute value", true);
                          } else {
                            Navigator.pop(context);

                            itemAttributes!.attributes![index].attributeOptions!
                                .add(_attributesValueController.text);
                            // Attributes? attribute = itemAttributes!.attributes![index];
                            // itemAttributes!.itemAttributes!.attributes!.removeAt(index);
                            // itemAttributes!.itemAttributes!.attributes!.insert(index, attribute);

                            // itemAttributes!.variants!.clear();
                            List<List<dynamic>> listArary = [];
                            for (int i = 0;
                                i < itemAttributes!.attributes!.length;
                                i++) {
                              // main Attribute loop
                              if (itemAttributes!
                                  .attributes![i].attributeOptions!.isNotEmpty)
                                listArary.add(itemAttributes!
                                    .attributes![i].attributeOptions!);
                            }

                            List<dynamic> list = getCombination(listArary);

                            list.forEach((element) {
                              bool _productIsInList = itemAttributes!.variants!
                                  .any((product) =>
                                      product.variant_sku == element);
                              if (_productIsInList) {
                                // Variants variant = itemAttributes!.variants!.firstWhere((product) => product.variant_sku == element);
                                // Variants variantsModel = Variants(
                                //     variant_sku: variant.variant_sku,
                                //     variant_id: variant.variant_id,
                                //     variant_image: variant.variant_image,
                                //     variant_price: variant.variant_price,
                                //     variant_quantity: variant.variant_quantity);
                                // itemAttributes!.variants!.add(variantsModel);
                              } else {
                                if (itemAttributes!.attributes![index]
                                        .attributeOptions!.length ==
                                    1) {
                                  itemAttributes!.variants!.clear();
                                  Variants variantsModel = Variants(
                                      variant_sku: element,
                                      variant_id: Uuid().v1(),
                                      variant_image: "",
                                      variant_price: "0",
                                      variant_quantity: "-1");
                                  itemAttributes!.variants!.add(variantsModel);
                                } else {
                                  Variants variantsModel = Variants(
                                      variant_sku: element,
                                      variant_id: Uuid().v1(),
                                      variant_image: "",
                                      variant_price: "0",
                                      variant_quantity: "-1");
                                  itemAttributes!.variants!.add(variantsModel);
                                }
                              }
                            });
                            print(itemAttributes!.variants!
                                .map((e) => e.toJson())
                                .toList());
                            _attributesValueController.clear();
                          }
                        },
                        child: Text(
                          "Add".tr(),
                          style: TextStyle(color: Colors.green),
                        )),
                  ],
                )
              ],
            ),
          );
        });
  }

  List<dynamic> getCombination(List<List<dynamic>> listArray) {
    debugPrint('--->1 ' + listArray.toString());

    if (listArray.length == 1) {
      return listArray[0];
    } else {
      List<dynamic> result = [];
      var allCasesOfRest = getCombination(listArray.sublist(1));
      for (var i = 0; i < allCasesOfRest.length; i++) {
        for (var j = 0; j < listArray[0].length; j++) {
          result.add(listArray[0][j] + '-' + allCasesOfRest[i]);
        }
      }
      return result;
    }
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
                  color: Colors.black,
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

  submit() async {
    if (selectedCategory == null) {
      showimgAlertDialog(context, 'Category selection is Required!'.tr(),
          'Please Select category'.tr(), true);
    } else if (isDiscountedPriceOk == true) {
      showimgAlertDialog(context, 'Valid amount is Required!'.tr(),
          'Please enter valid discount price'.tr(), true);
    } else if (selectedDigital == "Yes" &&
        digitalFile == null &&
        digitalProductFileName!.isEmpty) {
      showimgAlertDialog(context, 'Digital Product'.tr(),
          'Please upload digital product'.tr(), true);
    } else {
      // catselect();
      if (_key.currentState?.validate() ?? false) {
        _key.currentState!.save();

        specification.clear();
        specificationList.forEach((element) {
          if (element.value.isNotEmpty && element.lable.isNotEmpty) {
            specification.addEntries([MapEntry(element.lable, element.value)]);
          }
        });

        print("---->" + specification.toString());

        if (itemAttributes != null) {
          if (itemAttributes!.attributes!.isEmpty ||
              itemAttributes!.variants!.isEmpty) {
            itemAttributes = null;
          }
        }

        ProductModel productModel = widget.product ?? ProductModel();
        await showProgress(
            context,
            widget.product == null
                ? 'Adding product...'.tr()
                : 'Applying edits...'.tr(),
            false);
        List<String> mediaFilesURLs = _mediaFiles
            .where((element) => element is String)
            .toList()
            .cast<String>();
        List<File> imagesToUpload = _mediaFiles
            .where((element) => element is File)
            .toList()
            .cast<File>();
        if (imagesToUpload.isNotEmpty) {
          updateProgress(
            'Uploading Product Images {} of {}'
                .tr(args: ['1', '${imagesToUpload.length}']),
          );
          for (int i = 0; i < imagesToUpload.length; i++) {
            if (i != 0)
              updateProgress(
                'Uploading Product Images {} of {}'.tr(
                  args: ['${i + 1}', '${imagesToUpload.length}'],
                ),
              );
            String url = await fireStoreUtils.uploadProductImage(
              imagesToUpload[i],
              'Uploading Product Images {} of {}'.tr(
                args: ['${i + 1}', '${imagesToUpload.length}'],
              ),
            );
            mediaFilesURLs.add(url);
          }
        }

        if (selectedDigital == "Yes" && digitalFile != null) {
          await showProgress(
              context, 'Updating digital product...'.tr(), false);
          String fileName = digitalFile!.path.split('/').last;

          Reference upload = FirebaseStorage.instance
              .ref()
              .child(STORAGE_ROOT + '/digitalProducts/$fileName');
          UploadTask uploadTask = upload.putFile(digitalFile!);
          uploadTask.whenComplete(() {}).catchError((onError) {
            print((onError as PlatformException).message);
          });
          var storageRef = (await uploadTask.whenComplete(() {})).ref;
          String downloadUrl = await storageRef.getDownloadURL();
          productModel.digitalProduct = downloadUrl;
        }
        productModel.photo =
            mediaFilesURLs.isNotEmpty ? mediaFilesURLs.first : "";
        productModel.photos = mediaFilesURLs;
        productModel.price = rprice.text.toString();
        productModel.disPrice =
            disprice.text.toString().isEmpty ? "0" : disprice.text.toString();
        productModel.quantity = int.parse(quantityController.text);
        productModel.description = desc!;
        productModel.itemAttributes = itemAttributes;
        productModel.specification = specification;
        productModel.brandID =
            selectedBrandModel != null ? selectedBrandModel!.id.toString() : "";
        productModel.calories =
            widget.product != null ? widget.product!.calories : _cal;
        productModel.grams =
            widget.product != null ? widget.product!.grams : _grm;
        productModel.proteins =
            widget.product != null ? widget.product!.proteins : _pro;
        productModel.fats =
            widget.product != null ? widget.product!.fats : _fats;
        productModel.veg = veg;
        productModel.nonveg = nonVeg;
        productModel.name = title!;
        productModel.isDigitalProduct = selectedDigital == "Yes" ? true : false;
        if (widget.product != null) {
          productModel.publish = publish;
        }
        productModel.vendorID = MyAppState.currentUser!.vendorID;
        productModel.categoryID = catid;
        productModel.section_id = section_id;

        for (int a = 0; a < lstAddOnsTitle.length; a++) {
          if (lstAddOnsTitle[a] == null ||
              lstAddOnsTitle[a].toString().isEmpty) {
          } else {
            if (lstAddOnsTitle[a] != null && lstAddOnPrice[a] == null) {
              listAddPrice.add("0");
            } else {
              listAddTitle.add(lstAddOnsTitle[a]);
              listAddPrice.add(
                  lstAddOnPrice[a].toString().isEmpty ? "0" : lstAddOnPrice[a]);
            }
          }
        }

        productModel.addOnsTitle = listAddTitle.toList();
        productModel.addOnsPrice = listAddPrice.toList();
        productModel.takeaway = takeaway;
        //productModel.geoFireData = GeoFireData(geohash: randomAlphaNumeric(10),geoPoint: GeoPoint(position!.latitude, position!.longitude));

        //productModel.lstSizeCustom = aaa.toList();
        //productModel.lstAddOnsCustom = bbb.toList();

        await fireStoreUtils.addOrUpdateProduct(productModel);
        await hideProgress();
        Navigator.pop(context);
      } else {
        setState(() {
          _validate = AutovalidateMode.onUserInteraction;
        });
      }
    }
  }

  showProductOptionsSheet(ProductModel productModel) {
    final action = CupertinoActionSheet(
      message: Text(
        'Are you sure you want to delete this product?',
        style: TextStyle(fontSize: 15.0),
      ).tr(),
      title: Text(
        '${productModel.name}',
        style: TextStyle(fontSize: 17.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Yes, i'm sure, Delete").tr(),
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(context);
            Navigator.pop(context);
            fireStoreUtils.deleteProduct(productModel.id);
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

  Widget _buildChip(
      String label, int attributesIndex, int attributesOptionIndex) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.remove_circle, color: Colors.white),
        ],
      ),
      backgroundColor: Color(COLOR_PRIMARY),
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(8.0),
    );
  }
}

class SpecificationModel {
  String lable;

  String value;

  SpecificationModel({required this.lable, required this.value});
}
