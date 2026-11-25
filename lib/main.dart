import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await OneSignal.initialize(
    'fd762f68-dc4d-4f1e-91ef-4820bcef6a21',
  );

  try {
    await OneSignal.Notifications.requestPermission(true);

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario != null) {
      await OneSignal.login(usuario.uid);
    }
  } catch (e) {
    debugPrint('OneSignal: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDPHONE',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: fondo,
        colorScheme: const ColorScheme.dark(
          primary: azul,
          secondary: azul,
          surface: tarjeta,
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

        if (snapshot.hasData) {
          return const Panel();
        }

        return const Bienvenida();
      },
    );
  }
}

class Bienvenida extends StatelessWidget {
  const Bienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_android, size: 85, color: azul),
              const SizedBox(height: 20),
              const Text(
                'EDPHONE',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: azul,
                ),
              ),
              const Text(
                'ASISTENCIA TÉCNICA',
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu servicio técnico, siempre cerca.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 35),
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
              BotonPrincipal(
                texto: 'CREAR CUENTA',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Registro(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'EDPHONE © 2026',
                style: TextStyle(color: Colors.white54),
              ),
            ],
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
  final clave = TextEditingController();
  bool cargando = false;

  Future<void> ingresar() async {
    setState(() => cargando = true);

    try {
      final credencial =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo.text.trim(),
        password: clave.text.trim(),
      );

      try {
        await OneSignal.login(credencial.user!.uid);
      } catch (e) {
        debugPrint('OneSignal login: $e');
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Panel()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      mensaje(context, traducirError(e.code));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> recuperar() async {
    if (correo.text.trim().isEmpty) {
      mensaje(context, 'Escribe tu correo electrónico.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: correo.text.trim(),
      );
      if (mounted) {
        mensaje(context, 'Enviamos un enlace a tu correo.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) mensaje(context, traducirError(e.code));
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
      appBar: AppBar(title: const Text('Ingresar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: clave,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          BotonPrincipal(
            texto: cargando ? 'INGRESANDO...' : 'INGRESAR',
            onPressed: cargando ? null : ingresar,
          ),
          TextButton(
            onPressed: recuperar,
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ],
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
  final clave = TextEditingController();
  bool cargando = false;

  Future<void> registrar() async {
    if (nombre.text.trim().isEmpty ||
        correo.text.trim().isEmpty ||
        telefono.text.trim().isEmpty ||
        clave.text.length < 6) {
      mensaje(
        context,
        'Completa todos los campos. La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: correo.text.trim(),
        password: clave.text.trim(),
      );

      final usuario = credencial.user!;

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

      try {
        await OneSignal.login(usuario.uid);
      } catch (e) {
        debugPrint('OneSignal login: $e');
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Panel()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      mensaje(context, traducirError(e.code));
    } catch (e) {
      mensaje(context, 'No se pudo completar el registro.');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    nombre.dispose();
    correo.dispose();
    telefono.dispose();
    clave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre y apellido',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: clave,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Crear contraseña (mínimo 6 caracteres)',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          BotonPrincipal(
            texto: cargando ? 'REGISTRANDO...' : 'CREAR CUENTA',
            onPressed: cargando ? null : registrar,
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

  final paginas = const [
    MisReparaciones(),
    Historial(),
    Notificaciones(),
    Soporte(),
    Perfil(),
  ];

  Future<void> salir() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('OneSignal logout: $e');
    }

    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: tarjeta,
              title: const Text('Salir de EDPHONE'),
              content: const Text('¿Deseas cerrar la aplicación?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    SystemNavigator.pop();
                  },
                  child: const Text('SALIR'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EDPHONE'),
          actions: [
            IconButton(
              onPressed: salir,
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
        body: paginas[seleccionado],
        bottomNavigationBar: NavigationBar(
          backgroundColor: tarjeta,
          indicatorColor: azul.withValues(alpha: 0.25),
          selectedIndex: seleccionado,
          onDestinationSelected: (index) {
            setState(() => seleccionado = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.build),
              label: 'Reparaciones',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications),
              label: 'Avisos',
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
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return;

    if (marca.text.trim().isEmpty ||
        modelo.text.trim().isEmpty ||
        falla.text.trim().isEmpty) {
      mensaje(context, 'Completa todos los campos.');
      return;
    }

    setState(() => cargando = true);

    try {
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

      if (mounted) {
        mensaje(context, '¡Solicitud enviada correctamente!');
      }
    } catch (e) {
      if (mounted) {
        mensaje(context, 'No se pudo enviar la solicitud.');
      }
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
    final usuario = FirebaseAuth.instance.currentUser!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Solicitar reparación',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
          decoration: const InputDecoration(
            labelText: 'Describe la falla',
          ),
        ),
        const SizedBox(height: 16),
        BotonPrincipal(
          texto: cargando ? 'ENVIANDO...' : 'ENVIAR SOLICITUD',
          onPressed: cargando ? null : enviar,
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
              .where('uid', isEqualTo: usuario.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error al cargar solicitudes.');
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final documentos = snapshot.data!.docs;

            if (documentos.isEmpty) {
              return const Text('Todavía no tienes solicitudes.');
            }

            return Column(
              children: documentos.map((doc) {
                final datos = doc.data();

                return Card(
                  color: tarjeta,
                  child: ListTile(
                    leading: const Icon(Icons.phone_android, color: azul),
                    title: Text(
                      '${datos['marca'] ?? ''} ${datos['modelo'] ?? ''}',
                    ),
                    subtitle: Text(
                      'Falla: ${datos['falla'] ?? ''}\nEstado: ${datos['estado'] ?? 'Pendiente'}',
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

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reparaciones')
          .where('uid', isEqualTo: usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar historial.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documentos = snapshot.data!.docs.toList();

        documentos.sort((a, b) {
          final fechaA = a.data()['fecha'] as Timestamp?;
          final fechaB = b.data()['fecha'] as Timestamp?;

          return (fechaB?.millisecondsSinceEpoch ?? 0)
              .compareTo(fechaA?.millisecondsSinceEpoch ?? 0);
        });

        if (documentos.isEmpty) {
          return const Center(child: Text('Tu historial está vacío.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: documentos.map((doc) {
            final datos = doc.data();

            return Card(
              color: tarjeta,
              child: ListTile(
                leading: const Icon(Icons.history, color: azul),
                title: Text(
                  '${datos['marca'] ?? ''} ${datos['modelo'] ?? ''}',
                ),
                subtitle: Text(
                  'Falla: ${datos['falla'] ?? ''}\nEstado: ${datos['estado'] ?? 'Pendiente'}',
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class Notificaciones extends StatelessWidget {
  const Notificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notificaciones')
          .doc(usuario.uid)
          .collection('avisos')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar los avisos.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final avisos = snapshot.data!.docs.toList();

        avisos.sort((a, b) {
          final fechaA = a.data()['fecha'] as Timestamp?;
          final fechaB = b.data()['fecha'] as Timestamp?;

          return (fechaB?.millisecondsSinceEpoch ?? 0)
              .compareTo(fechaA?.millisecondsSinceEpoch ?? 0);
        });

        if (avisos.isEmpty) {
          return const Center(
            child: Text('Todavía no tienes notificaciones.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: avisos.map((doc) {
            final datos = doc.data();
            final leida = datos['leida'] == true;

            return Card(
              color: tarjeta,
              child: ListTile(
                leading: Icon(
                  leida
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: azul,
                ),
                title: Text(
                  datos['titulo'] ?? 'Notificación',
                  style: TextStyle(
                    fontWeight:
                        leida ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(datos['mensaje'] ?? ''),
                trailing: leida
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.circle, color: azul, size: 10),
                onTap: () async {
                  if (!leida) {
                    await doc.reference.update({'leida': true});
                  }
                },
              ),
            );
          }).toList(),
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

  Future<void> enviar() async {
    final usuario = FirebaseAuth.instance.currentUser!;
    final contenido = texto.text.trim();

    if (contenido.isEmpty) return;

    texto.clear();

    try {
      final conversacion = FirebaseFirestore.instance
          .collection('conversaciones')
          .doc(usuario.uid);

      await conversacion.set({
        'uid': usuario.uid,
        'cliente': usuario.displayName ?? 'Cliente',
        'correo': usuario.email ?? '',
        'ultimaActividad': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await conversacion.collection('mensajes').add({
        'autor': 'cliente',
        'texto': contenido,
        'fecha': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        mensaje(context, 'No se pudo enviar el mensaje.');
      }
    }
  }

  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Soporte técnico',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('conversaciones')
                .doc(usuario.uid)
                .collection('mensajes')
                .orderBy('fecha')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error al cargar mensajes.'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final mensajes = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  final datos = mensajes[index].data();
                  final esCliente = datos['autor'] == 'cliente';

                  return Align(
                    alignment: esCliente
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: esCliente ? azul : tarjeta,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(datos['texto'] ?? ''),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: texto,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                  ),
                ),
              ),
              IconButton(
                onPressed: enviar,
                icon: const Icon(Icons.send, color: azul),
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
    final usuario = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final datos = snapshot.data?.data() ?? {};

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.account_circle, size: 90, color: azul),
            const SizedBox(height: 20),
            Text(
              datos['nombre'] ?? usuario.displayName ?? 'Cliente',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: azul),
              title: const Text('Correo electrónico'),
              subtitle: Text(datos['correo'] ?? usuario.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: azul),
              title: const Text('Teléfono'),
              subtitle: Text(datos['telefono'] ?? 'No registrado'),
            ),
            const SizedBox(height: 20),
            BotonPrincipal(
              texto: 'CERRAR SESIÓN',
              onPressed: () async {
                try {
                  await OneSignal.logout();
                } catch (e) {
                  debugPrint('OneSignal logout: $e');
                }

                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        );
      },
    );
  }
}

class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
    case 'email-already-in-use':
      return 'Este correo ya está registrado.';
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'weak-password':
      return 'La contraseña es demasiado débil.';
    case 'user-not-found':
      return 'No existe una cuenta con este correo.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'network-request-failed':
      return 'Revisa tu conexión a internet.';
    default:
      return 'No se pudo completar la operación. Intenta nuevamente.';
  }
}
