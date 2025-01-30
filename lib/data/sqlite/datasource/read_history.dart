part of '../sqlite.dart';

class _BookReadHistoryMapper {
  static final idColumn = "id";
  static final bookIdColumn = "book_id";
  static final dateTimeFromColumn = "date_time_from";
  static final dateTimeToColumn = "date_time_to";
  static final pageFromColumn = "page_from";
  static final pageToColumn = "page_to";

  static Map<String, Object?> toMap(BookReadHistoryEntity entity) =>
      <String, Object?>{
        idColumn: entity.id,
        bookIdColumn: entity.bookId,
        dateTimeFromColumn: entity.dateTimeFrom.toUnixSeconds(),
        dateTimeToColumn: entity.dateTimeTo.toUnixSeconds(),
        pageFromColumn: entity.pageFrom,
        pageToColumn: entity.pageTo
      };

  static BookReadHistoryEntity fromMap(Map<String, Object?> map) =>
      BookReadHistoryEntity(
        id: map[idColumn] as int?,
        bookId: map[bookIdColumn] as int,
        dateTimeFrom: (map[dateTimeFromColumn] as int).unixSecondsToDateTime(),
        dateTimeTo: (map[dateTimeToColumn] as int).unixSecondsToDateTime(),
        pageFrom: map[pageFromColumn] as int,
        pageTo: map[pageToColumn] as int,
      );
}


class BookReadHistoryDataSource extends ChangeNotifier implements BookReadHistoryRepository {
  Database database;

  BookReadHistoryDataSource(this.database);

  @override
  Future<int> add(BookReadHistoryEntity history) async {
    final result = await database.insert(
        _readHistoryTable, _BookReadHistoryMapper.toMap(history),
        conflictAlgorithm: ConflictAlgorithm.fail);
    notifyListeners();
    return result;
  }

  @override
  Future<void> update(BookReadHistoryEntity history) async {
    await database.update(
      _readHistoryTable,
      _BookReadHistoryMapper.toMap(history),
      where: "id = ?",
      whereArgs: [history.id],
    );
    notifyListeners();
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(_readHistoryTable, where: "id = ?", whereArgs: [id]);
    notifyListeners();
  }

  @override
  Future<List<BookReadHistoryEntity>> getAllByBook(int bookId) async {
    final list = await database.query(_readHistoryTable,
        where: "book_id = ?",
        whereArgs: [bookId],
        orderBy: "date_time_from DESC");
    return list.map(_BookReadHistoryMapper.fromMap).toList();
  }

  @override
  Future<BookReadHistoryEntity?> getLastByBook(int bookId) async {
    final row = await database.query(_readHistoryTable,
        where: "book_id = ?",
        whereArgs: [bookId],
        limit: 1,
        orderBy: "date_time_to DESC");
    if (row.isEmpty) return null;
    return _BookReadHistoryMapper.fromMap(row.first);
  }

  @override
  Future<List<BookReadRangeEntity>> getAllMergedByBook(int bookId) async {
    final rows = await database
        .query(_readRangesTable, where: "book_id = ?", whereArgs: [bookId]);
    return rows
        .map((map) => BookReadRangeEntity(
        pageFrom: map["page_from"] as int, pageTo: map["page_to"] as int))
        .toList();
  }

  @override
  Future<BookReadStatistic> getStatistic(
      DateTime fromDay, DateTime toDay) async {
    var fromTime = fromDay.toDateOnly().toUnixSeconds(); // inclusive
    var toTime =
    toDay.toDateOnly().add(Duration(days: 1)).toUnixSeconds(); // exclusive

    final rows = await database.rawQuery("""
SELECT 
  SUM(MIN(date_time_to, ?) - MAX(date_time_from, ?)) AS seconds,
  SUM(page_to - page_from + 1) AS pages,
  COUNT(DISTINCT book_id) AS books
FROM read_histories
WHERE 
  (date_time_from >= ? AND date_time_from < ?) OR
  (date_time_to >= ? AND date_time_to < ?)
""", [toTime, fromTime, fromTime, toTime, fromTime, toTime]);
    int seconds = 0;
    int pages = 0;
    int books = 0;
    if (rows.isNotEmpty) {
      seconds = rows.first["seconds"] as int? ?? 0;
      pages = rows.first["pages"] as int? ?? 0;
      books = rows.first["books"] as int? ?? 0;
    }

    return BookReadStatistic(
      seconds: seconds,
      pages: pages,
      books: books,
    );
  }
}
