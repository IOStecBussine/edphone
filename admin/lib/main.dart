import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EdphoneAdmin());
}

class EdphoneAdmin extends StatelessWidget {
  const EdphoneAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDPHONE ADMIN',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          brightness: Brightness.dark,
        ),
      ),
      home: const AccesoAdmin(),
    );
  }
}

class AccesoAdmin extends StatefulWidget {
  const AccesoAdmin({super.key});

  @override
  State<AccesoAdmin> createState() => _AccesoAdminState();
}

class _AccesoAdminState extends State<AccesoAdmin> {
  final correo = TextEditingController();
  final clave = TextEditingController();
  bool cargando = false;

  Future<void> ingresar() async {
    setState(() => cargando = true);

    try {
      final resultado = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: correo.text.trim(),
        password: clave.text.trim(),
      );

      final uid = resultado.user!.uid;

      final documento = await FirebaseFirestore.instance
          .collection('administradores')
          .doc(uid)
          .get();

      if (!documento.exists || documento.data()?['rol'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Esta cuenta no tiene acceso de administrador.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanelAdmin()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    correo.dispose();
    clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 85, color: azul),
              const SizedBox(height: 15),
              const Text(
                'EDPHONE ADMIN',
                style: TextStyle(
                    fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: clave,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: cargando ? null : ingresar,
                  child: cargando
                      ? const CircularProgressIndicator()
                      : const Text('INGRESAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  Future<void> cambiarEstado(
      String id, String estado) async {
    await FirebaseFirestore.instance
        .collection('reparaciones')
        .doc(id)
        .update({'estado': estado});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDPHONE ADMIN'),
        backgroundColor: tarjeta,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const AccesoAdmin()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reparaciones')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar las reparaciones'));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final reparaciones = snapshot.data!.docs;

          if (reparaciones.isEmpty) {
            return const Center(
                child: Text('Todavía no hay reparaciones.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reparaciones.length,
            itemBuilder: (context, index) {
              final doc = reparaciones[index];
              final datos = doc.data() as Map<String, dynamic>;
              final estado =
                  datos['estado'] ?? 'Pendiente';

              return Card(
                color: tarjeta,
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${datos['marca'] ?? ''} ${datos['modelo'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Cliente: ${datos['cliente'] ?? 'No indicado'}'),
                      Text('Correo: ${datos['correo'] ?? 'No indicado'}'),
                      Text('Problema: ${datos['falla'] ?? 'No indicado'}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Estado de reparación:',
                        style: TextStyle(color: azul),
                      ),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: [
                          'Pendiente',
                          'En reparación',
                          'Terminado'
                        ].contains(estado)
                            ? estado
                            : 'Pendiente',
                        items: const [
                          DropdownMenuItem(
                            value: 'Pendiente',
                            child: Text('Pendiente'),
                          ),
                          DropdownMenuItem(
                            value: 'En reparación',
                            child: Text('En reparación'),
                          ),
                          DropdownMenuItem(
                            value: 'Terminado',
                            child: Text('Terminado'),
                          ),
                        ],
                        onChanged: (nuevoEstado) {
                          if (nuevoEstado != null) {
                            cambiarEstado(doc.id, nuevoEstado);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
