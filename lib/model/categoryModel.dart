class VendorCategoryModel {
  List<dynamic>? reviewAttributes;
  String? sectionId;
  String? photo;
  String? description;
  String? id;
  String? title;
  num? order;
  String? section_id;

  VendorCategoryModel(
      {this.reviewAttributes,
        this.sectionId,
        this.photo,
        this.description,
        this.id,
        this.title,
        this.section_id,
        this.order});


  VendorCategoryModel.fromJson(Map<String, dynamic> json) {
    reviewAttributes = json['review_attributes'] ?? [];
    sectionId = json['section_id']??"";
    photo = json['photo']??"";
    description = json['description']??'';
    id = json['id']??"";
    title = json['title']??"";
    section_id = json['section_id']??"";
    order = json['order'] ?? 0;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['review_attributes'] = reviewAttributes;
    data['section_id'] = sectionId;
    data['photo'] = photo;
    data['description'] = description;
    data['id'] = id;
    data['title'] = title;
    data['order'] = order;
    data['section_id'] = section_id;
    return data;
  }
}
