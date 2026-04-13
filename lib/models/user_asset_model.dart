class UserAsset {
  final String id;
  final String assetCode;
  final String name;
  final String status;
  final String purchaseDate;
  final String roomName; // Data dari tabel rooms
  final String? description;

  UserAsset({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.status,
    required this.purchaseDate,
    required this.roomName,
    this.description,
  });

  // Factory method untuk mengubah JSON dari Supabase menjadi Object Flutter
  factory UserAsset.fromJson(Map<String, dynamic> json) {
    return UserAsset(
      id: json['id'] ?? '',
      assetCode: json['asset_code'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? 'available',
      purchaseDate: json['purchase_date'] ?? '',
      // Mengambil room_name dari relasi tabel rooms
      // Supabase mengembalikan relasi dalam bentuk Map/Object nested
      roomName:
          json['rooms'] != null ? json['rooms']['room_name'] : 'Tanpa Ruangan',
      description: json['description'],
    );
  }
}
