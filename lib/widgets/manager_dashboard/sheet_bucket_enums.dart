/// Per-card timestamp source — picks which DateTime field on
/// `ExpenseSheetListItem` to render in the timestamp column.
///
/// Shared by `SheetBucketCard`, `DesktopSheetBucketRow`, `MobileSheetBucketRow`.
enum SheetBucketTimestampSource { submittedAt, reviewedAt }

/// Per-card row-action visual.
///   * `reviewButton` — outlined primary "Review" button.
///   * `viewButton`   — outlined neutral "View" button.
///   * `eyeIcon`      — ghost eye icon (audit / history bucket).
enum SheetBucketActionStyle { reviewButton, viewButton, eyeIcon }
