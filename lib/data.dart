import 'package:flutter/foundation.dart';

class BookEntity {
  final int? id;
  final String title;
  final int pageCount;
  final int readedPageCount;

  double get readPercentage =>
      readedPageCount.toDouble() / pageCount.toDouble();

  const BookEntity({
    this.id,
    required this.title,
    required this.pageCount,
    required this.readedPageCount,
  });
}

class BookDetailEntity extends BookEntity {
  final List<CollectionEntity> collections;

  BookDetailEntity({required BookEntity book, required this.collections})
      : super(
          id: book.id,
          title: book.title,
          pageCount: book.pageCount,
          readedPageCount: book.readedPageCount,
        );
}

class CollectionEntity {
  final int? id;
  final String name;

  const CollectionEntity({
    this.id,
    required this.name,
  });

  CollectionEntity copy() => CollectionEntity(id: id, name: name);
}

class BookReadHistoryEntity {
  final int? id;
  final int bookId;
  final DateTime dateTimeFrom, dateTimeTo;
  final int pageFrom, pageTo;

  const BookReadHistoryEntity({
    this.id,
    required this.bookId,
    required this.dateTimeFrom,
    required this.dateTimeTo,
    required this.pageFrom,
    required this.pageTo,
  });
}

class BookReadRangeEntity {
  final int pageFrom, pageTo;

  const BookReadRangeEntity({required this.pageFrom, required this.pageTo});
}

class BookReadStatistic {
  final int seconds;
  final int pages;
  final int books;

  const BookReadStatistic({required this.seconds, required this.pages, required this.books});
}

abstract interface class BookRepository implements Listenable {
  Future<int> add(BookDetailEntity book);

  Future<void> update(BookDetailEntity book);

  Future<List<BookEntity>> getAll();

  Future<BookDetailEntity?> getById(int id);

  Future<List<BookEntity>> getAllByCollection(int collectionId);

  Future<void> delete(int id);
}

abstract interface class BookReadHistoryRepository implements Listenable {
  Future<int> add(BookReadHistoryEntity history);

  Future<void> update(BookReadHistoryEntity history);

  Future<List<BookReadHistoryEntity>> getAllByBook(int bookId);

  Future<List<BookReadRangeEntity>> getAllMergedByBook(int bookId);

  Future<BookReadHistoryEntity?> getLastByBook(int bookId);

  Future<void> delete(int id);

  Future<BookReadStatistic> getStatistic(DateTime fromDay, DateTime toDay);
}

abstract interface class CollectionRepository implements Listenable {
  Future<int> add(CollectionEntity collection);

  Future<CollectionEntity?> getById(int id);

  Future<void> update(CollectionEntity collection);

  Future<List<CollectionEntity>> getAll();

  Future<void> delete(int id);
}

abstract interface class RepositoryProvider {
  BookRepository get books;

  BookReadHistoryRepository get readHistories;

  CollectionRepository get collections;
}
