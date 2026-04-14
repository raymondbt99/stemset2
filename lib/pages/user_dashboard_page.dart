import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stemset/models/user_asset_model.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Import library QR

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final supabase = Supabase.instance.client;
  List<UserAsset> myAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndListen();
  }

  void _fetchAndListen() {
    _loadData();

    // Dengar perubahan di tabel assets secara realtime
    supabase
        .channel('public:assets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assets',
          callback: (payload) {
            debugPrint('Ada perubahan data, mengambil ulang...');
            _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('assets')
          .select('id, name, asset_code, status, rooms(room_name)')
          .eq('assigned_to', userId);

      if (mounted) {
        setState(() {
          myAssets =
              (response as List)
                  .map((json) => UserAsset.fromJson(json))
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk menampilkan QR Code Besar saat kartu diklik
  void _showQRDialog(UserAsset asset) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(asset.name, textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Scan kode ini untuk verifikasi aset"),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: asset.assetCode,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  asset.assetCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aset Saya"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : myAssets.isEmpty
              ? const Center(
                child: Text("Tidak ada aset terdaftar atas nama Anda."),
              )
              : ListView.builder(
                itemCount: myAssets.length,
                itemBuilder: (context, index) {
                  final asset = myAssets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap:
                          () =>
                              _showQRDialog(asset), // Klik untuk lihat QR besar
                      leading: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: asset.assetCode,
                          version: QrVersions.auto,
                          size: 45.0,
                        ),
                      ),
                      title: Text(
                        asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Lokasi: ${asset.roomName}"),
                          Text("Kode: ${asset.assetCode}"),
                        ],
                      ),
                      trailing: _buildStatusBadge(asset.status),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        break;
      case 'maintenance':
        color = Colors.orange;
        break;
      case 'broken':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
