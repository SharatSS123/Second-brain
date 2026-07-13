import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class ChecklistsRepository {
  final AppDatabase _db;
  ChecklistsRepository(this._db);
  static const _uuid = Uuid();

  // Watch checklists ordered by creation date (newest first)
  Stream<List<Checklist>> watchAll() {
    return (_db.select(_db.checklistsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // Add checklist
  Future<void> add({required String name, String? iconKey, String type = 'my_lists'}) async {
    final id = _uuid.v4();
    await _db.into(_db.checklistsTable).insert(
          ChecklistsTableCompanion.insert(
            id: id,
            name: name,
            iconKey: Value(iconKey),
            type: Value(type),
          ),
        );
  }

  // Update checklist name
  Future<void> updateName(String id, String name) {
    return (_db.update(_db.checklistsTable)..where((t) => t.id.equals(id)))
        .write(ChecklistsTableCompanion(name: Value(name)));
  }

  // Update checklist icon and type
  Future<void> updateIconAndType(String id, String? iconKey, String type) {
    return (_db.update(_db.checklistsTable)..where((t) => t.id.equals(id)))
        .write(ChecklistsTableCompanion(
      iconKey: Value(iconKey),
      type: Value(type),
    ));
  }

  // Delete checklist and all checklist items associated with it
  Future<void> delete(String id) async {
    await (_db.delete(_db.checklistItemsTable)..where((t) => t.checklistId.equals(id))).go();
    await (_db.delete(_db.checklistsTable)..where((t) => t.id.equals(id))).go();
  }

  // Items for checklist (ordered by sort order)
  Stream<List<ChecklistItem>> watchItems(String checklistId) {
    return (_db.select(_db.checklistItemsTable)
          ..where((t) => t.checklistId.equals(checklistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  // Add checklist item AT THE TOP of the list
  Future<void> addItem({required String checklistId, required String title}) async {
    final id = _uuid.v4();
    
    // Retrieve existing items
    final existing = await (_db.select(_db.checklistItemsTable)
          ..where((t) => t.checklistId.equals(checklistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    
    // Shift all existing items' sortOrder by 1
    await _db.transaction(() async {
      for (final item in existing) {
        await (_db.update(_db.checklistItemsTable)..where((t) => t.id.equals(item.id)))
            .write(ChecklistItemsTableCompanion(sortOrder: Value(item.sortOrder + 1)));
      }
      
      // Insert the new item at sortOrder = 0 (top)
      await _db.into(_db.checklistItemsTable).insert(
            ChecklistItemsTableCompanion.insert(
              id: id,
              checklistId: checklistId,
              title: title,
              sortOrder: const Value(0),
            ),
          );
    });
  }

  // Toggle checklist item checked status
  Future<void> toggleItem(String id, bool currentStatus) {
    return (_db.update(_db.checklistItemsTable)..where((t) => t.id.equals(id)))
        .write(ChecklistItemsTableCompanion(isChecked: Value(!currentStatus)));
  }

  // Update checklist item title
  Future<void> updateItemTitle(String id, String title) {
    return (_db.update(_db.checklistItemsTable)..where((t) => t.id.equals(id)))
        .write(ChecklistItemsTableCompanion(title: Value(title)));
  }

  // Update complete checklist item details (title, notes, priority, dueDate)
  Future<void> updateItem({
    required String id,
    required String title,
    String? notes,
    String? priority,
    DateTime? dueDate,
  }) {
    return (_db.update(_db.checklistItemsTable)..where((t) => t.id.equals(id)))
        .write(ChecklistItemsTableCompanion(
      title: Value(title),
      notes: Value(notes),
      priority: Value(priority),
      dueDate: Value(dueDate),
    ));
  }

  // Delete checklist item
  Future<void> deleteItem(String id) {
    return (_db.delete(_db.checklistItemsTable)..where((t) => t.id.equals(id))).go();
  }

  // Clear completed checklist items
  Future<void> clearCompleted(String checklistId) async {
    await (_db.delete(_db.checklistItemsTable)
          ..where((t) => t.checklistId.equals(checklistId) & t.isChecked.equals(true)))
        .go();
  }

  // Update items sort order
  Future<void> updateItemsOrder(List<ChecklistItem> items) async {
    await _db.transaction(() async {
      for (int i = 0; i < items.length; i++) {
        await (_db.update(_db.checklistItemsTable)..where((t) => t.id.equals(items[i].id)))
            .write(ChecklistItemsTableCompanion(sortOrder: Value(i)));
      }
    });
  }

  // Move item to top
  Future<void> moveItemToTop(String checklistId, String itemId) async {
    final items = await (_db.select(_db.checklistItemsTable)
          ..where((t) => t.checklistId.equals(checklistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    
    final idx = items.indexWhere((t) => t.id == itemId);
    if (idx <= 0) return;
    
    final item = items.removeAt(idx);
    items.insert(0, item);
    await updateItemsOrder(items);
  }

  // Move item to bottom
  Future<void> moveItemToBottom(String checklistId, String itemId) async {
    final items = await (_db.select(_db.checklistItemsTable)
          ..where((t) => t.checklistId.equals(checklistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    
    final idx = items.indexWhere((t) => t.id == itemId);
    if (idx == -1 || idx == items.length - 1) return;
    
    final item = items.removeAt(idx);
    items.add(item);
    await updateItemsOrder(items);
  }

  // Seed default checklists (Shopping & Travel) with 2 items each
  Future<void> seedDefaults() async {
    final existing = await _db.select(_db.checklistsTable).get();
    if (existing.isNotEmpty) return;

    // Seed Shopping Checklist
    final shoppingId = _uuid.v4();
    await _db.into(_db.checklistsTable).insert(
          ChecklistsTableCompanion.insert(
            id: shoppingId,
            name: 'Shopping 🛒',
            iconKey: const Value('shopping_cart'),
            type: const Value('my_lists'),
          ),
        );
    await _db.into(_db.checklistItemsTable).insert(
          ChecklistItemsTableCompanion.insert(
            id: _uuid.v4(),
            checklistId: shoppingId,
            title: 'Milk 🥛',
            sortOrder: const Value(0),
          ),
        );
    await _db.into(_db.checklistItemsTable).insert(
          ChecklistItemsTableCompanion.insert(
            id: _uuid.v4(),
            checklistId: shoppingId,
            title: 'Eggs 🥚',
            sortOrder: const Value(1),
          ),
        );

    // Seed Travel Checklist
    final travelId = _uuid.v4();
    await _db.into(_db.checklistsTable).insert(
          ChecklistsTableCompanion.insert(
            id: travelId,
            name: 'Travel ✈️',
            iconKey: const Value('flight'),
            type: const Value('my_lists'),
          ),
        );
    await _db.into(_db.checklistItemsTable).insert(
          ChecklistItemsTableCompanion.insert(
            id: _uuid.v4(),
            checklistId: travelId,
            title: 'Passport 🛂',
            sortOrder: const Value(0),
          ),
        );
    await _db.into(_db.checklistItemsTable).insert(
          ChecklistItemsTableCompanion.insert(
            id: _uuid.v4(),
            checklistId: travelId,
            title: 'Charger 🔌',
            sortOrder: const Value(1),
          ),
        );
  }
}
