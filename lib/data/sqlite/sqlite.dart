import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:readlog/data/repositories.dart';
import 'package:readlog/data/entities.dart';
import 'package:readlog/utils.dart';
import 'package:sqflite/sqflite.dart';

part 'datasource/book.dart';
part 'datasource/collection.dart';
part 'datasource/read_history.dart';

final _bookTable = "books";
final _bookDetailsTable = "book_details";
final _readHistoryTable = "read_histories";
final _readRangesTable = "book_read_ranges";
final _collectionsTable = "collections";

class RepositoryProviderSQLite implements RepositoryProvider {
  late Database db;
  late BookDataSource bookDataSource;
  late BookReadHistoryDataSource bookReadHistoryDataSource;
  late CollectionDataSource collectionDataSource;

  Future<void> open() async {
    final dbPath = join(await getDatabasesPath(), "db");
    db = await openDatabase(dbPath, version: 1,
        onConfigure: (Database db) async {
          db.execute("PRAGMA foreign_keys = ON");
        },
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
    await db.execute("""
CREATE TABLE IF NOT EXISTS collections(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
)
""");
    await db.execute("""
CREATE TABLE IF NOT EXISTS collection_books(
  collection_id INTEGER NOT NULL,
  book_id INTEGER NOT NULL,
  FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (collection_id, book_id)
)
""");
    bookDataSource = BookDataSource(db);
    bookReadHistoryDataSource = BookReadHistoryDataSource(db);
    collectionDataSource = CollectionDataSource(db);
  }

  @override
  BookRepository get books => bookDataSource;

  @override
  BookReadHistoryRepository get readHistories => bookReadHistoryDataSource;

  @override
  CollectionRepository get collections => collectionDataSource;
}
