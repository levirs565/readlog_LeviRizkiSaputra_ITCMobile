import 'package:flutter/foundation.dart';
import 'entities.dart';

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
