import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/quote.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'quotes.db');
    return openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quotes (
        id TEXT PRIMARY KEY,
        clientName TEXT,
        clientAddress TEXT,
        clientRef TEXT,
        status TEXT,
        createdAt TEXT,
        taxExclusive INTEGER,
        items TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE quotes ADD COLUMN status TEXT DEFAULT "Draft"');
    }
  }

  Future<void> insertQuote(Quote q) async {
    final database = await db;
    await database.insert(
      'quotes',
      {
        'id': q.id,
        'clientName': q.clientName,
        'clientAddress': q.clientAddress,
        'clientRef': q.clientRef,
        'status': q.status,
        'createdAt': q.createdAt.toIso8601String(),
        'taxExclusive': q.taxExclusive ? 1 : 0,
        'items': jsonEncode(q.items.map((e) => e.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Quote>> fetchAll() async {
    final database = await db;
    final res = await database.query('quotes', orderBy: 'createdAt DESC');
    return res.map((r) {
      final items = (jsonDecode(r['items'] as String) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final m = {
        'id': r['id'],
        'clientName': r['clientName'],
        'clientAddress': r['clientAddress'],
        'clientRef': r['clientRef'],
        'status': r['status'],
        'createdAt': r['createdAt'],
        'taxExclusive': r['taxExclusive'],
        'items': items,
      };
      return Quote.fromDbMap(m);
    }).toList();
  }

  Future<void> deleteQuote(String id) async {
    final database = await db;
    await database.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStatus(String id, String status) async {
    final database = await db;
    await database.update(
      'quotes',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
