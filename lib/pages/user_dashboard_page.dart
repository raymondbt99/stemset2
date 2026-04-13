import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stemset/models/user_asset_model.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final supabase = Supabase.instance.client;
  List<UserAsset> myAssets = [];

  @override
  void initState() {
    super.initState();
    _fetchAndListen();
  }

  void _fetchAndListen() {
    // 1. Ambil data awal (termasuk join nama ruangan)
    _loadData();

    // 2. Dengar perubahan di tabel assets secara realtime
    supabase
        .channel('public:assets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'assets',
          callback: (payload) {
            print('Ada perubahan data, mengambil ulang...');
            _loadData(); // Panggil ulang fungsi load data
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('assets')
        .select('id, name, asset_code, status, rooms(room_name)')
        .eq('assigned_to', userId);

    if (mounted) {
      setState(() {
        myAssets =
            (response as List).map((json) => UserAsset.fromJson(json)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aset Saya")),
      body:
          myAssets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: myAssets.length,
                itemBuilder:
                    (context, index) => Card(
                      child: ListTile(
                        title: Text(myAssets[index].name),
                        subtitle: Text(myAssets[index].roomName),
                        trailing: Text(myAssets[index].status),
                      ),
                    ),
              ),
    );
  }
}
