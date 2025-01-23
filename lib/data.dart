class BookEntity {
  final int? id;
  final String title;
  final int pageCount;
  final int readedPageCount;

  const BookEntity(
      {this.id,
      required this.title,
      required this.pageCount,
      required this.readedPageCount});
}

class BookReadHistoryEntity {
  final int? id;
  final int bookId;
  final DateTime dateTimeFrom, dateTimeTo;
  final int pageFrom, pageTo;

  const BookReadHistoryEntity(
      {this.id,
      required this.bookId,
      required this.dateTimeFrom,
      required this.dateTimeTo,
      required this.pageFrom,
      required this.pageTo});
}

class BookReadRangeEntity {
  final int pageFrom, pageTo;

  const BookReadRangeEntity({required this.pageFrom, required this.pageTo});
}

abstract interface class BookRepository {
  Future<int> add(BookEntity book);

  Future<void> update(BookEntity book);

  Future<List<BookEntity>> getAll();

  Future<BookEntity?> getById(int id);

  Future<void> delete(int id);
}

abstract interface class BookReadHistoryRepository {
  Future<int> add(BookReadHistoryEntity history);

  Future<void> update(BookReadHistoryEntity history);

  Future<List<BookReadHistoryEntity>> getAllByBook(int bookId);

  Future<List<BookReadRangeEntity>> getAllMergedByBook(int bookId);

  Future<BookReadHistoryEntity?> getLastByBook(int bookId);

  Future<void> delete(int id);
}

abstract interface class RepositoryProvider {
  BookRepository get books;

  BookReadHistoryRepository get readHistories;
}
