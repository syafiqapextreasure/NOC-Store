import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/model/CurrencyModel.dart';
import 'package:nocstore/model/OrderModel.dart';
import 'package:nocstore/model/OrderProductModel.dart';
import 'package:nocstore/model/SectionModel.dart';
import 'package:nocstore/model/User.dart';
import 'package:nocstore/model/VendorModel.dart';
import 'package:nocstore/model/variant_info.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/services/pushnotification.dart';
import 'package:nocstore/ui/chat_screen/chat_screen.dart';
import 'package:nocstore/ui/ordersScreen/OrderDetailsScreen.dart';
import 'package:nocstore/ui/reviewScreen.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../services/notification_service.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  FireStoreUtils _fireStoreUtils = FireStoreUtils();
  late Stream<List<OrderModel>> ordersStream;

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // final audioPlayer = AudioPlayer(playerId: "playerId");

  @override
  void initState() {
    super.initState();
    setCurrency();
    ordersStream = _fireStoreUtils.watchOrdersStatus(MyAppState.currentUser!.vendorID);
    getVendor();
    final pushNotificationService = PushNotificationService(_firebaseMessaging);
    pushNotificationService.initialise();
  }

  VendorModel? vendorData;
  SectionModel? selectedModel;

  getVendor() async {
    if (MyAppState.currentUser!.vendorID.isNotEmpty) {
      await FireStoreUtils.getVendor(MyAppState.currentUser!.vendorID)?.then((value) {
        setState(() {
          vendorData = value;
        });
      });

      await FireStoreUtils.getSections().then((value) {
        value.forEach((element) {
          if (element.id == vendorData!.section_id) {
            setState(() {
              selectedModel = element;
            });
          }
        });
      });
    }
  }

  bool isLoading = true;

  setCurrency() async {
    /* await FireStoreUtils().getCurrency().then((value) {
      for (var element in value) {
        if (element.isactive = true) {
          setState(() {
            currencyData = element;
          });
        }
      }
    });*/
    await FireStoreUtils().getCurrency().then((value) {
      if (value != null) {
        currencyData = value;
      } else {
        currencyData = CurrencyModel(
            id: "",
            code: "USD",
            decimal: 2,
            isactive: true,
            name: "US Dollar",
            symbol: "\$",
            symbolatright: false);
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _fireStoreUtils.closeOrdersStream();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? Color(COLOR_DARK) : Color(0XFFFFFFFF),
        body: SingleChildScrollView(
            child: isLoading == true
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<List<OrderModel>>(
                    stream: ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Container(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      print(snapshot.data!.length.toString() + "-----L");
                      if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                        return Center(
                          child: showEmptyState(
                              'No Orders'.tr(), 'New order requests will show up here'.tr()),
                        );
                      } else {
                        // for(int a=0;a<snapshot.data!.length;a++){
                        //   // print("====TOKEN===${a}===="+snapshot.data![a].author!.fcmToken);
                        // }
                        return ListView.builder(
                            shrinkWrap: true,
                            physics: ClampingScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            padding:
                                const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                            itemBuilder: (context, index) => InkWell(
                                onTap: () async {
                                  if (isPlaying) {
                                    stopSound();
                                  }
                                  await audioPlayer.stop();

                                  push(
                                      context,
                                      OrderDetailsScreen(
                                        orderModel: snapshot.data![index],
                                      ));
                                },
                                child: buildOrderItem(snapshot.data![index], index,
                                    (index != 0) ? snapshot.data![index - 1] : null)));
                      }
                    })));
  }

  Widget buildTableOrderItem() {
    return Card(
        elevation: 3,
        margin: EdgeInsets.only(bottom: 10, top: 10),
        color: isDarkMode(context) ? Color(COLOR_DARK) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // if you need this
          side: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://images.unsplash.com/photo-1646064121471-b58da3df0866?crop=entropy&cs=tinysrgb&fm=jpg&ixlib=rb-1.2.1&q=80&raw_url=true&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=387"),
                      fit: BoxFit.cover,
                      // colorFilter: ColorFilter.mode(
                      //     Colors.black.withOpacity(0.5), BlendMode.darken),
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vogito snacks bar",
                      style: TextStyle(
                        fontFamily: "Poppinssm",
                        fontSize: 18,
                        color: Color(0xff000000),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "91,Parker St. Aleansto US",
                        style: TextStyle(
                          fontFamily: "Poppinssm",
                          color: Color(GREY_TEXT_COLOR),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Text("Booking Details".tr()),
            ),
            buildDetails(iconsData: Icons.person_outline, title: 'Name', value: "Metadata"),
            buildDetails(iconsData: Icons.phone, title: 'Phone Number', value: "+91 1234567890"),
            buildDetails(
                iconsData: Icons.date_range, title: 'Date', value: "May 23 ,2020 at 6:30 PM"),
            buildDetails(iconsData: Icons.group, title: 'Guest', value: "5"),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      child: Container(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(width: 0.8, color: Color(COLOR_PRIMARY))),
                          child: Center(
                            child: Text(
                              'Accept'.tr(),
                              style: TextStyle(
                                  color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                  fontFamily: "Poppinsm",
                                  fontSize: 15
                                  // fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )),
                      onTap: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      child: Container(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(width: 0.8, color: Colors.grey)),
                          child: Center(
                            child: Text(
                              'Rejected'.tr(),
                              style:
                                  TextStyle(color: Colors.grey, fontFamily: "Poppinsm", fontSize: 15
                                      // fontWeight: FontWeight.bold,
                                      ),
                            ),
                          )),
                      onTap: () {
                        if (isPlaying) {
                          stopSound();
                        }
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }

  Widget buildOrderItem(OrderModel orderModel, int index, OrderModel? prevModel) {
    double total = 0.0;
    total = 0.0;
    double specialDiscount = 0.0;
    String extrasDisVal = '';
    print(orderModel.status);
    if (orderModel.status == ORDER_STATUS_PLACED) {
      if (!isPlaying) {
        playSound();
      }
    }
    orderModel.products.forEach((element) {
      // if (orderModel.status == ORDER_STATUS_PLACED) {
      //   playSound();
      // }

      try {
        if (element.extras_price!.isNotEmpty && double.parse(element.extras_price!) != 0.0) {
          total += element.quantity * double.parse(element.extras_price!);
        }
        total += element.quantity * double.parse(element.price);
        List addOnVal = [];
        if (element.extras == null) {
          addOnVal.clear();
        } else {
          if (element.extras is String) {
            if (element.extras == '[]') {
              addOnVal.clear();
            } else {
              String extraDecode = element.extras
                  .toString()
                  .replaceAll("[", "")
                  .replaceAll("]", "")
                  .replaceAll("\"", "");
              if (extraDecode.contains(",")) {
                addOnVal = extraDecode.split(",");
              } else {
                if (extraDecode.trim().isNotEmpty) {
                  addOnVal = [extraDecode];
                }
              }
            }
          }
          if (element.extras is List) {
            addOnVal = List.from(element.extras);
          }
        }

        for (int i = 0; i < addOnVal.length; i++) {
          extrasDisVal +=
              '${addOnVal[i].toString().replaceAll("\"", "")} ${(i == addOnVal.length - 1) ? "" : ","}';
        }
      } catch (ex) {}
    });

    print("order data ${(orderModel.id)}");
    // log("extra add on ${(orderModel.author!.firstName + ' ' + orderModel.author!.lastName)}  id is ${orderModel.id}");
    // if(orderModel.deliveryCharge!=null && orderModel.deliveryCharge!.isNotEmpty){
    //   total+=double.parse(orderModel.deliveryCharge!);
    // }

    String date = DateFormat(' MMM d yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(orderModel.createdAt.millisecondsSinceEpoch));
    String date2 = "";
    if (prevModel != null) {
      date2 = DateFormat(' MMM d yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(prevModel.createdAt.millisecondsSinceEpoch));
    }

    if (orderModel.specialDiscount != null ||
        orderModel.specialDiscount!['special_discount'] != null) {
      specialDiscount = double.parse(orderModel.specialDiscount!['special_discount'].toString());
    }

    var totalamount = total - orderModel.discount! - specialDiscount;

    double adminComm = (orderModel.adminCommissionType == 'Percent')
        ? (totalamount * double.parse(orderModel.adminCommission!)) / 100
        : double.parse(orderModel.adminCommission!);

    print("cond1 ${(index == 0)} cond 2 ${(index != 0 && prevModel != null && date != date2)}");
    return Column(
      children: [
        // ElevatedButton(
        //     onPressed: () async {
        //       log('Got a message whilst in the foreground!');
        //       try {
        //         // final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        //         AndroidNotificationChannel channel = const AndroidNotificationChannel(
        //           "01",
        //           "emart_store",
        //           description: 'Show NOC Notification',
        //           importance: Importance.max,
        //         );
        //         AndroidNotificationDetails notificationDetails = AndroidNotificationDetails(
        //             channel.id, channel.name,
        //             channelDescription: 'your channel Description',
        //             importance: Importance.high,
        //             priority: Priority.high,
        //             ticker: 'ticker');
        //         const DarwinNotificationDetails darwinNotificationDetails =
        //             DarwinNotificationDetails(
        //                 presentAlert: true, presentBadge: true, presentSound: true);
        //         NotificationDetails notificationDetailsBoth = NotificationDetails(
        //             android: notificationDetails, iOS: darwinNotificationDetails);
        //         await FlutterLocalNotificationsPlugin().show(
        //           0,
        //           "message.notification!.title",
        //           "message.notification!.body",
        //           notificationDetailsBoth,
        //           // payload: jsonEncode(message.data),
        //         );
        //       } on Exception catch (e) {
        //         log(e.toString());
        //       }
        //     },
        //     child: Text("data notification test")),
        Visibility(
          visible: index == 0 || (index != 0 && prevModel != null && date != date2),
          child: Wrap(children: [
            Container(
              height: 50.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDarkMode(context) ? Colors.white : Colors.grey,
              ),
              alignment: Alignment.center,
              child: Text(
                '$date',
                style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode(context) ? Color(0XFF000000) : Colors.white,
                    letterSpacing: 0.5,
                    fontFamily: 'Poppinsm'),
              ),
            )
          ]),
        ),
        Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 10, top: 10),
            color: isDarkMode(context) ? Color(COLOR_DARK) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // if you need this
              side: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(bottom: 10.0, top: 5),
              child: Column(
                children: [
                  Container(
                      padding: EdgeInsets.only(left: 10),
                      child: Row(children: [
                        Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(orderModel.products.first.photo),
                                fit: BoxFit.cover,
                                // colorFilter: ColorFilter.mode(
                                //     Colors.black.withOpacity(0.5), BlendMode.darken),
                              ),
                            )),
                        SizedBox(
                          width: 10,
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                orderModel.author.firstName + ' ' + orderModel.author.lastName,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode(context) ? Colors.white : Color(0XFF000000),
                                    letterSpacing: 0.5,
                                    fontFamily: 'Poppinsm'),
                              ),
                              SizedBox(
                                height: 7,
                              ),
                              orderModel.takeAway!
                                  ? Text(
                                      'Takeaway'.tr(),
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: isDarkMode(context)
                                              ? Colors.white
                                              : Color(0XFF555353),
                                          letterSpacing: 0.5,
                                          fontFamily: 'Poppinsl'),
                                    )
                                  : Row(children: [
                                      Icon(Icons.location_pin, size: 17, color: Colors.grey),
                                      SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        'Deliver to:'.tr(),
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Color(0XFF555353),
                                            letterSpacing: 0.5,
                                            fontFamily: 'Poppinsl'),
                                      ),
                                    ]),
                              orderModel.takeAway!
                                  ? Container()
                                  : Container(
                                      padding: EdgeInsets.only(bottom: 8),
                                      constraints: BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        '${orderModel.deliveryAddress()}',
                                        maxLines: 1,
                                        style: TextStyle(
                                            color: isDarkMode(context)
                                                ? Colors.white
                                                : Color(0XFF555353),
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                            fontFamily: 'Poppinsr'),
                                      ),
                                    ),
                            ])
                      ])),
                  // SizedBox(height: 10,),
                  Divider(
                    color: Color(0XFFD7DDE7),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ORDER LIST'.tr(),
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0XFF9091A4),
                          letterSpacing: 0.5,
                          fontFamily: 'Poppinsm'),
                    ),
                  ),

                  ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: orderModel.products.length,
                      padding: EdgeInsets.only(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        OrderProductModel product = orderModel.products[index];
                        VariantInfo? variantIno = product.variant_info;
                        List<dynamic>? addon = product.extras;
                        String extrasDisVal = '';
                        for (int i = 0; i < addon!.length; i++) {
                          extrasDisVal +=
                              '${addon[i].toString().replaceAll("\"", "")} ${(i == addon.length - 1) ? "" : ","}';
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              minLeadingWidth: 10,
                              contentPadding: EdgeInsets.only(left: 10, right: 10),
                              visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                              leading: CircleAvatar(
                                radius: 13,
                                backgroundColor: Color(0xFFFEDF00),
                                child: Text(
                                  '${product.quantity}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: TextStyle(
                                    color: isDarkMode(context) ? Colors.white : Color(0XFF333333),
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Poppinsr'),
                              ),
                              trailing: Text(
                                amountShow(
                                    amount: double.parse((product.extras_price!.isNotEmpty &&
                                                double.parse(product.extras_price!) != 0.0)
                                            ? (double.parse(product.extras_price!) +
                                                    double.parse(product.price))
                                                .toString()
                                            : product.price)
                                        .toString()),
                                style: TextStyle(
                                    color: isDarkMode(context)
                                        ? Colors.grey.shade200
                                        : Color(0XFF333333),
                                    fontSize: 17,
                                    letterSpacing: 0.5,
                                    fontFamily: 'Poppinssm'),
                              ),
                            ),
                            variantIno == null || variantIno.variant_options!.isEmpty
                                ? Container()
                                : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
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
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 5, right: 10),
                              child: extrasDisVal.isEmpty
                                  ? Container()
                                  : Text(
                                      extrasDisVal,
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey, fontFamily: 'Poppinsr'),
                                    ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(child: Container()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      elevation: 0.0,
                                      padding: EdgeInsets.all(8),
                                      side: BorderSide(color: Color(0xFFFEDF00), width: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(2),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      push(
                                          context,
                                          ReviewScreen(
                                            product: product,
                                            orderId: orderModel.id,
                                          ));
                                    },
                                    child: Text(
                                      'View Rating'.tr(),
                                      style: TextStyle(
                                          letterSpacing: 0.5,
                                          color: Colors.black,
                                          fontFamily: 'Poppinsm'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),

                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      padding: EdgeInsets.only(bottom: 8, top: 8, left: 10, right: 10),
                      color: isDarkMode(context) ? null : Color(0XFFF4F4F5),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          orderModel.scheduleTime != null
                              ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(
                                    'Schedule Time'.tr(),
                                    style: TextStyle(
                                        color:
                                            isDarkMode(context) ? Colors.white : Color(0XFF333333),
                                        letterSpacing: 0.5,
                                        fontFamily: 'Poppinsr'),
                                  ),
                                  Text(
                                    '${DateFormat("EEE dd MMMM , HH:mm aa").format(orderModel.scheduleTime!.toDate())}',
                                    style: TextStyle(
                                        color: Color(COLOR_PRIMARY), fontFamily: 'Poppinssm'),
                                  ),
                                ])
                              : Container(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(
                              'Order Total'.tr(),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: isDarkMode(context) ? Colors.white : Color(0XFF333333),
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppinsr'),
                            ),
                            Text(
                              amountShow(amount: total.toString()),
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppinssm'),
                            ),
                          ]),
                          SizedBox(
                            height: 5,
                          ),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(
                              'Admin commission'.tr(),
                              style: TextStyle(
                                  color: isDarkMode(context) ? Colors.white : Color(0XFF333333),
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppinsr'),
                            ),
                            Text(
                              "(-${amountShow(amount: adminComm.toString())})",
                              style: TextStyle(
                                  color: Colors.red, letterSpacing: 0.5, fontFamily: 'Poppinssm'),
                            ),
                          ])
                        ],
                      )),

                  orderModel.notes!.isEmpty
                      ? Container()
                      : SizedBox(
                          height: 10,
                        ),
                  orderModel.notes!.isEmpty
                      ? Container()
                      : Container(
                          padding: EdgeInsets.only(bottom: 8, top: 8, left: 10, right: 10),
                          color: isDarkMode(context) ? null : Colors.white,
                          alignment: Alignment.centerLeft,
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(
                              'Remark'.tr(),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: isDarkMode(context) ? Colors.white : Color(0XFF333333),
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppinsr'),
                            ),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    isDismissible: true,
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    enableDrag: true,
                                    builder: (BuildContext context) =>
                                        viewNotesheet(orderModel.notes!));
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
                          ])),
                  Container(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (orderModel.status == ORDER_STATUS_PLACED &&
                              selectedModel?.serviceTypeFlag == "ecommerce-service")
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  elevation: 0.0,
                                  padding: EdgeInsets.all(8),
                                  side: BorderSide(color: Color(COLOR_PRIMARY), width: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (isPlaying) {
                                    stopSound();
                                  }
                                  audioPlayer.stop();
                                  _displayTextInputDialog(context, orderModel);

                                  // orderModel.status = ORDER_STATUS_IN_TRANSIT;
                                  // FireStoreUtils.updateOrder(orderModel);
                                  // FireStoreUtils.sendFcmMessage(
                                  //     "Your Order has Shipped".tr(), '${orderModel.vendor.title}' + ' ' + 'has Shipped Your Order'.tr(), orderModel.author!.fcmToken);
                                  //
                                  // if (orderModel.status == ORDER_STATUS_PLACED && !orderModel.takeAway!) {
                                  //   FireStoreUtils.sendFcmMessage("New Delivery!".tr(), 'New Delivery Request'.tr(), orderModel.driver!.fcmToken);
                                  // }
                                  // setState(() {});
                                },
                                child: Text(
                                  'Shipped order'.tr(),
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      color:
                                          isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                      fontFamily: 'Poppinsm'),
                                ),
                              ),
                            ),
                          if (orderModel.status == ORDER_STATUS_IN_TRANSIT &&
                              selectedModel?.serviceTypeFlag == "ecommerce-service")
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0.0,
                                  padding: EdgeInsets.all(8),
                                  side: BorderSide(color: Color(COLOR_PRIMARY), width: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  orderModel.status = ORDER_STATUS_COMPLETED;
                                  // updateWallateAmountEcommarce(orderModel);
                                  await FireStoreUtils().updateWallateAmountEcommarce(orderModel);
                                  await FireStoreUtils.updateOrder(orderModel);
                                  Map<String, dynamic> payLoad = <String, dynamic>{
                                    "type": "vendor_order",
                                    "orderId": orderModel.id
                                  };
                                  await FireStoreUtils.sendFcmMessage(
                                      storeCompleted, orderModel.author.fcmToken, payLoad);

                                  await FireStoreUtils.getFirestOrderOrNOt(orderModel)
                                      .then((value) async {
                                    print("isExit----->$value");
                                    if (value == true) {
                                      await FireStoreUtils.updateReferralAmount(orderModel);
                                    }
                                  });

                                  setState(() {});
                                },
                                child: Text(
                                  'Complete Order'.tr(),
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      color:
                                          isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                      fontFamily: 'Poppinsm'),
                                ),
                              ),
                            ),
                          if (orderModel.status == ORDER_STATUS_PLACED &&
                              selectedModel?.serviceTypeFlag != "ecommerce-service")
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Color(0xFFFEDF00),
                                  elevation: 0.0,
                                  padding: EdgeInsets.all(8),
                                  side: BorderSide(color: Colors.black, width: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  if (isPlaying) {
                                    stopSound();
                                  }
                                  await audioPlayer.stop();

                                  if (orderModel.scheduleTime != null) {
                                    if (orderModel.scheduleTime!
                                        .toDate()
                                        .isBefore(Timestamp.now().toDate())) {
                                      print("ok");
                                      if ((selectedModel != null &&
                                          selectedModel!.dineInActive == true)) {
                                        await _displayTextInputEstimatedTimeDialog(
                                            context, orderModel);
                                      } else {
                                        showProgress(context, 'Please wait...', false);
                                        orderModel.status = ORDER_STATUS_ACCEPTED;
                                        await FireStoreUtils.updateOrder(orderModel);
                                        await FireStoreUtils()
                                            .restaurantVendorWalletSet(orderModel);
                                        Map<String, dynamic> payLoad = <String, dynamic>{
                                          "type": "vendor_order",
                                          "orderId": orderModel.id
                                        };
                                        await FireStoreUtils.sendFcmMessage(restaurantAccepted,
                                            orderModel.author.fcmToken, payLoad);
                                        hideProgress();
                                      }
                                    } else {
                                      final snackBar = SnackBar(
                                        content: Text(
                                                '${"You can accept order on".tr()} ${DateFormat("EEE dd MMMM , HH:mm a").format(orderModel.scheduleTime!.toDate())}.')
                                            .tr(),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                    }
                                  } else {
                                    if ((selectedModel != null &&
                                        selectedModel!.dineInActive == true)) {
                                      await _displayTextInputEstimatedTimeDialog(
                                          context, orderModel);
                                    } else {
                                      showProgress(context, 'Please wait...', false);
                                      orderModel.status = ORDER_STATUS_ACCEPTED;
                                      await FireStoreUtils.updateOrder(orderModel);
                                      await FireStoreUtils().restaurantVendorWalletSet(orderModel);
                                      Map<String, dynamic> payLoad = <String, dynamic>{
                                        "type": "vendor_order",
                                        "orderId": orderModel.id
                                      };
                                      await FireStoreUtils.sendFcmMessage(
                                          restaurantAccepted, orderModel.author.fcmToken, payLoad);
                                      hideProgress();
                                    }
                                  }

                                  // orderModel.status = ORDER_STATUS_ACCEPTED;
                                  //  FireStoreUtils.updateOrder(orderModel);
                                  //  await FireStoreUtils().restaurantVendorWalletSet(orderModel);
                                  //  FireStoreUtils.sendFcmMessage("Your Order has Accepted".tr(), '${orderModel.vendor.title}' + ' ' + 'has Accept Your Order'.tr(), orderModel.author.fcmToken);
                                  //
                                  //  if (orderModel.status == ORDER_STATUS_PLACED && !orderModel.takeAway!) {
                                  //    FireStoreUtils.sendFcmMessage("New Delivery!".tr(), 'New Delivery Request'.tr(), orderModel.driver!.fcmToken);
                                  //  }
                                  setState(() {});
                                },
                                child: Text(
                                  'ACCEPT'.tr(),
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      color:
                                      Colors.black,
                                      fontFamily: 'Poppinsm'),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: 20,
                          ),
                          if (orderModel.status == ORDER_STATUS_PLACED &&
                              selectedModel?.serviceTypeFlag != "ecommerce-service")
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  elevation: 0.0,
                                  padding: EdgeInsets.all(8),
                                  side: BorderSide(color: isDarkMode(context) ? Colors.white.withOpacity(0.9) : Color(0XFF63605F), width: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  if (isPlaying) {
                                    stopSound();
                                  }
                                  audioPlayer.stop();
                                  orderModel.status = ORDER_STATUS_REJECTED;
                                  await FireStoreUtils.updateOrder(orderModel);
                                  Map<String, dynamic> payLoad = <String, dynamic>{
                                    "type": "vendor_order",
                                    "orderId": orderModel.id
                                  };
                                  await FireStoreUtils.sendFcmMessage(
                                      restaurantRejected, orderModel.author.fcmToken, payLoad);
                                  if (orderModel.payment_method.toLowerCase() != 'cod') {
                                    FireStoreUtils.createPaymentId().then((value) {
                                      final paymentID = value;
                                      FireStoreUtils.topUpWalletAmount(
                                              paymentMethod: "Refund Amount".tr(),
                                              userId: orderModel.author.userID,
                                              amount: total.toDouble(),
                                              id: paymentID)
                                          .then((value) {
                                        FireStoreUtils.updateWalletAmount(
                                                userId: orderModel.author.userID,
                                                amount: total.toDouble())
                                            .then((value) {});
                                      });
                                    });
                                  }

                                  setState(() {});
                                },
                                child: Text(
                                  'REJECT'.tr(),
                                  style: TextStyle(
                                      letterSpacing: 0.5,
                                      color: isDarkMode(context) ? Colors.white.withOpacity(0.9) : Color(0XFF63605F),
                                      fontFamily: 'Poppinsm'),
                                ),
                              ),
                            ),
                          //if (orderModel.status == ORDER_STATUS_COMPLETED)
                          // PrintTicket(orderModel: orderModel),
                          if (orderModel.status != ORDER_STATUS_PLACED &&
                              !orderModel.takeAway! &&
                              selectedModel?.serviceTypeFlag != "ecommerce-service")
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(6),
                                    ),
                                  ),
                                  side: BorderSide(
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                ),
                                onPressed: () => null,
                                child: Text(
                                  '${orderModel.status}'.tr(),
                                  style: TextStyle(
                                    color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          orderModel.status == ORDER_STATUS_ACCEPTED && orderModel.takeAway!
                              ? Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      orderModel.status = ORDER_STATUS_COMPLETED;
                                      await FireStoreUtils.updateOrder(orderModel);
                                      //updateWallateAmount(orderModel);
                                      Map<String, dynamic> payLoad = <String, dynamic>{
                                        "type": "vendor_order",
                                        "orderId": orderModel.id
                                      };
                                      await FireStoreUtils.sendFcmMessage(
                                          takeawayCompleted, orderModel.author.fcmToken, payLoad);
                                    },
                                    child: Container(
                                        width: MediaQuery.of(context).size.width * 0.4,
                                        // height: 50,
                                        padding:
                                            EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
                                        // primary: Colors.white,

                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(
                                                width: 0.8, color: Color(COLOR_PRIMARY))),
                                        child: Text(
                                          'Delivered'.tr().toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                              fontFamily: "Poppinsm",
                                              fontSize: 15
                                              // fontWeight: FontWeight.bold,
                                              ),
                                        )),
                                  ),
                                )
                              : orderModel.status == ORDER_STATUS_COMPLETED && orderModel.takeAway!
                                  ? Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.all(16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(6),
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: Color(COLOR_PRIMARY),
                                          ),
                                        ),
                                        onPressed: () => null,
                                        child: Text(
                                          '${orderModel.status}'.tr(),
                                          style: TextStyle(
                                            color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                          ),
                                        ),
                                      ),
                                    )
                                  : orderModel.status == ORDER_STATUS_REJECTED &&
                                          orderModel.takeAway!
                                      ? Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.all(16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(6),
                                                ),
                                              ),
                                              side: BorderSide(
                                                color: Color(COLOR_PRIMARY),
                                              ),
                                            ),
                                            onPressed: () => null,
                                            child: Text(
                                              '${orderModel.status}'.tr(),
                                              style: TextStyle(
                                                color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(),
                          Visibility(
                              visible: orderModel.status == ORDER_STATUS_ACCEPTED ||
                                  orderModel.status == ORDER_STATUS_SHIPPED ||
                                  orderModel.status == ORDER_STATUS_DRIVER_PENDING ||
                                  orderModel.status == ORDER_STATUS_DRIVER_REJECTED ||
                                  orderModel.status == ORDER_STATUS_IN_TRANSIT ||
                                  orderModel.status == ORDER_STATUS_SHIPPED,
                              child: Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: InkWell(
                                  onTap: () async {
                                    await showProgress(context, "Please wait".tr(), false);

                                    User? customer =
                                        await FireStoreUtils.getCurrentUser(orderModel.authorID);
                                    User? restaurantUser = await FireStoreUtils.getCurrentUser(
                                        orderModel.vendor.author);
                                    VendorModel? vendorModel = await FireStoreUtils.getVendor(
                                        restaurantUser!.vendorID.toString());

                                    hideProgress();
                                    push(
                                        context,
                                        ChatScreens(
                                          type: "vendor_chat",
                                          customerName:
                                              '${customer!.firstName + " " + customer.lastName}',
                                          restaurantName: vendorModel!.title,
                                          orderId: orderModel.id,
                                          restaurantId: restaurantUser.userID,
                                          customerId: customer.userID,
                                          customerProfileImage: customer.profilePictureURL,
                                          restaurantProfileImage: vendorModel.photo,
                                          token: customer.fcmToken,
                                        ));
                                  },
                                  child: Image(
                                    image: AssetImage("assets/images/user_chat.png"),
                                    height: 30,
                                    color: Color(COLOR_PRIMARY),
                                    width: 30,
                                  ),
                                ),
                              ))
                        ],
                      )),
                ],
              ),
            )),
      ],
    );
  }

  final estimatedTime = TextEditingController();

  viewNotesheet(String notes) {
    return Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 4.3, left: 25, right: 25),
        height: MediaQuery.of(context).size.height * 0.88,
        decoration:
            BoxDecoration(color: Colors.transparent, border: Border.all(style: BorderStyle.none)),
        child: Column(children: [
          InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 0.3),
                    color: Colors.transparent,
                    shape: BoxShape.circle),

                // radius: 20,
                child: Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )),
          SizedBox(
            height: 25,
          ),
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDarkMode(context) ? Color(COLOR_DARK) : Colors.white),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'Remark'.tr(),
                        style: TextStyle(
                            fontFamily: 'Poppinssb',
                            color: isDarkMode(context) ? Colors.white60 : Colors.white,
                            fontSize: 16),
                      )),
                  Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                      // height: 120,
                      child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: Container(
                              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
                              color: isDarkMode(context) ? Color(0XFF2A2A2A) : Color(0XFFF1F4F7),
                              // height: 120,
                              alignment: Alignment.center,
                              child: Text(
                                notes,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDarkMode(context) ? Colors.white60 : Colors.black,
                                  fontFamily: 'Poppinsm',
                                ),
                              )))),
                ],
              ),
            ),
          )),
        ]));
  }

  buildDetails({required IconData iconsData, required String title, required String value}) {
    return ListTile(
      enabled: false,
      dense: true,
      contentPadding: EdgeInsets.only(left: 8),
      horizontalTitleGap: 0.0,
      visualDensity: VisualDensity.comfortable,
      leading: Icon(
        iconsData,
        color: isDarkMode(context) ? Colors.white : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: isDarkMode(context) ? Colors.white : Colors.black87),
      ),
      subtitle: Text(
        value,
        style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black54),
      ),
    );
  }
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  void stopSound() {
    audioPlayer.stop();
    setState(() {
      isPlaying = false;
    });
  }
  playSound() async {
    final path = await rootBundle.load("assets/audio/mixkit-happy-bells-notification-937.mp3");

    audioPlayer.setSourceBytes(path.buffer.asUint8List());
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    //audioPlayer.setSourceUrl(url);
    audioPlayer.play(BytesSource(path.buffer.asUint8List()),
        volume: 15,
        ctx: AudioContext(
            android: AudioContextAndroid(
                contentType: AndroidContentType.music,
                isSpeakerphoneOn: true,
                stayAwake: true,
                usageType: AndroidUsageType.alarm,
                audioFocus: AndroidAudioFocus.gainTransient),
            iOS: AudioContextIOS(category: AVAudioSessionCategory.playback, options: [])));
  }

  final courierCompanyName = TextEditingController();
  final trackingId = TextEditingController();

  Future<void> _displayTextInputDialog(BuildContext context, OrderModel orderModel) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add Shipping Details').tr(),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courierCompanyName,
                  decoration: InputDecoration(hintText: "Courier Company Name"),
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: trackingId,
                  decoration: InputDecoration(hintText: "Tracking Id".tr()),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          elevation: 0.0,
                          padding: EdgeInsets.all(8),
                          side: BorderSide(color: Color(COLOR_PRIMARY), width: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(2),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel'.tr(),
                          style: TextStyle(
                              letterSpacing: 0.5,
                              color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                              fontFamily: 'Poppinsm'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          elevation: 0.0,
                          padding: EdgeInsets.all(8),
                          side: BorderSide(color: Color(COLOR_PRIMARY), width: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(2),
                            ),
                          ),
                        ),
                        onPressed: () async {
                          if (courierCompanyName.text.isNotEmpty && trackingId.text.isNotEmpty) {
                            orderModel.status = ORDER_STATUS_IN_TRANSIT;
                            orderModel.courierCompanyName = courierCompanyName.text;
                            orderModel.courierTrackingId = trackingId.text;
                            await FireStoreUtils.updateOrder(orderModel);
                            Map<String, dynamic> payLoad = <String, dynamic>{
                              "type": "vendor_order",
                              "orderId": orderModel.id
                            };
                            await FireStoreUtils.sendFcmMessage(
                                storeInTransit, orderModel.author.fcmToken, payLoad);

                            courierCompanyName.clear();
                            trackingId.clear();
                            Navigator.pop(context);
                            setState(() {});
                          } else {
                            // showAlertDialog(context, "Alert!".tr(), "", true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter details.'.tr(),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Shipped order'.tr(),
                          style: TextStyle(
                              letterSpacing: 0.5,
                              color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                              fontFamily: 'Poppinsm'),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  Future<void> _displayTextInputEstimatedTimeDialog(
      BuildContext context, OrderModel orderModel) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Estimated time to Prepare'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: estimatedTime,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MaskedInputFormatter('##:##')],
                  decoration: InputDecoration(
                    fillColor: Color(0xFFFEDF00),
                      filled: true,
                      hintText: "00:00",
                      contentPadding: EdgeInsets.symmetric(horizontal: 6),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 0.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFEDF00), width: 0.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 0.0),
                      ),
                      prefixIcon: Icon(
                        Icons.access_time,
                        color: Colors.black
                      )),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          elevation: 0.0,
                          padding: EdgeInsets.all(8),
                          backgroundColor: Color(0xFFFEDF00),
                          side: BorderSide(color: Colors.black, width: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(2),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel'.tr(),
                          style: TextStyle(
                              letterSpacing: 0.5,
                              color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                              fontFamily: 'Poppinsm'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          elevation: 0.0,
                          padding: EdgeInsets.all(8),
                          backgroundColor: Color(0xFFFEDF00),
                          side: BorderSide(color: Colors.black, width: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(2),
                            ),
                          ),
                        ),
                        onPressed: () async {
                          print(estimatedTime.text);
                          if (estimatedTime.text.isNotEmpty) {
                            showProgress(context, 'Please wait...', false);

                            orderModel.estimatedTimeToPrepare = estimatedTime.text;
                            orderModel.status = ORDER_STATUS_ACCEPTED;
                            await FireStoreUtils.updateOrder(orderModel);
                            await FireStoreUtils().restaurantVendorWalletSet(orderModel);
                            Map<String, dynamic> payLoad = <String, dynamic>{
                              "type": "vendor_order",
                              "orderId": orderModel.id
                            };
                            await FireStoreUtils.sendFcmMessage(
                                restaurantAccepted, orderModel.author.fcmToken, payLoad);
                            hideProgress();
                            Navigator.pop(context);
                            setState(() {});
                          } else {
                            //showAlertDialog(context, "Alert!".tr(), "", true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter details.'.tr(),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Shipped order'.tr(),
                          style: TextStyle(
                              letterSpacing: 0.5,
                              color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black,
                              fontFamily: 'Poppinsm'),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }
}

class PrintTicket extends StatefulWidget {
  final OrderModel orderModel;

  const PrintTicket({Key? key, required this.orderModel}) : super(key: key);

  @override
  State<PrintTicket> createState() => PrintTicketState();
}

class PrintTicketState extends State<PrintTicket> {
  double total = 0.0;
  var discount;

  @override
  void initState() {
    // TODO: implement initState
    widget.orderModel.products.forEach((element) {
      if (element.extras_price != null &&
          element.extras_price!.isNotEmpty &&
          double.parse(element.extras_price!) != 0.0) {
        total += element.quantity * double.parse(element.extras_price!);
      }
      total += element.quantity * double.parse(element.price);

      discount = widget.orderModel.discount;
    });

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(6),
            ),
          ),
          side: BorderSide(
            color: Color(COLOR_PRIMARY),
          ),
        ),
        onPressed: () => printTicket(),
        child: Text(
          'Print Invoice'.tr(),
          style: TextStyle(
            color: Color(COLOR_PRIMARY),
          ),
        ),
      ),
    );
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    print(isConnected);
    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      log(bytes.toString());
      String base64Image = base64Encode(bytes);

      log(base64Image.toString());

      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      if (result == "true") {
        showAlertDialog(context, "Successfully".tr(), "Invoice print successfully".tr(), true);
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
    bytes += generator.text('Tel:'.tr() + ' ${widget.orderModel.vendor.phonenumber}',
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'No'.tr(), width: 1, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Item'.tr(), width: 7, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Qty'.tr(), width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
      PosColumn(
          text: 'Total'.tr(), width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    List<OrderProductModel> products = widget.orderModel.products;
    for (int i = 0; i < products.length; i++) {
      bytes += generator.row([
        PosColumn(text: (i + 1).toString(), width: 1),
        PosColumn(
            text: products[i].name,
            width: 7,
            styles: const PosStyles(
              align: PosAlign.left,
            )),
        PosColumn(
            text: products[i].quantity.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: products[i].price.toString(),
            width: 2,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'Subtotal'.tr(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: total.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Discount'.tr(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: discount.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Delivery charges'.tr(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: widget.orderModel.deliveryCharge == null
              ? amountShow(amount: "0.0")
              : amountShow(amount: widget.orderModel.deliveryCharge!),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Tip Amount'.tr(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: widget.orderModel.tipValue!.isEmpty
              ? currencyData!.symbol + "0.0"
              : currencyData!.symbol + widget.orderModel.tipValue!,
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          //text: widget.orderModel.taxModel!.tax_lable ?? "10",
          text: "Tax",
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text:
              // symbol + ((widget.orderModel.taxModel == null) ? "0" : getTaxValue(widget.orderModel.taxModel, total - discount).toString()),
              //   widget.orderModel.taxModel == null ? amountShow(amount: "0") : amountShow(amount: getTaxValue(widget.orderModel.taxModel, total - discount).toString()),
              taxAmount.toString(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    if (widget.orderModel.notes != null && widget.orderModel.notes!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(
            text: "Remark".tr(),
            width: 6,
            styles: const PosStyles(
              align: PosAlign.left,
              height: PosTextSize.size4,
              width: PosTextSize.size4,
            )),
        PosColumn(
            text: widget.orderModel.notes!,
            width: 6,
            styles: const PosStyles(
              align: PosAlign.right,
              height: PosTextSize.size4,
              width: PosTextSize.size4,
            )),
      ]);
    }
    double tipValue =
        widget.orderModel.tipValue!.isEmpty ? 0.0 : double.parse(widget.orderModel.tipValue!);
    // taxAmount = (widget.orderModel.taxModel == null) ? 0 : getTaxValue(widget.orderModel.taxModel, total - discount);

    if (widget.orderModel.taxModel != null) {
      for (var element in widget.orderModel.taxModel!) {
        taxAmount = (double.parse(taxAmount) +
                calculateTax(amount: (total - discount).toString(), taxModel: element))
            .toString();
      }
    }

    var totalamount =
        widget.orderModel.deliveryCharge == null || widget.orderModel.deliveryCharge!.isEmpty
            ? total + double.parse(taxAmount) - discount
            : total +
                double.parse(taxAmount) +
                double.parse(widget.orderModel.deliveryCharge!) +
                tipValue -
                discount;

    bytes += generator.row([
      PosColumn(
          text: 'Order Total'.tr(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
      PosColumn(
          text: totalamount.toDouble().toStringAsFixed(currencyData!.decimal),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            height: PosTextSize.size4,
            width: PosTextSize.size4,
          )),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);
    // ticket.feed(2);
    bytes +=
        generator.text('Thank you!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.cut();

    return bytes;
  }

  List availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetooths");
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
            child: availableBluetoothDevices.isEmpty
                ? Center(child: Text("connect-from-setting".tr()))
                : ListView.builder(
                    itemCount: availableBluetoothDevices.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          String select = availableBluetoothDevices[index];
                          List list = select.split("#");
                          // String name = list[0];
                          String mac = list[1];
                          setConnect(mac);
                        },
                        title: Text('${availableBluetoothDevices[index]}'),
                        subtitle: Text("Click to connect".tr()),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> setConnect(String mac) async {
    // final String? result = await BluetoothThermalPrinter.connect(mac);
    // print("state connected $result");
    // if (result == "true") {
    //   printTicket();
    // }
    // print("djjd 1");
    try {
      printTicket();
      final String? result = await BluetoothThermalPrinter.connect(mac);
      BluetoothThermalPrinter.connect(mac).catchError((error) {
        print(error.toString());
        log(error.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Done!!")));
      printTicket();
      print("state connected $result");
      if (result == "true") {
        printTicket();
      }
    } catch (e) {
      print(e.toString());
      print("dod 1");
    }
  }
}

Widget _buildChip(String label, int attributesOptionIndex) {
  return Container(
    decoration:
        BoxDecoration(color: const Color(0xffEEEDED), borderRadius: BorderRadius.circular(4)),
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
