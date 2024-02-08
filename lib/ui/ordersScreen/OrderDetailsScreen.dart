import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/model/OrderModel.dart';
import 'package:nocstore/model/OrderProductModel.dart';
import 'package:nocstore/model/TaxModel.dart';
import 'package:nocstore/model/variant_info.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel orderModel;

  const OrderDetailsScreen({Key? key, required this.orderModel})
      : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  FireStoreUtils fireStoreUtils = FireStoreUtils();
  double total = 0.0;
  double adminComm = 0.0;
  double specialDiscount = 0.0;
  double discount = 0.0;
  var tipAmount = "0.0";

  @override
  void initState() {
    widget.orderModel.products.forEach((element) {
      if (element.extras_price != null &&
          element.extras_price!.isNotEmpty &&
          double.parse(element.extras_price!) != 0.0) {
        total += element.quantity * double.parse(element.extras_price!);
      }
      total += element.quantity * double.parse(element.price);
    });

    discount = double.parse(widget.orderModel.discount.toString());

    if (widget.orderModel.specialDiscount != null ||
        widget.orderModel.specialDiscount!['special_discount'] != null) {
      specialDiscount = double.parse(
          widget.orderModel.specialDiscount!['special_discount'].toString());
    }

    var totalamount = total - discount - specialDiscount;

    adminComm = (widget.orderModel.adminCommissionType == 'Percent')
        ? (totalamount * double.parse(widget.orderModel.adminCommission!)) / 100
        : double.parse(widget.orderModel.adminCommission!);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDarkMode(context) ? const Color(DARK_CARD_BG_COLOR) : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {
            Navigator.of(context).pop();
          }, icon: Icon(Icons.arrow_back, color: Colors.black,)),
          title: Text(
        "Order Summary".tr(),
        style: TextStyle(
            fontFamily: 'Poppinsr',
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
            color: isDarkMode(context)
                ? Colors.grey.shade200
                : const Color(0xff333333)),
      )),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildOrderSummaryCard(widget.orderModel),
            Card(
              color: isDarkMode(context)
                  ? const Color(DARK_CARD_BG_COLOR)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Admin commission",
                          ),
                        ),
                        Text(
                          "(-${amountShow(amount: adminComm.toString())})",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Note : Admin commission will be debited from your wallet balance. \nAdmin commission will apply on order Amount minus Discount & Special Discount (if applicable)."
                          .tr(),
                      style: TextStyle(color: Colors.red),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderSummaryCard(OrderModel orderModel) {
    print("order status ${widget.orderModel.id}");
    double specialDiscountAmount = 0.0;
    String taxAmount = "0.0";
    if (widget.orderModel.specialDiscount!.isNotEmpty) {
      specialDiscountAmount = double.parse(
          widget.orderModel.specialDiscount!['special_discount'].toString());
    }

    if (widget.orderModel.taxModel != null) {
      for (var element in widget.orderModel.taxModel!) {
        taxAmount = (double.parse(taxAmount) +
                calculateTax(
                    amount:
                        (total - discount - specialDiscountAmount).toString(),
                    taxModel: element))
            .toString();
      }
    }

    var totalamount =
        total + double.parse(taxAmount) - discount - specialDiscountAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        color: isDarkMode(context)
            ? const Color(DARK_CARD_BG_COLOR)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 15,
              ),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: widget.orderModel.products.length,
                  itemBuilder: (context, index) {
                    VariantInfo? variantIno =
                        widget.orderModel.products[index].variant_info;
                    List<dynamic>? addon =
                        widget.orderModel.products[index].extras;
                    String extrasDisVal = '';
                    for (int i = 0; i < addon!.length; i++) {
                      extrasDisVal +=
                          '${addon[i].toString().replaceAll("\"", "")} ${(i == addon.length - 1) ? "" : ","}';
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CachedNetworkImage(
                                height: 55,
                                width: 55,
                                // width: 50,
                                imageUrl:
                                    widget.orderModel.products[index].photo,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          )),
                                    ),
                                errorWidget: (context, url, error) => ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      placeholderImage,
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height,
                                    ))),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.orderModel.products[index].name,
                                        style: TextStyle(
                                            fontFamily: 'Poppinsr',
                                            fontSize: 18,
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode(context)
                                                ? Colors.grey.shade200
                                                : const Color(0xff333333)),
                                      ),
                                      Text(
                                        ' x ${widget.orderModel.products[index].quantity}',
                                        style: TextStyle(
                                            fontFamily: 'Poppinsr',
                                            letterSpacing: 0.5,
                                            color: isDarkMode(context)
                                                ? Colors.grey.shade200
                                                : Colors.black
                                                    .withOpacity(0.60)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  getPriceTotalText(
                                      widget.orderModel.products[index]),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        variantIno == null ||
                                variantIno.variant_options!.isEmpty
                            ? Container()
                            : Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Wrap(
                                  spacing: 6.0,
                                  runSpacing: 6.0,
                                  children: List.generate(
                                    variantIno.variant_options!.length,
                                    (i) {
                                      return _buildChip(
                                          "${variantIno.variant_options!.keys.elementAt(i)} : ${variantIno.variant_options![variantIno.variant_options!.keys.elementAt(i)]}",
                                          i);
                                    },
                                  ).toList(),
                                ),
                              ),
                        const SizedBox(
                          height: 5,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 5, right: 10),
                          child: extrasDisVal.isEmpty
                              ? Container()
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    extrasDisVal,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontFamily: 'Poppinsr'),
                                  ),
                                ),
                        ),
                      ],
                    );
                  }),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                title: Text(
                  'Subtotal'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppinsm',
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDarkMode(context)
                        ? Colors.grey.shade300
                        : const Color(0xff9091A4),
                  ),
                ),
                trailing: Text(
                  amountShow(amount: total.toString()),
                  style: TextStyle(
                    fontFamily: 'Poppinssm',
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: isDarkMode(context)
                        ? Colors.grey.shade300
                        : const Color(0xff333333),
                  ),
                ),
              ),
              Visibility(
                visible: orderModel.vendor.specialDiscountEnable,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  title: Text(
                    'Special Discount'.tr() +
                        "(${widget.orderModel.specialDiscount!['special_discount_label']}${widget.orderModel.specialDiscount!['specialType'] == "amount" ? currencyData!.symbol : "%"})",
                    style: TextStyle(
                      fontFamily: 'Poppinsm',
                      fontSize: 16,
                      letterSpacing: 0.5,
                      color: isDarkMode(context)
                          ? Colors.grey.shade300
                          : const Color(0xff9091A4),
                    ),
                  ),
                  trailing: Text(
                    "(-${amountShow(amount: specialDiscountAmount.toString())})",
                    style: TextStyle(
                        fontFamily: 'Poppinssm',
                        letterSpacing: 0.5,
                        fontSize: 16,
                        color: Colors.red),
                  ),
                ),
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                title: Text(
                  'Discount'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppinsm',
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDarkMode(context)
                        ? Colors.grey.shade300
                        : const Color(0xff9091A4),
                  ),
                ),
                trailing: Text(
                  "(-${amountShow(amount: discount.toString())})",
                  style: TextStyle(
                      fontFamily: 'Poppinssm',
                      letterSpacing: 0.5,
                      fontSize: 16,
                      color: Colors.red),
                ),
              ),
              ListView.builder(
                itemCount: orderModel.taxModel!.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  TaxModel taxModel = orderModel.taxModel![index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    title: Text(
                      '${taxModel.title.toString()} (${taxModel.type == "fix" ? amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})',
                      style: TextStyle(
                        fontFamily: 'Poppinsm',
                        fontSize: 16,
                        letterSpacing: 0.5,
                        color: isDarkMode(context)
                            ? Colors.grey.shade300
                            : const Color(0xff9091A4),
                      ),
                    ),
                    trailing: Text(
                      amountShow(
                          amount: calculateTax(
                                  amount: (double.parse(total.toString()) -
                                          discount -
                                          specialDiscountAmount)
                                      .toString(),
                                  taxModel: taxModel)
                              .toString()),
                      style: TextStyle(
                        fontFamily: 'Poppinssm',
                        letterSpacing: 0.5,
                        fontSize: 16,
                        color: isDarkMode(context)
                            ? Colors.grey.shade300
                            : const Color(0xff333333),
                      ),
                    ),
                  );
                },
              ),
              (widget.orderModel.notes != null &&
                      widget.orderModel.notes!.isNotEmpty)
                  ? ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      title: Text(
                        "Remarks".tr(),
                        style: TextStyle(
                          fontFamily: 'Poppinsm',
                          fontSize: 17,
                          letterSpacing: 0.5,
                          color: isDarkMode(context)
                              ? Colors.grey.shade300
                              : const Color(0xff9091A4),
                        ),
                      ),
                      trailing: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                              isScrollControlled: true,
                              isDismissible: true,
                              context: context,
                              backgroundColor: Colors.transparent,
                              enableDrag: true,
                              builder: (BuildContext context) =>
                                  viewNotesheet(widget.orderModel.notes!));
                        },
                        child: Text(
                          "View".tr(),
                          style: TextStyle(
                              fontSize: 18,
                              color: Color(COLOR_PRIMARY),
                              letterSpacing: 0.5,
                              fontFamily: 'Poppinsm'),
                        ),
                      ),
                    )
                  : Container(),
              widget.orderModel.couponCode!.trim().isNotEmpty
                  ? ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      title: Text(
                        'Coupon Code'.tr(),
                        style: TextStyle(
                          fontFamily: 'Poppinsm',
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: isDarkMode(context)
                              ? Colors.grey.shade300
                              : const Color(0xff9091A4),
                        ),
                      ),
                      trailing: Text(
                        widget.orderModel.couponCode!,
                        style: TextStyle(
                          fontFamily: 'Poppinsm',
                          letterSpacing: 0.5,
                          fontSize: 16,
                          color: isDarkMode(context)
                              ? Colors.grey.shade300
                              : const Color(0xff333333),
                        ),
                      ),
                    )
                  : Container(),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                title: Text(
                  'Order Total'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppinsm',
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDarkMode(context)
                        ? Colors.grey.shade300
                        : const Color(0xff333333),
                  ),
                ),
                trailing: Text(
                  amountShow(amount: totalamount.toString()),
                  style: TextStyle(
                    fontFamily: 'Poppinssm',
                    letterSpacing: 0.5,
                    fontSize: 16,
                    color: isDarkMode(context)
                        ? Colors.grey.shade300
                        : const Color(0xff333333),
                  ),
                ),
              ),
              Visibility(
                visible: orderModel.status != ORDER_STATUS_DRIVER_REJECTED,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: InkWell(
                    child: Container(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                            color: Color(0xFFFEDF00),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                width: 0.8, color: Color(0xFFFEDF00),)),
                        child: Center(
                          child: Text(
                            'Print Invoice'.tr(),
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: "Poppinsm",
                                fontSize: 15
                                // fontWeight: FontWeight.bold,
                                ),
                          ),
                        )),
                    onTap: () {
                      printTicket();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;

    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      log(bytes.toString());
      String base64Image = base64Encode(bytes);

      log(base64Image.toString());

      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      if (result == "true") {
        showAlertDialog(context, "Successfully".tr(),
            "Invoice print successfully".tr(), true);
      }
    } else {
      getBluetooth();
    }
  }

  String taxAmount = "0.0";

  Future<List<int>> getTicket() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    bytes += generator.text("Invoice".tr(),
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    bytes += generator.text(widget.orderModel.vendor.title,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Tel: ${widget.orderModel.vendor.phonenumber}',
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Address'.tr(),
          width: 12,
          styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(
          text:
              '${widget.orderModel.address.line1} ${widget.orderModel.address.line2}, ${widget.orderModel.address.city}, ${widget.orderModel.address.country}',
          width: 12,
          styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Type'.tr(),
          width: 12,
          styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: widget.orderModel.takeAway == false
              ? 'Deliver to door'.tr()
              : 'Takeaway'.tr(),
          width: 12,
          styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Date'.tr(),
          width: 12,
          styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: DateFormat('dd-MM-yyyy, HH:mm')
              .format(DateTime.fromMicrosecondsSinceEpoch(
                  widget.orderModel.createdAt.microsecondsSinceEpoch))
              .toString(),
          width: 12,
          styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              bold: true)),
    ]);
    bytes += generator.hr();

    List<OrderProductModel> products = widget.orderModel.products;
    for (int i = 0; i < products.length; i++) {
//  bytes += generator.row([
//    PosColumn(
//           text: 'No',
//           width: 12,
//           styles: PosStyles(align: PosAlign.left, bold: true)),
//   ]);
//  bytes += generator.row([
//     PosColumn(
//           text: (i + 1).toString(),
//           width: 12,
//           styles: PosStyles(
//             align: PosAlign.left,
//           )),
//   ]);
      bytes += generator.row([
        PosColumn(
            text: 'Item:'.tr(),
            width: 12,
            styles: const PosStyles(align: PosAlign.left, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(
            text: products[i].name,
            width: 12,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Qty:'.tr(),
            width: 12,
            styles: const PosStyles(align: PosAlign.left, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(
            text: products[i].quantity.toString(),
            width: 12,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
      ]);
      bytes += generator.row([
        PosColumn(
            text: 'Price:'.tr(),
            width: 12,
            styles: const PosStyles(align: PosAlign.left, bold: true)),
      ]);
      bytes += generator.row([
        PosColumn(
            text: products[i].price.toString(),
            width: 12,
            styles: const PosStyles(align: PosAlign.left)),
      ]);
      bytes += generator.hr();
      //   bytes += generator.row([

      //   PosColumn(
      //       text: ' ',
      //       width: 1,
      //       styles: PosStyles(align: PosAlign.center, bold: true)),

      // ]);
      // bytes += generator.row([
      //   // PosColumn(text: (i + 1).toString(), width: 1),

      // PosColumn(
      //     text: '',
      //     width: 1,
      //     styles: PosStyles(
      //       align: PosAlign.center,
      //     )),

      // ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'Subtotal'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: total.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Discount'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: discount.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Special Discount'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: widget.orderModel.specialDiscount != null
              ? widget.orderModel.specialDiscount!['special_discount']
                  .toDouble()
                  .toStringAsFixed(currencyData!.decimal)
              : '0',
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Delivery charges'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: widget.orderModel.deliveryCharge == null
              ? "0.0"
              : double.parse(widget.orderModel.deliveryCharge
                      .toString()
                      .replaceAll(',', '')
                      .replaceAll('\€', ''))
                  .toString(),
          // widget.orderModel.deliveryCharge!,
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Tip Amount'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: widget.orderModel.tipValue!.isEmpty
              ? "0.0"
              : widget.orderModel.tipValue!,
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Tax'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: taxAmount.toString(),
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    if (widget.orderModel.notes != null &&
        widget.orderModel.notes!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
            text: "Remark".tr(),
            width: 5,
            styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
        PosColumn(
            text: '',
            width: 4,
            styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
        PosColumn(
            text: widget.orderModel.notes!.toString(),
            width: 3,
            styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            )),
      ]);
    }
    double tipValue = widget.orderModel.tipValue!.isEmpty
        ? 0.0
        : double.parse(widget.orderModel.tipValue!);
    if (widget.orderModel.taxModel != null) {
      for (var element in widget.orderModel.taxModel!) {
        taxAmount = (double.parse(taxAmount) +
                calculateTax(
                    amount: (total - discount).toString(), taxModel: element))
            .toString();
      }
    }

    var totalamount = widget.orderModel.deliveryCharge == null ||
            widget.orderModel.deliveryCharge!.isEmpty
        ? total + double.parse(taxAmount) - discount
        : total +
            double.parse(taxAmount) +
            double.parse(widget.orderModel.deliveryCharge!) +
            tipValue -
            discount;

    bytes += generator.row([
      PosColumn(
          text: 'Order Total'.tr(),
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: '',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.center,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
      PosColumn(
          text: totalamount.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 3,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);
    // ticket.feed(2);
    bytes += generator.text('Thank you!'.tr(),
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.cut();

    return bytes;
  }

  List availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("printer status $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths!;
      showLoadingAlert();
    });
  }

  showLoadingAlert() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connect Bluetooth device').tr(),
          content: SizedBox(
            width: double.maxFinite,
            child: availableBluetoothDevices.length == 0
                ? Center(
                    child: const Text(
                            "Please connect device from your bluetooth setting.")
                        .tr())
                : ListView.builder(
                    itemCount: availableBluetoothDevices.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          String select = availableBluetoothDevices[index];
                          List list = select.split("#");
                          // String name = list[0];
                          String mac = list[1];
                          setConnect(mac);
                          Navigator.pop(context);
                        },
                        title: Text('${availableBluetoothDevices[index]}'),
                        subtitle: const Text("Click to connect").tr(),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> setConnect(String mac) async {
    final String? result = await BluetoothThermalPrinter.connect(mac);
    print("state conneected $result");
    if (result == "true") {
      printTicket();
    }
  }

  getPriceTotalText(OrderProductModel s) {
    double total = 0.0;

    if (s.extras_price != null &&
        s.extras_price!.isNotEmpty &&
        double.parse(s.extras_price!) != 0.0) {
      total += s.quantity * double.parse(s.extras_price!);
    }
    total += s.quantity * double.parse(s.price);

    return Text(
      amountShow(amount: total.toString()),
      style: TextStyle(
          fontSize: 20, color: Colors.black, fontFamily: "Poppinsm"),
    );
  }

  viewNotesheet(String notes) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height / 4.3,
          left: 25,
          right: 25),
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(style: BorderStyle.none)),
      child: Column(
        children: [
          InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 0.3),
                    color: Colors.transparent,
                    shape: BoxShape.circle),

                // radius: 20,
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )),
          const SizedBox(
            height: 25,
          ),
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDarkMode(context)
                    ? const Color(0XFF2A2A2A)
                    : Colors.white),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        'Remark'.tr(),
                        style: TextStyle(
                            fontFamily: 'Poppinssb',
                            color: isDarkMode(context)
                                ? Colors.white70
                                : Colors.black,
                            fontSize: 16),
                      )),
                  Container(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 20),
                    // height: 120,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, top: 20, bottom: 20),
                        color: isDarkMode(context)
                            ? const Color(DARK_CARD_BG_COLOR)
                            : const Color(0XFFF1F4F7),
                        // height: 120,
                        alignment: Alignment.center,
                        child: Text(
                          notes,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode(context)
                                ? Colors.white70
                                : Colors.black,
                            fontFamily: 'Poppinsm',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

Widget _buildChip(String label, int attributesOptionIndex) {
  return Container(
    decoration: BoxDecoration(
        color: const Color(0xffEEEDED), borderRadius: BorderRadius.circular(4)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
        ),
      ),
    ),
  );
}
