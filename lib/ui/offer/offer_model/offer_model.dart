import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  String? id;
  String? code;
  String? description;
  String? discount;
  String? discountType;
  Timestamp? expiresAt;
  bool? isEnabled;
  bool? isPublic = false;
  String? image = "";
  String? vendorID;
  String? section_id;


  OfferModel({
    this.description,
    this.discount,
    this.discountType,
    this.expiresAt,
    this.image = "",
    this.isEnabled,
    this.code,
    this.id,
    this.vendorID,
    this.section_id,
    this.isPublic,
  });

  factory OfferModel.fromJson(Map<String, dynamic> parsedJson) {
    return OfferModel(
      description: parsedJson["description"],
      discount: parsedJson["discount"],
      discountType: parsedJson["discountType"],
      expiresAt: parsedJson["expiresAt"],
      image: parsedJson["image"] == null
          ? ((parsedJson["photo"] == null ? "" : parsedJson["photo"]))
          : parsedJson["image"],
      isEnabled: parsedJson["isEnabled"],
      code: parsedJson["code"],
      id: parsedJson["id"] == null ? "" : parsedJson["id"],
      vendorID: parsedJson["vendorID"],
      section_id: parsedJson["section_id"],
      isPublic: parsedJson['isPublic'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "description": this.description,
      "discount": this.discount,
      "discountType": this.discountType,
      "expiresAt": this.expiresAt,
      "image": this.image,
      "isEnabled": this.isEnabled,
      "code": this.code,
      "id": this.id,
      "vendorID": this.vendorID,
      "section_id": this.section_id,
      "isPublic": this.isPublic
    };
  }
}
