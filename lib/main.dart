import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDPHONE ASISTENCIA TÉCNICA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          brightness: Brightness.dark,
        ),
      ),
      home: const Inicio(),
    );
  }
}

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data != null
            ? const Panel()
            : const Bienvenida();
      },
    );
  }
}

class Bienvenida extends StatelessWidget {
  const Bienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, size: 95, color: azul),
                const SizedBox(height: 20),
                const Text(
                  'EDPHONE',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ASISTENCIA TÉCNICA',
                  style: TextStyle(color: azul, letterSpacing: 2),
                ),
                const SizedBox(height: 15),
                const Text('Tu servicio técnico, siempre cerca.'),
                const SizedBox(height: 40),
                BotonPrincipal(
                  texto: 'INGRESAR',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Acceso(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Registro(),
                      ),
                    );
                  },
                  child: const Text('CREAR CUENTA'),
                ),
                const SizedBox(height: 45),
                const Text(
                  'EDPHONE © 2026',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Acceso extends StatefulWidget {
  const Acceso({super.key});

  @override
  State<Acceso> createState() => _AccesoState();
}

class _AccesoState extends State<Acceso> {
  final correo = TextEditingController();
  final contrasena = TextEditingController();
  bool cargando = false;

  Future<void> ingresar() async {
    if (correo.text.trim().isEmpty || contrasena.text.isEmpty) {
      mensaje(context, 'Completa los campos.');
      return;
    }

    setState(() => cargando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo.text.trim(),
        password: contrasena.text,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Panel()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) mensaje(context, traducirError(e.code));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    correo.dispose();
    contrasena.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 65, color: azul),
            const SizedBox(height: 25),
            TextField(
              controller: correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: contrasena,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
              ),
            ),
            const SizedBox(height: 25),
            BotonPrincipal(
              texto: cargando ? 'INGRESANDO...' : 'CONTINUAR',
              onPressed: cargando ? () {} : ingresar,
            ),
          ],
        ),
      ),
    );
  }
}
class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final nombre = TextEditingController();
  final correo = TextEditingController();
  final telefono = TextEditingController();
  final contrasena = TextEditingController();
  bool cargando = false;

  Future<void> registrar() async {
    if (nombre.text.trim().isEmpty ||
        correo.text.trim().isEmpty ||
        telefono.text.trim().isEmpty ||
        contrasena.text.length < 6) {
      mensaje(context, 'Completa los campos. Contraseña mínimo 6 caracteres.');
      return;
    }

    setState(() => cargando = true);

    try {
      final resultado = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: correo.text.trim(),
        password: contrasena.text,
      );

      final usuario = resultado.user!;
      await usuario.updateDisplayName(nombre.text.trim());

      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(usuario.uid)
          .set({
        'uid': usuario.uid,
        'nombre': nombre.text.trim(),
        'correo': correo.text.trim(),
        'telefono': telefono.text.trim(),
        'rol': 'cliente',
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Panel()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) mensaje(context, traducirError(e.code));
    } catch (e) {
      if (mounted) mensaje(context, 'Error al registrar: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    nombre.dispose();
    correo.dispose();
    telefono.dispose();
    contrasena.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Icon(Icons.person_add, size: 65, color: azul),
          const SizedBox(height: 22),
          TextField(
            controller: nombre,
            decoration: const InputDecoration(labelText: 'Nombre y apellido'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: contrasena,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña (mínimo 6 caracteres)',
            ),
          ),
          const SizedBox(height: 22),
          BotonPrincipal(
            texto: cargando ? 'REGISTRANDO...' : 'REGISTRARME',
            onPressed: cargando ? () {} : registrar,
          ),
        ],
      ),
    );
  }
}

class Panel extends StatefulWidget {
  const Panel({super.key});

  @override
  State<Panel> createState() => _PanelState();
}

class _PanelState extends State<Panel> {
  int seleccionado = 0;

  final titulos = [
    'Mis reparaciones',
    'Mi historial',
    'Soporte técnico',
    'Mi perfil',
  ];

  Future<void> salir() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const MisReparaciones(),
      const Historial(),
      const Soporte(),
      const Perfil(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Deseas cerrar tu sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('NO'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('SÍ'),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          await FirebaseAuth.instance.signOut();
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulos[seleccionado]),
          actions: [
            IconButton(
              onPressed: salir,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: paginas[seleccionado],
        bottomNavigationBar: NavigationBar(
          selectedIndex: seleccionado,
          onDestinationSelected: (i) {
            setState(() => seleccionado = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.build_circle),
              label: 'Reparaciones',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.support_agent),
              label: 'Soporte',
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}


class MisReparaciones extends StatefulWidget {
  const MisReparaciones({super.key});

  @override
  State<MisReparaciones> createState() => _MisReparacionesState();
}

class _MisReparacionesState extends State<MisReparaciones> {
  final marca = TextEditingController();
  final modelo = TextEditingController();
  final falla = TextEditingController();
  bool cargando = false;

  Future<void> enviar() async {
    if (marca.text.trim().isEmpty ||
        modelo.text.trim().isEmpty ||
        falla.text.trim().isEmpty) {
      mensaje(context, 'Completa todos los campos.');
      return;
    }

    setState(() => cargando = true);

    try {
      final usuario = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('reparaciones').add({
        'uid': usuario.uid,
        'cliente': usuario.displayName ?? 'Cliente',
        'correo': usuario.email ?? '',
        'marca': marca.text.trim(),
        'modelo': modelo.text.trim(),
        'falla': falla.text.trim(),
        'estado': 'Pendiente',
        'fecha': FieldValue.serverTimestamp(),
      });

      marca.clear();
      modelo.clear();
      falla.clear();

      if (mounted) mensaje(context, 'Solicitud enviada correctamente.');
    } catch (e) {
      if (mounted) mensaje(context, 'Error al enviar: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    marca.dispose();
    modelo.dispose();
    falla.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(Icons.build_circle, size: 55, color: azul),
        const SizedBox(height: 12),
        const Text(
          'Solicitar reparación',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: marca,
          decoration: const InputDecoration(labelText: 'Marca del celular'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: modelo,
          decoration: const InputDecoration(labelText: 'Modelo del celular'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: falla,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Describe la falla'),
        ),
        const SizedBox(height: 18),
        BotonPrincipal(
          texto: cargando ? 'ENVIANDO...' : 'ENVIAR SOLICITUD',
          onPressed: cargando ? () {} : enviar,
        ),
        const SizedBox(height: 25),
        const Text(
          'Mis solicitudes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('reparaciones')
              .where('uid', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error al cargar solicitudes.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Text('Todavía no tienes solicitudes.');
            }

            return Column(
              children: docs.map((doc) {
                final datos = doc.data();
                return Card(
                  color: tarjeta,
                  child: ListTile(
                    leading: const Icon(Icons.phone_android, color: azul),
                    title: Text(
                      '${datos['marca'] ?? ''} ${datos['modelo'] ?? ''}',
                    ),
                    subtitle: Text(
                      'Falla: ${datos['falla'] ?? ''}\n'
                      'Estado: ${datos['estado'] ?? 'Pendiente'}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class Historial extends StatelessWidget {
  const Historial({super.key});

  String fechaTexto(dynamic fecha) {
    if (fecha is! Timestamp) return 'Fecha pendiente';
    final d = fecha.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reparaciones')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar historial.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final fa = a.data()['fecha'];
          final fb = b.data()['fecha'];
          final ta = fa is Timestamp ? fa.millisecondsSinceEpoch : 0;
          final tb = fb is Timestamp ? fb.millisecondsSinceEpoch : 0;
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('Todavía no tienes reparaciones registradas.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Mi historial de reparaciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final datos = doc.data();
              return Card(
                color: tarjeta,
                child: ListTile(
                  leading: const Icon(Icons.history, color: azul),
                  title: Text(
                    '${datos['marca'] ?? ''} ${datos['modelo'] ?? ''}',
                  ),
                  subtitle: Text(
                    'Falla: ${datos['falla'] ?? ''}\n'
                    'Estado: ${datos['estado'] ?? 'Pendiente'}\n'
                    'Fecha: ${fechaTexto(datos['fecha'])}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
class Soporte extends StatefulWidget {
  const Soporte({super.key});

  @override
  State<Soporte> createState() => _SoporteState();
}

class _SoporteState extends State<Soporte> {
  final texto = TextEditingController();
  bool enviando = false;

  final db = FirebaseFirestore.instance;

  Future<void> enviar() async {
    final usuario = FirebaseAuth.instance.currentUser;
    final contenido = texto.text.trim();

    if (usuario == null || contenido.isEmpty || enviando) return;

    setState(() => enviando = true);

    try {
      final uid = usuario.uid;
      final conversacion = db.collection('conversaciones').doc(uid);
      final nuevoMensaje = conversacion.collection('mensajes').doc();

      final datosCliente =
          await db.collection('clientes').doc(uid).get();
      final nombre = datosCliente.data()?['nombre'] ?? 'Cliente';

      final lote = db.batch();

      lote.set(
        conversacion,
        {
          'uid': uid,
          'cliente': nombre,
          'correo': usuario.email ?? '',
          'ultimoMensaje': contenido,
          'actualizado': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      lote.set(nuevoMensaje, {
        'autor': 'cliente',
        'texto': contenido,
        'fecha': FieldValue.serverTimestamp(),
      });

      await lote.commit();

      texto.clear();
    } catch (e) {
      if (mounted) mensaje(context, 'No se pudo enviar el mensaje.');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(child: Text('Inicia sesión para usar soporte.'));
    }

    final mensajes = db
        .collection('conversaciones')
        .doc(usuario.uid)
        .collection('mensajes')
        .orderBy('fecha')
        .snapshots();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          color: tarjeta,
          child: const Column(
            children: [
              Icon(Icons.support_agent, color: azul, size: 40),
              SizedBox(height: 8),
              Text(
                'SOPORTE TÉCNICO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Escribe aquí para comunicarte con EDPHONE.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: mensajes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('No se pudieron cargar los mensajes.'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final lista = snapshot.data!.docs;

              if (lista.isEmpty) {
                return const Center(
                  child: Text('Todavía no hay mensajes. ¡Escribe al soporte!'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                itemBuilder: (context, index) {
                  final datos =
                      lista[index].data() as Map<String, dynamic>;
                  final esCliente = datos['autor'] == 'cliente';

                  return Align(
                    alignment: esCliente
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: esCliente ? azul : tarjeta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esCliente ? 'Tú' : 'Soporte EDPHONE',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(datos['texto'] ?? ''),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: texto,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: enviando ? null : enviar,
                icon: enviando
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.send, color: azul),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Perfil extends StatelessWidget {
  const Perfil({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(child: Text('No hay una sesión iniciada.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final datos =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.account_circle, size: 90, color: azul),
            const SizedBox(height: 20),
            Card(
              color: tarjeta,
              child: ListTile(
                leading: const Icon(Icons.person, color: azul),
                title: const Text('Nombre y apellido'),
                subtitle: Text(datos['nombre'] ?? 'No disponible'),
              ),
            ),
            Card(
              color: tarjeta,
              child: ListTile(
                leading: const Icon(Icons.email, color: azul),
                title: const Text('Correo electrónico'),
                subtitle: Text(datos['correo'] ?? usuario.email ?? ''),
              ),
            ),
            Card(
              color: tarjeta,
              child: ListTile(
                leading: const Icon(Icons.phone, color: azul),
                title: const Text('Teléfono'),
                subtitle: Text(datos['telefono'] ?? 'No disponible'),
              ),
            ),
            const SizedBox(height: 25),
            OutlinedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('CERRAR SESIÓN'),
            ),
          ],
        );
      },
    );
  }
}

class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

void mensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(texto)),
  );
}

String traducirError(String codigo) {
  switch (codigo) {
    case 'user-not-found':
      return 'No existe una cuenta con ese correo.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'network-request-failed':
      return 'Revisa tu conexión a internet.';
    default:
      return 'No se pudo iniciar sesión. Intenta nuevamente.';
  }
}
