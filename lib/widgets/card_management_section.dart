// lib/widgets/card_management_section.dart
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/firebase_service.dart';

class CardManagementSection extends StatefulWidget {
  const CardManagementSection({super.key});

  @override
  State<CardManagementSection> createState() => _CardManagementSectionState();
}

class _CardManagementSectionState extends State<CardManagementSection> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _nameController = TextEditingController();

  // THÊM BIẾN NÀY ĐỂ KIỂM SOÁT HIỆU ỨNG LOADING
  List<CardItem> _currentCards = []; // Giữ dữ liệu thẻ hiện tại để hiển thị trong khi chờ update
  bool _isLoadingInitial = true; // Chỉ loading ban đầu

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showRenameDialog(BuildContext context, CardItem card) async {
    _nameController.text = card.name ?? '';

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi tên thẻ ${card.id.substring(0, 5)}...'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Nhập tên mới cho thẻ'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _nameController.text);
              _nameController.clear();
            },
            child: const Text('Đổi tên'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != card.name) {
      try {
        await _firebaseService.updateCardName(card.id, newName);
        _showSnackBar(context, 'Đã cập nhật tên thẻ thành "$newName"');
      } catch (e) {
        _showSnackBar(context, 'Lỗi khi đổi tên thẻ: $e', isError: true);
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, CardItem card) async {
    final String displayName = card.name ?? card.id;
    final bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa thẻ'),
        content: Text('Bạn có chắc chắn muốn xóa thẻ "$displayName" (${card.id.substring(0, 5)}...)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      try {
        await _firebaseService.deleteCard(card.id);
        _showSnackBar(context, 'Đã xóa thẻ "$displayName"');
      } catch (e) {
        _showSnackBar(context, 'Lỗi khi xóa thẻ: $e', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quản lý Thẻ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const Divider(height: 24),
            StreamBuilder<List<CardItem>>(
              stream: _firebaseService.getCardsStream(),
              builder: (context, snapshot) {
                // Cập nhật _isLoadingInitial và _currentCards dựa trên snapshot
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Chỉ hiển thị loading indicator nếu đây là lần tải ban đầu và chưa có dữ liệu
                  if (_currentCards.isEmpty && _isLoadingInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Nếu đã có dữ liệu, hoặc không phải lần tải ban đầu, hiển thị dữ liệu cũ
                  // và tránh hiển thị spinner
                  // FALL-THROUGH TO DISPLAY _currentCards
                } else if (snapshot.hasError) {
                  _isLoadingInitial = false; // Đã cố gắng tải, không còn là "initial loading"
                  return Center(child: Text('Lỗi tải thẻ: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  _isLoadingInitial = false; // Đã tải xong dữ liệu lần đầu
                  _currentCards = snapshot.data!; // Cập nhật dữ liệu thẻ
                }

                // Luôn hiển thị dữ liệu từ _currentCards (hoặc dữ liệu mới nhất nếu có)
                if (_currentCards.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Chưa có thẻ nào được thêm.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentCards.length,
                  itemBuilder: (context, index) {
                    final card = _currentCards[index]; // Sử dụng _currentCards
                    final String displayName = card.name ?? card.id;
                    return Card(
                      key: ValueKey(card.id), // THÊM KEY ĐỂ TỐI ƯU HIỆU SUẤT LISTVIEW
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.nfc, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'ID: ${card.id}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Thêm lúc: ${DateTime.fromMillisecondsSinceEpoch(card.addedAt * 1000).toLocal().toString().split('.')[0]}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showRenameDialog(context, card),
                              tooltip: 'Đổi tên thẻ',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(context, card),
                              tooltip: 'Xóa thẻ',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}