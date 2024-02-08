import 'package:nocstore/model/CurrencyModel.dart';
import 'package:nocstore/model/TaxModel.dart';
import 'package:nocstore/model/mail_setting.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const FINISHED_ON_BOARDING = 'finishedOnBoarding';
const COLOR_ACCENT = 0xFFFFFC05;
const COLOR_PRIMARY_DARK = 0xFF2c7305;
const COLOR_DARK = 0xFF191A1C;
var COLOR_PRIMARY = 0xFFFFFC05;
const FACEBOOK_BUTTON_COLOR = 0xFF415893;
const COUPON_BG_COLOR = 0xFFFCF8F3;
const COUPON_DASH_COLOR = 0xFFCACFDA;
const GREY_TEXT_COLOR = 0xff5E5C5C;
const DARK_COLOR = 0xff191A1C;
const DARK_CARD_BG_COLOR = 0xff242528;

const USERS = 'users';
const REPORTS = 'reports';
const STORAGE_ROOT = 'noc';
const VENDORS_CATEGORIES = 'vendor_categories';
const REVIEW_ATTRIBUTES = "review_attributes";

const VENDORS = 'vendors';
const PRODUCTS = 'vendor_products';
const SECTION = 'sections';
const ORDERS = 'vendor_orders';
const COUPONS = "coupons";
const ORDERS_TABLE = 'booked_table';
const FOOD_REVIEW = 'items_review';
const CONTACT_US = 'ContactUs';
const OrderTransaction = "order_transactions";
const VENDOR_ATTRIBUTES = "vendor_attributes";
const BRANDS = "brands";
const Order_Rating = 'items_review';
const STORY = 'story';
const REFERRAL = 'referral';
const dynamicNotification = 'dynamic_notification';
const emailTemplates = 'email_templates';


const SECOND_MILLIS = 1000;
const MINUTE_MILLIS = 60 * SECOND_MILLIS;
const HOUR_MILLIS = 60 * MINUTE_MILLIS;

String SERVER_KEY = 'AAAAYKYVaUA:APA91bGOSiK4mbR5tYbpYlHuS0iElkV5UE3T1QaUzJQbzzX39h87rD9blQIjl9ER0ksBScmIomRO96YtS4ZVjjYDbH3jcFb_a00WzA3OWnKVKiSsuSle24bWHuSZCsQZQjKNDXRZ3WdS';
String GOOGLE_API_KEY = 'AIzaSyAvNwZ_RUaMuDHblwRJBi1QYs8oZQK8xOs';

const ORDER_STATUS_PLACED = 'Order Placed';
const ORDER_STATUS_ACCEPTED = 'Order Accepted';
const ORDER_STATUS_REJECTED = 'Order Rejected';
const ORDER_STATUS_DRIVER_PENDING = 'Driver Pending';
const ORDER_STATUS_DRIVER_ACCEPTED = 'Driver Accepted'; 
const ORDER_STATUS_DRIVER_REJECTED = 'Driver Rejected';
const ORDER_STATUS_SHIPPED = 'Order Shipped';
const ORDER_STATUS_IN_TRANSIT = 'In Transit';
const ORDER_STATUS_COMPLETED = 'Order Completed';


const restaurantAccepted = "restaurant_accepted";
const dineInPlaced = "dinein_placed";
const dineInCanceled = "dinein_canceled";
const dineInAccepted = "dinein_accepted";
const takeawayCompleted = "takeaway_completed";
const orderPlaced = "order_placed";
const restaurantRejected = "restaurant_rejected";
const takeawayShipped = "takeaway_Shipped";
const storeCompleted = "store_completed";
const storeAccepted = "store_accepted";
const storeInTransit = "store_intransit";


const walletTopup = "wallet_topup";
const newVendorSignup = "new_vendor_signup";
const payoutRequestStatus = "payout_request_status";
const payoutRequest = "payout_request";
const newOrderPlaced = "new_order_placed";

const USER_ROLE_VENDOR = 'vendor';

const Currency = 'currencies';


String fileSize = "10";

CurrencyModel? currencyData;
bool isDineInEnable = false;
bool isLanguageShown = false;

const Setting = 'settings';
String placeholderImage = '';

const Wallet = "wallet";
const Payouts = "payouts";
String appVersion = '';


String getFileName(String url) {
  RegExp regExp = new RegExp(r'.+(\/|%2F)(.+)\?.+');
  //This Regex won't work if you remove ?alt...token
  var matches = regExp.allMatches(url);

  var match = matches.elementAt(0);
  print("${Uri.decodeFull(match.group(2)!)}");
  return Uri.decodeFull(match.group(2)!);
}


String amountShow({required String? amount}) {
  if (currencyData!.symbolatright == true) {
    return "${double.parse(amount.toString()).toStringAsFixed(currencyData!.decimal)} ${currencyData!.symbol.toString()}";
  } else {
    return "${currencyData!.symbol.toString()} ${double.parse(amount.toString()).toStringAsFixed(currencyData!.decimal)}";
  }
}
double calculateTax({String? amount, TaxModel? taxModel}) {
  double taxAmount = 0.0;
  if (taxModel != null && taxModel.enable == true) {
    if (taxModel.type == "fix") {
      taxAmount = double.parse(taxModel.tax.toString());
    } else {
      taxAmount = (double.parse(amount.toString()) * double.parse(taxModel.tax!.toString())) / 100;
    }
  }
  return taxAmount;
}

MailSettings? mailSettings;


final smtpServer = SmtpServer(mailSettings!.host.toString(), username: mailSettings!.userName.toString(), password: mailSettings!.password.toString(), port: 465, ignoreBadCertificate: false, ssl: true, allowInsecure: true);

sendMail({String? subject, String? body, bool? isAdmin = false, List<dynamic>? recipients}) async {
  // Create our message.

  print("SENDGMAIL");
  print(isAdmin);
  if(isAdmin == true){
    print("SENDGMAIL11");
    recipients!.add(mailSettings!.userName.toString());
    print(recipients);
  }
  final message = Message()
    ..from = Address(mailSettings!.userName.toString(), mailSettings!.fromName.toString())
    ..recipients = recipients!
    ..subject = subject
    ..text = body
    ..html = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print(e);
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}

