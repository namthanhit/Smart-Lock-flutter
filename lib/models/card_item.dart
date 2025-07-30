// lib/models/card_item.dart (Cập nhật file này)
class CardItem {
  final String id;
  String? name; // THAY ĐỔI: tên có thể null
  final String uid; // Giả sử uid vẫn tồn tại, nếu không có, bạn có thể xem xét bỏ nó
  final int addedAt; // THÊM TRƯỜNG addedAt

  CardItem({required this.id, this.name, required this.uid, required this.addedAt}); // Cập nhật constructor

  factory CardItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return CardItem(
      id: id,
      name: map['name'] as String?, // Lấy tên, có thể là null
      uid: map['uid'] as String? ?? 'unknown_uid', // Giả định có uid, nếu không bạn có thể bỏ
      addedAt: map['addedAt'] as int? ?? 0, // Lấy addedAt
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null && name != id) 'name': name, // Chỉ lưu name nếu nó không null và khác id
      'uid': uid, // Giữ uid nếu cần
      'addedAt': addedAt,
      'cardID': id, // Đảm bảo cardID cũng được lưu (thường là key của node)
    };
  }
}