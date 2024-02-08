import 'package:nocstore/model/ItemAttributes.dart';

class ProductModel {
  String categoryID;
  String brandID;

  String description;

  String id;

  String photo;

  List<dynamic> photos;

  String price;

  String name;

  String vendorID;
  String section_id;

  int quantity;

  bool publish;

  int calories;

  int grams;

  int proteins;

  int fats;

  bool veg;

  bool nonveg;
  String? disPrice = "0";
  bool takeaway;

  List<dynamic> addOnsTitle = [];
  List<dynamic> addOnsPrice = [];

  ItemAttributes? itemAttributes;
  Map<String, dynamic>? reviewAttributes;

  Map<String, dynamic> specification = {};

  num reviewsCount;
  num reviewsSum;
  bool? isDigitalProduct;
  String? digitalProduct;

  ProductModel({
    this.categoryID = '',
    this.brandID = '',
    this.description = '',
    this.id = '',
    this.photo = '',
    this.photos = const [],
    this.price = '',
    this.name = '',
    this.quantity = -1,
    this.vendorID = '',
    this.section_id = '',
    this.calories = 0,
    this.grams = 0,
    this.proteins = 0,
    this.fats = 0,
    this.publish = true,
    this.veg = false,
    this.nonveg = false,
    this.disPrice,
    this.takeaway = false,
    this.reviewsCount = 0,
    this.reviewsSum = 0,
    this.addOnsPrice = const [],
    this.addOnsTitle = const [],
    this.itemAttributes,
    this.specification = const {},
    this.reviewAttributes,
    this.isDigitalProduct,
    this.digitalProduct,
    /*this.lstSizeCustom = const [],
        this.lstAddOnsCustom = const []*/
  });


  factory ProductModel.fromJson(Map<String, dynamic> parsedJson) {
    return new ProductModel(
      categoryID: parsedJson['categoryID'] ?? '',
      brandID: parsedJson['brandID'] ?? '',
      description: parsedJson['description'] ?? '',
      id: parsedJson['id'] ?? '',
      photo: parsedJson['photo'],
      photos: parsedJson['photos'] ?? [],
      price: parsedJson['price'] ?? '',
      quantity: parsedJson['quantity'] ?? -1,
      name: parsedJson['name'] ?? '',
      vendorID: parsedJson['vendorID'] ?? '',
      section_id: parsedJson['section_id'] ?? '',
      publish: parsedJson['publish'] ?? true,
      calories: parsedJson['calories'] ?? 0,
      grams: parsedJson['grams'] ?? 0,
      proteins: parsedJson['proteins'] ?? 0,
      fats: parsedJson['fats'] ?? 0,
      nonveg: parsedJson['nonveg'] ?? false,
      disPrice: parsedJson['disPrice'] ?? '0',
      specification: parsedJson['product_specification'] ?? {},
      takeaway: parsedJson['takeawayOption'] == null ? false : parsedJson['takeawayOption'],
      addOnsPrice: parsedJson['addOnsPrice'] ?? [],
      addOnsTitle: parsedJson['addOnsTitle'] ?? [],
      reviewsCount: parsedJson['reviewsCount'] ?? 0,
      reviewsSum: parsedJson['reviewsSum'] ?? 0,
      isDigitalProduct: parsedJson['isDigitalProduct'] ?? false,
      digitalProduct: parsedJson['digitalProduct'] ?? "",
      reviewAttributes: parsedJson['reviewAttributes'] ?? {},
       veg: parsedJson['veg'] ?? false,
      itemAttributes: (parsedJson.containsKey('item_attribute') && parsedJson['item_attribute'] != null) ? ItemAttributes.fromJson(parsedJson['item_attribute']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    photos.toList().removeWhere((element) => element == null);
    return {
      'categoryID': this.categoryID,
      'brandID': this.brandID,
      'description': this.description,
      'id': this.id,
      'photo': this.photo,
      'photos': this.photos,
      'price': this.price,
      'name': this.name,
      'quantity': this.quantity,
      'vendorID': this.vendorID,
      'section_id': this.section_id,
      'publish': this.publish,
      'calories': this.calories,
      'grams': this.grams,
      'proteins': this.proteins,
      'fats': this.fats,
      'veg': this.veg,
      'nonveg': this.nonveg,
      'takeawayOption': this.takeaway,
      'disPrice': this.disPrice,
      "addOnsTitle": this.addOnsTitle,
      "addOnsPrice": this.addOnsPrice,
      'item_attribute': itemAttributes != null ? itemAttributes!.toJson() : null,
      'product_specification': specification,
      'reviewAttributes': reviewAttributes,
      'reviewsCount': reviewsCount,
      'reviewsSum': reviewsSum,
      'isDigitalProduct': isDigitalProduct,
      'digitalProduct': digitalProduct,
      //"lstAddOnsCustom":this.lstAddOnsCustom.map((e) => e.toJson()).toList(),
      //"lstSizeCustom":this.lstSizeCustom.map((e) => e.toJson()).toList()
    };
  }
}

class ReviewsAttribute {
  num? reviewsCount;
  num? reviewsSum;


  ReviewsAttribute(
      { this.reviewsCount,
        this.reviewsSum,});

  ReviewsAttribute.fromJson(Map<String, dynamic> json) {
    reviewsCount = json['reviewsCount']??0;
    reviewsSum = json['reviewsSum']??0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    return data;
  }
}