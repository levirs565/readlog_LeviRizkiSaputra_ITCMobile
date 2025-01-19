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

abstract interface class BookRepository {
  Future<void> add(BookEntity book);
  Future<void> update(BookEntity book);
  Future<List<BookEntity>> getAll();
  Future<BookEntity?> getById(int id);
  Future<void> delete(int id);
}

abstract interface class RepositoryProvider {
  BookRepository get books;
}
