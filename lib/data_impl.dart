import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'data.dart';

class _BookMapper {
  static final idColumn = "id";
  static final titleColumn = "title";
  static final pageCountColumn = "page_count";
  static final readedPageCountColumn = "readed_page_count";

  static Map<String, Object?> toMap(BookEntity entity) => <String, Object?>{
        idColumn: entity.id,
        titleColumn: entity.title,
        pageCountColumn: entity.pageCount,
      };

  static BookEntity fromMap(Map<String, Object?> map) => BookEntity(
        id: map[idColumn] as int?,
        title: map[titleColumn] as String,
        pageCount: map[pageCountColumn] as int,
        readedPageCount: map[readedPageCountColumn] as int? ?? 0,
      );
}

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
        dateTimeFromColumn: entity.dateTimeFrom.millisecondsSinceEpoch ~/ 1000,
        dateTimeToColumn: entity.dateTimeTo.millisecondsSinceEpoch ~/ 1000,
        pageFromColumn: entity.pageFrom,
        pageToColumn: entity.pageTo
      };

  static BookReadHistoryEntity fromMap(Map<String, Object?> map) =>
      BookReadHistoryEntity(
        id: map[idColumn] as int?,
        bookId: map[bookIdColumn] as int,
        dateTimeFrom: DateTime.fromMillisecondsSinceEpoch(
            (map[dateTimeFromColumn] as int) * 1000),
        dateTimeTo: DateTime.fromMillisecondsSinceEpoch(
            (map[dateTimeToColumn] as int) * 1000),
        pageFrom: map[pageFromColumn] as int,
        pageTo: map[pageToColumn] as int,
      );
}

final bookTable = "books";
final bookDetailsTable = "book_details";
final readHistoryTable = "read_histories";
final readRangesTable = "book_read_ranges";

class BookDataSource implements BookRepository {
  Database _db;

  BookDataSource(this._db);

  @override
  Future<int> add(BookEntity book) async {
    return await _db.insert(bookTable, _BookMapper.toMap(book),
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  @override
  Future<void> update(BookEntity book) async {
    await _db.update(bookTable, _BookMapper.toMap(book),
        where: "id = ?", whereArgs: [book.id]);
  }

  @override
  Future<List<BookEntity>> getAll() async {
    var rows = await _db.query(bookDetailsTable);
    return rows.map(_BookMapper.fromMap).toList();
  }

  @override
  Future<BookEntity?> getById(int id) async {
    var rows =
        await _db.query(bookDetailsTable, where: "id = ?", whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _BookMapper.fromMap(rows.first);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete(bookTable, where: "id = ?", whereArgs: [id]);
  }
}

class BookReadHistoryDataSource implements BookReadHistoryRepository {
  Database database;

  BookReadHistoryDataSource(this.database);

  @override
  Future<int> add(BookReadHistoryEntity history) async {
    return await database.insert(
        readHistoryTable, _BookReadHistoryMapper.toMap(history),
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  @override
  Future<void> update(BookReadHistoryEntity history) async {
    await database.update(
      readHistoryTable,
      _BookReadHistoryMapper.toMap(history),
      where: "id = ?",
      whereArgs: [history.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await database.delete(readHistoryTable, where: "id = ?", whereArgs: [id]);
  }

  @override
  Future<List<BookReadHistoryEntity>> getAllByBook(int bookId) async {
    final list = await database.query(readHistoryTable,
        where: "book_id = ?", whereArgs: [bookId], orderBy: "date_time_from DESC");
    return list.map(_BookReadHistoryMapper.fromMap).toList();
  }

  @override
  Future<BookReadHistoryEntity?> getLastByBook(int bookId) async {
    final row = await database.query(readHistoryTable,
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
        .query(readRangesTable, where: "book_id = ?", whereArgs: [bookId]);
    return rows
        .map((map) => BookReadRangeEntity(
            pageFrom: map["page_from"] as int, pageTo: map["page_to"] as int))
        .toList();
  }
}

class RepositoryProviderImpl implements RepositoryProvider {
  late Database db;
  late BookDataSource bookDataSource;
  late BookReadHistoryDataSource bookReadHistoryDataSource;

  Future<void> open() async {
    final dbPath = join(await getDatabasesPath(), "db");
    db = await openDatabase(dbPath, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute("""
CREATE TABLE IF NOT EXISTS books(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  page_count INT NOT NULL
)""");
      await db.execute("""
CREATE TABLE IF NOT EXISTS read_histories(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  date_time_from INTEGER NOT NULL,
  date_time_to INTEGER NOT NULL,
  page_from INTEGER NOT NULL,
  page_to INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE ON UPDATE CASCADE    
)""");
      await db.execute("""
CREATE INDEX read_histories_ranges
ON read_histories(book_id, page_from, page_to)
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_read_ranges AS
WITH RECURSIVE merged AS (
  SELECT 
  	id,
  	book_id,
  	page_from,
  	page_to
  FROM read_histories
  WHERE id = (
  	SELECT id
    FROM read_histories h WHERE h.book_id = read_histories.book_id
 		ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
  UNION ALL
  SELECT 
  	read_histories.id,
  	read_histories.book_id,
  	MAX(merged.page_to + 1, read_histories.page_from) AS page_from,
  	read_histories.page_to as page_to
  FROM read_histories, merged
  WHERE read_histories.id = (
    SELECT id
    FROM read_histories h WHERE h.book_id = merged.book_id AND h.page_to > merged.page_to
    ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
)
SELECT * FROM merged
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_readed_counts AS
WITH RECURSIVE merged AS (
  SELECT 
  	id,
  	book_id,
  	page_from,
  	page_to
  FROM read_histories
  WHERE id = (
  	SELECT id
    FROM read_histories h WHERE h.book_id = read_histories.book_id
 		ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
  UNION ALL
  SELECT 
  	read_histories.id,
  	read_histories.book_id,
  	MAX(merged.page_to + 1, read_histories.page_from) AS page_from,
  	read_histories.page_to as page_to
  FROM read_histories, merged
  WHERE read_histories.id = (
    SELECT id
    FROM read_histories h WHERE h.book_id = merged.book_id AND h.page_to > merged.page_to
    ORDER BY h.page_from, h.page_to
    LIMIT 1
  )
)
SELECT 
	book_id,
  SUM(page_to - page_from + 1) as readed_page_count
FROM merged 
GROUP BY book_id
""");
      await db.execute("""
CREATE VIEW IF NOT EXISTS book_details AS   
SELECT 
  id,
  title,
  page_count,
  readed_page_count
FROM books
LEFT JOIN book_readed_counts
  ON book_readed_counts.book_id = books.id   
""");
    });
    bookDataSource = BookDataSource(db);
    bookReadHistoryDataSource = BookReadHistoryDataSource(db);
  }

  @override
  BookRepository get books => bookDataSource;

  @override
  BookReadHistoryRepository get readHistories => bookReadHistoryDataSource;
}
