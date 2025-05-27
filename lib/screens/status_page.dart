import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'dart:async';

class StatusPage extends StatefulWidget {
  final String username;

  const StatusPage({super.key, required this.username});

  @override
  State<StatusPage> createState() => StatusPageState();
}

class StatusPageState extends State<StatusPage> {
  final bool _isLoading = false;
  List<Map<String, dynamic>> _statusUpdates = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();

    // Set up a periodic timer to refresh every 3 seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fetchStatusUpdates(); // Correctly reference the method to fetch updates
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchStatusUpdates() async {
    final supabase = Supabase.instance.client;

    try {
      final data = await supabase
          .from('status_updates')
          .select()
          .order('updated_at', ascending: false);

      setState(() {
        _statusUpdates =
            List<Map<String, dynamic>>.from(
              data,
            ).where((update) => update['username'] == widget.username).toList();
      });
    } catch (error) {
      debugPrint('Error fetching status updates: $error');
    }
  }

  void _setupRealtimeUpdates() {
    final supabase = Supabase.instance.client;

    supabase
        .from('status_updates')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .listen((data) {
          setState(() {
            _statusUpdates = List<Map<String, dynamic>>.from(data);
          });
        });
  }

  void fetchStatusManually() {
    _setupRealtimeUpdates();
  }

  void _logout() async {
    try {
      await Supabase.instance.client.auth
          .signOut(); // Ensure sign-out is awaited
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                items: [
                  PopupMenuItem(
                    value: 'username',
                    child: Text('Username: ${widget.username}'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
              ).then((value) {
                if (value == 'logout') {
                  _logout();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Phone: 8973416296', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _statusUpdates.isEmpty
                      ? const Center(
                        child: Text(
                          'No updates available.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _statusUpdates.length,
                        itemBuilder: (context, index) {
                          final update = _statusUpdates[index];
                          final formattedDate = DateFormat(
                            'yyyy-MM-dd – kk:mm',
                          ).format(DateTime.parse(update['updated_at']));
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 8.0,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  update['status_message'] ?? 'No message',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'By: ${update['username']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'At: $formattedDate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
