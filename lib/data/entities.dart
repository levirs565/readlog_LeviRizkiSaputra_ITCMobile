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
