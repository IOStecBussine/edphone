import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';

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

      final admin = await FirebaseFirestore.instance
          .collection('administradores')
          .doc(uid)
          .get();

      if (!admin.exists || admin.data()?['rol'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Esta cuenta no tiene permiso de administrador.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PanelAdmin(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: azul, size: 85),
              const SizedBox(height: 15),
              const Text(
                'EDPHONE ADMIN',
                style: TextStyle(
                  color: azul,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: clave,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
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
class PanelAdmin extends StatefulWidget {
  const PanelAdmin({super.key});

  @override
  State<PanelAdmin> createState() => _PanelAdminState();
}

class _PanelAdminState extends State<PanelAdmin> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> avisarCliente(
    Map<String, dynamic> datos,
    String reparacionId,
  ) async {
    final uid = (datos['uid'] ?? '').toString();

    if (uid.isEmpty) {
      mostrarMensaje('La reparación no tiene UID del cliente.');
      return;
    }

    const titulo = '¡Tu reparación está terminada!';
    final marca = datos['marca'] ?? '';
    final modelo = datos['modelo'] ?? '';
    final mensaje = 'Tu equipo $marca $modelo está listo para retirar.';

    try {
      // Primero guarda el aviso dentro de EDPHONE.
      await db
          .collection('notificaciones')
          .doc(uid)
          .collection('avisos')
          .add({
        'titulo': titulo,
        'mensaje': mensaje,
        'reparacionId': reparacionId,
        'fecha': FieldValue.serverTimestamp(),
        'leida': false,
      });

      // Después solicita el envío de la notificación externa.
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception('No hay una sesión de administrador activa.');
      }

      final token = await usuario.getIdToken(true);

      final cliente = HttpClient();
      final solicitud = await cliente.postUrl(
        Uri.parse(
          'https://edphone-notificaciones.edmilsonbogado39.workers.dev',
        ),
      );

      solicitud.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $token',
      );
      solicitud.headers.contentType = ContentType.json;

      solicitud.write(jsonEncode({
        'targetUid': uid,
        'title': titulo,
        'message': mensaje,
      }));

      final respuesta = await solicitud.close();
      final cuerpo = await respuesta.transform(utf8.decoder).join();
      cliente.close();

      if (respuesta.statusCode < 200 ||
          respuesta.statusCode >= 300) {
        throw Exception(
          'HTTP ${respuesta.statusCode}: $cuerpo',
        );
      }

      mostrarMensaje(
        'Aviso guardado. Respuesta del servidor: $cuerpo',
      );
    } catch (e) {
      mostrarMensaje(
        'El aviso quedó guardado, pero falló el Push: $e',
      );
    }
  }

  void mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> cambiarEstado(
    String id,
    String estado,
  ) async {
    try {
      await db.collection('reparaciones').doc(id).update({
        'estado': estado,
      });
      mostrarMensaje('Estado actualizado.');
    } catch (e) {
      mostrarMensaje('Error al actualizar: $e');
    }
  }

  Future<void> salir() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AccesoAdmin(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDPHONE ADMIN'),
        backgroundColor: tarjeta,
        actions: [
          IconButton(
            onPressed: salir,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('reparaciones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documentos = snapshot.data!.docs;

          if (documentos.isEmpty) {
            return const Center(
              child: Text('No hay reparaciones registradas.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final documento = documentos[index];
              final datos =
                  documento.data() as Map<String, dynamic>;

              final marca = datos['marca'] ?? '';
              final modelo = datos['modelo'] ?? '';
              final falla = datos['falla'] ?? '';
              final estado = datos['estado'] ?? 'Pendiente';
              final cliente = datos['cliente'] ?? 'Cliente';

              return Card(
                color: tarjeta,
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$marca $modelo',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: azul,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Cliente: $cliente'),
                      Text('Falla: $falla'),
                      Text('Estado: $estado'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => cambiarEstado(
                                documento.id,
                                'En reparación',
                              ),
                              child: const Text('EN REPARACIÓN'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => avisarCliente(
                            datos,
                            documento.id,
                          ),
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('AVISAR AL CLIENTE'),
                        ),
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
