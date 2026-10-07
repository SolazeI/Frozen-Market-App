import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? toDate(dynamic v) => v is Timestamp ? v.toDate() : null;
double toDouble(dynamic v, [double fallback = 0]) =>
    (v as num?)?.toDouble() ?? fallback;
int toInt(dynamic v, [int fallback = 0]) => (v as num?)?.toInt() ?? fallback;
