// FS-1026 Receipt AI - column widths that make the tables fit their card.

/// The Profiles table's column widths for [available] width. Name takes the
/// room left (at least [minName]); below 1000px "Last changed" is left out and
/// the rest narrow, so the table fits from a 768px screen up. Actions: 128.
({
  double number,
  double name,
  double status,
  double companies,
  double published,
  double draft,
  double lastChanged,
  bool showLastChanged,
})
aiProfileTableLayout(double available) {
  const actions = 128.0;
  const cardFrame = 10.0; // the table card's margin and border
  final wide = available >= 1000;
  final (number, status, companies, published, draft, lastChanged) = wide
      ? (48.0, 120.0, 100.0, 90.0, 110.0, 170.0)
      : (44.0, 110.0, 84.0, 80.0, 100.0, 0.0);
  final fixed = number + status + companies + published + draft + lastChanged + actions + cardFrame;
  final minName = wide ? 180.0 : 150.0;
  final name = available - fixed > minName ? available - fixed : minName;
  return (
    number: number,
    name: name,
    status: status,
    companies: companies,
    published: published,
    draft: draft,
    lastChanged: lastChanged,
    showLastChanged: wide,
  );
}

/// One column of a Receipt AI table: its width when there is room ([wide]) and
/// when there is not ([compact]); an [optional] column is left out when there
/// is not.
typedef AiFitColumn = ({double wide, double compact, bool optional});

/// Column widths that make a table fit [available], its action column
/// included. Column [flex] takes the room left (at least [minFlex]). When the
/// wide widths leave it less than that, every column goes compact and the
/// optional ones are left out (null). Only below that does the table scroll.
List<double?> aiFitColumns(double available, List<AiFitColumn> columns, {required int flex, required double minFlex}) {
  const cardFrame = 10.0; // the table card's margin and border
  double fixed(bool wide) =>
      cardFrame +
      [
        for (var i = 0; i < columns.length; i++)
          if (i != flex) wide ? columns[i].wide : (columns[i].optional ? 0.0 : columns[i].compact),
      ].fold(0.0, (a, b) => a + b);
  final wide = available - fixed(true) >= minFlex;
  final rest = available - fixed(wide);
  return [
    for (var i = 0; i < columns.length; i++)
      i == flex
          ? (rest > minFlex ? rest : minFlex)
          : wide
          ? columns[i].wide
          : columns[i].optional
          ? null
          : columns[i].compact,
  ];
}

/// The table columns for [labels] at [widths], the left-out ones dropped.
List<({String label, double width})> aiFitTableColumns(List<String> labels, List<double?> widths) => [
  for (var i = 0; i < labels.length; i++)
    if (widths[i] != null) (label: labels[i], width: widths[i]!),
];

/// A row's cells with the left-out columns' cells dropped.
List<T> aiFitCells<T>(List<T> cells, List<double?> widths) => [
  for (var i = 0; i < cells.length; i++)
    if (widths[i] != null) cells[i],
];

/// Usage "By model" / "By profile": the name flexible; "Not reviewed" goes
/// first when tight (it is uploads less verified and corrected).
const List<AiFitColumn> aiUsageTableColumns = [
  (wide: 0, compact: 0, optional: false), // model / profile - flexible
  (wide: 90, compact: 80, optional: false), // uploads
  (wide: 90, compact: 80, optional: false), // verified
  (wide: 90, compact: 90, optional: false), // corrected
  (wide: 110, compact: 0, optional: true), // not reviewed
  (wide: 220, compact: 150, optional: false), // accuracy
  (wide: 56, compact: 56, optional: false), // view scans
];

/// The scan list: the company flexible; profile and model go when tight.
const List<AiFitColumn> aiScanListColumns = [
  (wide: 110, compact: 100, optional: false), // expense date
  (wide: 0, compact: 0, optional: false), // company - flexible
  (wide: 180, compact: 150, optional: false), // merchant
  (wide: 120, compact: 110, optional: false), // amount
  (wide: 160, compact: 0, optional: true), // profile
  (wide: 160, compact: 0, optional: true), // model
  (wide: 130, compact: 120, optional: false), // review
  (wide: 56, compact: 56, optional: false), // open
];

/// Companies: the company flexible; "Since" goes when tight.
const List<AiFitColumn> aiCompaniesTableColumns = [
  (wide: 48, compact: 48, optional: false), // checkbox
  (wide: 0, compact: 0, optional: false), // company - flexible
  (wide: 220, compact: 180, optional: false), // profile
  (wide: 90, compact: 80, optional: false), // version
  (wide: 140, compact: 0, optional: true), // since
  (wide: 110, compact: 90, optional: false), // AI scans
];

/// Versions: the note flexible; "By" goes when tight.
const List<AiFitColumn> aiVersionsTableColumns = [
  (wide: 90, compact: 80, optional: false), // version
  (wide: 120, compact: 110, optional: false), // status
  (wide: 130, compact: 110, optional: false), // source
  (wide: 0, compact: 0, optional: false), // note - flexible
  (wide: 150, compact: 0, optional: true), // by
  (wide: 150, compact: 140, optional: false), // date
  (wide: 56, compact: 56, optional: false), // restore
];
