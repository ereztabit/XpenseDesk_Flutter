import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_sheet_detail.dart';
import '../models/expense_sheet_list_item.dart';
import '../models/user_info.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

/// Loads the caller's non-finalised expense sheets (Draft + Submitted +
/// Declined). Approved sheets get filtered out at the call site since the
/// employee dashboard doesn't show them.
///
/// Re-fetched on session change. Invalidate after any mutation that may move
/// a sheet between buckets (edit/delete a Declined-bucket expense).
final mySheetsProvider =
    FutureProvider<List<ExpenseSheetListItem>>((ref) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return const [];

  final service = ref.watch(expenseServiceProvider);
  return service.getMySheets();
});

/// Loads the full detail for a single sheet (header + expenses + audit log).
///
/// Family parameter is the `expenseSheetId`. Watch this from the picker's
/// selection; invalidate the family entry after any PUT/DELETE on a Declined
/// sheet so the badge update is visible immediately.
final sheetDetailProvider =
    FutureProvider.family<ExpenseSheetDetail, String>((ref, sheetId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) throw const ExpenseSheetNotFoundException();

  final service = ref.watch(expenseServiceProvider);
  return service.getSheetDetail(sheetId);
});
