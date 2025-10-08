import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
// Add additional imports in a real app: firebase_database, google_maps_flutter, razorpay_flutter, firebase_messaging

// NOTE: For a real app, follow the Firebase console steps to register Android/iOS apps and download config files.
// This is a compact example demonstrating flows: sign-in, fetch drivers, create booking request with backend.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Hiring - Starter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignInPage(),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String _error = '';

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()
      );
      final idToken = await userCred.user!.getIdToken();
      // Upsert user profile on backend
      final resp = await http.post(
        Uri.parse('http://localhost:4000/api/auth/upsert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken'
        },
        body: jsonEncode({ 'name': userCred.user!.displayName ?? '', 'phone': userCred.user!.phoneNumber ?? '' })
      );
      if (resp.statusCode == 200) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(idToken: idToken)));
      } else {
        setState(() { _error = 'Backend upsert failed: ' + resp.body; });
      }
    } catch (e) {
      setState(() { _error = 'Sign-in error: ' + e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _signIn, child: _loading ? const CircularProgressIndicator() : const Text('Sign in')),
            if (_error.isNotEmpty) Padding(padding: const EdgeInsets.all(8.0), child: Text(_error, style: const TextStyle(color: Colors.red)))
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String idToken;
  const HomePage({required this.idToken, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List drivers = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() { loading = true; });
    final resp = await http.get(
      Uri.parse('http://localhost:4000/api/drivers?available=true'),
      headers: { 'Authorization': 'Bearer ${widget.idToken}' }
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      setState(() { drivers = data['drivers'] ?? []; });
    } else {
      // handle error
    }
    setState(() { loading = false; });
  }

  Future<void> _hireDriver(int driverId) async {
    final resp = await http.post(Uri.parse('http://localhost:4000/api/bookings'),
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.idToken}' },
      body: jsonEncode({ 'driver_id': driverId, 'amount': 1000 })
    );
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      // If order returned, you can call Razorpay checkout via razorpay_flutter (not included in this compact sample)
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Booked'), content: Text('Booking id: ' + json['bookingId'].toString())));
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Error'), content: Text(resp.body)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Drivers')),
      body: loading ? const Center(child:CircularProgressIndicator()) : ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (_, i) {
          final d = drivers[i];
          return ListTile(
            title: Text(d['name'] ?? 'Unnamed'),
            subtitle: Text('${d['vehicle_type'] ?? ''} · ${d['experience_years'] ?? 0} yrs'),
            trailing: ElevatedButton(onPressed: () => _hireDriver(d['id']), child: const Text('Hire')),
          );
        }
      ),
    );
  }
}
