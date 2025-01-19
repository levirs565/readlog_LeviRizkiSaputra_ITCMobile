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

final bookTable = "books";
final bookDetailsTable = "book_details";

class BookDataSource implements BookRepository {
  Database _db;

  BookDataSource(this._db);

  @override
  Future<void> add(BookEntity book) async {
    await _db.insert(bookTable, _BookMapper.toMap(book), conflictAlgorithm: ConflictAlgorithm.fail);
  }

  @override
  Future<void> update(BookEntity book) async {
    await _db.update(bookTable, _BookMapper.toMap(book), where: "id = ?", whereArgs: [book.id]);
  }

  @override
  Future<List<BookEntity>> getAll() async {
    var rows = await _db.query(bookDetailsTable);
    return rows.map(_BookMapper.fromMap).toList();
  }

  @override
  Future<BookEntity?> getById(int id) async {
    var rows = await _db.query(bookDetailsTable, where: "id = ?", whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _BookMapper.fromMap(rows.first);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete(bookTable, where: "id = ?", whereArgs: [id]);
  }
}

class RepositoryProviderImpl implements RepositoryProvider {
  late Database db;
  late BookDataSource bookDataSource;

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
  page_from INTEGER NOT NULL,
  page_to INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE ON UPDATE CASCADE    
)""");
      await db.execute("""
CREATE INDEX read_histories_ranges
ON read_histories(book_id, page_from, page_to)
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
  }

  @override
  BookRepository get books => bookDataSource;
}
