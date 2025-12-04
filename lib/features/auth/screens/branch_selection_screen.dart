import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BranchSelectionScreen extends StatefulWidget {
  final List<dynamic> userBranches; // could be empty, 1, or many
  const BranchSelectionScreen({super.key, required this.userBranches});

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  bool loading = true;
  List<Map<String, dynamic>> branches = [];

  @override
  void initState() {
    super.initState();
    loadBranches();
  }

  Future<void> loadBranches() async {
    QuerySnapshot snap;

    if (widget.userBranches.isEmpty) {
      // User has no assigned branches → show all
      snap = await FirebaseFirestore.instance.collection('branches').get();
    } else {
      // Only show assigned branches
      snap = await FirebaseFirestore.instance
          .collection('branches')
          .where(FieldPath.documentId, whereIn: widget.userBranches)
          .get();
    }

    branches = snap.docs
        .map(
          (d) => {
            'id': d.id,
            'name': d['name'],
            'address': d['address'],
            'phone': d['phone'],
          },
        )
        .toList();

    setState(() => loading = false);
  }

  Future<void> selectBranch(Map<String, dynamic> branch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeBranchId', branch['id']);
    await prefs.setString('activeBranchName', branch['name']);

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Cabang"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: branches.length,
              itemBuilder: (_, i) {
                final b = branches[i];
                return Card(
                  child: ListTile(
                    title: Text(b['name']),
                    subtitle: Text("${b['address']}\n${b['phone']}"),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => selectBranch(b),
                  ),
                );
              },
            ),
    );
  }
}
