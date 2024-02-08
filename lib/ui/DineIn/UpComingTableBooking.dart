import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/main.dart';
import 'package:nocstore/services/FirebaseHelper.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/DineIn/BookTableModel.dart';

class UpComingTableBooking extends StatefulWidget {
  const UpComingTableBooking({Key? key}) : super(key: key);

  @override
  State<UpComingTableBooking> createState() => _UpComingTableBookingState();
}

class _UpComingTableBookingState extends State<UpComingTableBooking> {
  final fireStoreUtils = FireStoreUtils();
  Stream<List<BookTableModel>>? upcomingFuture;

  @override
  void initState() {
    upcomingFuture = fireStoreUtils.watchDineOrdersStatus(
        MyAppState.currentUser!.vendorID, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: StreamBuilder<List<BookTableModel>>(
          stream: upcomingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Container(
                child: Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                ),
              );

            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return Center(
                child: showEmptyState(
                    'No Upcoming Booking'.tr(), "Let's book table!".tr()),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  BookTableModel bookTableModel = snapshot.data![index];

                  String bookStatus = '';
                  if (bookTableModel.status == ORDER_STATUS_PLACED) {
                    bookStatus = 'Processing request';
                  } else if (bookTableModel.status == ORDER_STATUS_ACCEPTED) {
                    bookStatus = 'Confirmed';
                  } else if (bookTableModel.status == ORDER_STATUS_REJECTED) {
                    bookStatus = 'Rejected';
                  }

                  return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 10, top: 10),
                      color: isDarkMode(context) ? Color(COLOR_DARK) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        // if you need this
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          bookTableModel.vendor.photo),
                                      fit: BoxFit.cover,
                                      // colorFilter: ColorFilter.mode(
                                      //     Colors.black.withOpacity(0.5), BlendMode.darken),
                                    ),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${bookTableModel.vendor.title}",
                                    style: TextStyle(
                                      fontFamily: "Poppinsssb",
                                      fontSize: 18,
                                      color: Color(0xff000000),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Table Booking Request".tr(),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            child: Text(
                              "Booking Details".tr(),
                              style: TextStyle(
                                fontFamily: "Poppinsssb",
                                fontSize: 16,
                              ),
                            ),
                          ),
                          buildDetails(
                              iconsData: Icons.person_outline,
                              title: 'Name'.tr(),
                              value:
                                  "${bookTableModel.author.firstName} ${bookTableModel.author.lastName}"),
                          buildDetails(
                              iconsData: Icons.phone,
                              title: 'Phone Number'.tr(),
                              value: "${bookTableModel.author.phoneNumber}"),
                          buildDetails(
                              iconsData: Icons.date_range,
                              title: 'Date'.tr(),
                              value:
                                  "${DateFormat("MMM dd, yyyy 'at' hh:mm a").format(bookTableModel.date.toDate())}"),
                          buildDetails(
                              iconsData: Icons.group,
                              title: 'Guest'.tr(),
                              value: "${bookTableModel.totalGuest}"),
                          (bookTableModel.status == ORDER_STATUS_PLACED)
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          child: Container(
                                              padding: EdgeInsets.only(
                                                  top: 8, bottom: 8),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      width: 0.8,
                                                      color: Color(
                                                          COLOR_PRIMARY))),
                                              child: Center(
                                                child: Text(
                                                  'Accept'.tr(),
                                                  style: TextStyle(
                                                      color: isDarkMode(context)
                                                          ? Color(0xffFFFFFF)
                                                          : Color(
                                                              COLOR_PRIMARY),
                                                      fontFamily: "Poppinsm",
                                                      fontSize: 15
                                                      // fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              )),
                                          onTap: () async {
                                            bookTableModel.status =
                                                ORDER_STATUS_ACCEPTED;
                                            await FireStoreUtils
                                                .updateDineInOrder(
                                                    bookTableModel);
                                            Map<String, dynamic> payLoad =
                                                <String, dynamic>{
                                              "type": "dine_in",
                                              "orderId": bookTableModel.id
                                            };
                                            await FireStoreUtils.sendFcmMessage(
                                                dineInAccepted,
                                                bookTableModel.author.fcmToken,
                                                payLoad);
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          child: Container(
                                              padding: EdgeInsets.only(
                                                  top: 8, bottom: 8),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      width: 0.8,
                                                      color: Colors.grey)),
                                              child: Center(
                                                child: Text(
                                                  'Rejected'.tr(),
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontFamily: "Poppinsm",
                                                      fontSize: 15
                                                      // fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              )),
                                          onTap: () async {
                                            bookTableModel.status =
                                                ORDER_STATUS_REJECTED;
                                            await FireStoreUtils
                                                .updateDineInOrder(
                                                    bookTableModel);
                                            Map<String, dynamic> payLoad =
                                                <String, dynamic>{
                                              "type": "dine_in",
                                              "orderId": bookTableModel.id
                                            };
                                            await FireStoreUtils.sendFcmMessage(
                                                dineInCanceled,
                                                bookTableModel.author.fcmToken,
                                                payLoad);
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Center(
                                      child: Text(
                                    '$bookStatus',
                                    style: TextStyle(
                                      letterSpacing: 0.5,
                                      color: (bookStatus == 'Rejected')
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 16,
                                      fontFamily: "Poppinssb",
                                    ),
                                  )),
                                )
                        ],
                      ));
                },
              );
            }
          }),
    );
  }

  buildDetails(
      {required IconData iconsData,
      required String title,
      required String value}) {
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
        style: TextStyle(
            fontSize: 16,
            color: isDarkMode(context) ? Colors.white : Colors.black87),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black54),
      ),
    );
  }
}
