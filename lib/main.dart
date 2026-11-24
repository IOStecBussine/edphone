
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
        appBarTheme: const AppBarTheme(
          backgroundColor: fondo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: tarjeta,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
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

        if (snapshot.data != null) {
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                    color: tarjeta,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: azul, width: 2),
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    color: azul,
                    size: 75,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'EDPHONE',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ASISTENCIA TÉCNICA',
                  style: TextStyle(
                    color: azul,
                    fontSize: 15,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tu servicio técnico, siempre cerca.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 50),
                BotonPrincipal(
                  texto: 'INGRESAR',
                  icono: Icons.login,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Acceso(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('CREAR CUENTA'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Registro(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 55),
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
    if (correo.text.trim().isEmpty ||
        contrasena.text.isEmpty) {
      mensaje(context, 'Completa el correo y la contraseña.');
      return;
    }

    setState(() => cargando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: correo.text.trim(),
        password: contrasena.text,
      );
    } on FirebaseAuthException catch (e) {
      mensaje(context, traducirError(e.code));
    } catch (e) {
      mensaje(context, 'No se pudo ingresar: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> recuperar() async {
    if (correo.text.trim().isEmpty) {
      mensaje(context, 'Escribe tu correo electrónico primero.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: correo.text.trim(),
      );
      if (mounted) {
        mensaje(context, 'Revisa tu correo para recuperar tu contraseña.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) mensaje(context, traducirError(e.code));
    } catch (e) {
      if (mounted) mensaje(context, 'No se pudo enviar el correo.');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 70, color: azul),
            const SizedBox(height: 20),
            const Text(
              'Bienvenido nuevamente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email, color: azul),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contrasena,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock, color: azul),
              ),
            ),
            const SizedBox(height: 25),
            BotonPrincipal(
              texto: cargando ? 'INGRESANDO...' : 'CONTINUAR',
              icono: Icons.arrow_forward,
              onPressed: cargando ? () {} : ingresar,
            ),
            TextButton(
              onPressed: cargando ? null : recuperar,
              child: const Text('¿Olvidaste tu contraseña?'),
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
        contrasena.text.isEmpty) {
      mensaje(context, 'Completa todos los campos.');
      return;
    }

    if (contrasena.text.length < 6) {
      mensaje(context, 'La contraseña debe tener al menos 6 caracteres.');
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

      if (mounted) {
  Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) mensaje(context, traducirError(e.code));
    } on FirebaseException catch (e) {
      if (mounted) {
        mensaje(
          context,
          'Cuenta creada, pero no se pudieron guardar los datos: ${e.code}',
        );
      }
    } catch (e) {
      if (mounted) mensaje(context, 'Ocurrió un error: $e');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.person_add_alt_1,
              size: 65,
              color: azul,
            ),
            const SizedBox(height: 18),
            const Text(
              'Registro de cliente',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellido',
                prefixIcon: Icon(Icons.person, color: azul),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email, color: azul),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone, color: azul),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: contrasena,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Crear contraseña (mínimo 6 caracteres)',
                prefixIcon: Icon(Icons.lock, color: azul),
              ),
            ),
            const SizedBox(height: 28),
            BotonPrincipal(
              texto: cargando ? 'REGISTRANDO...' : 'REGISTRARME',
              icono: Icons.check_circle,
              onPressed: cargando ? () {} : registrar,
            ),
          ],
        ),
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

  final iconos = [
    Icons.build_circle,
    Icons.history,
    Icons.support_agent,
    Icons.person,
  ];

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EDPHONE'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: seleccionado == 3
          ? Perfil(usuario: usuario)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iconos[seleccionado], color: azul, size: 75),
                    const SizedBox(height: 22),
                    Text(
                      titulos[seleccionado],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'EDPHONE ASISTENCIA TÉCNICA',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Tu información y tus servicios estarán disponibles aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
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
    );
  }
}

class Perfil extends StatelessWidget {
  final User usuario;

  const Perfil({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final datos = snapshot.data?.data();

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 80, color: azul),
                const SizedBox(height: 20),
                Text(
                  datos?['nombre'] ?? usuario.displayName ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(usuario.email ?? ''),
                const SizedBox(height: 8),
                Text(datos?['telefono'] ?? ''),
                if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No se pudieron cargar los datos del perfil.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BotonPrincipal extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback onPressed;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono),
        label: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
      return 'Ese correo ya tiene una cuenta.';
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'weak-password':
      return 'La contraseña es demasiado débil.';
    case 'user-not-found':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'wrong-password':
      return 'La contraseña es incorrecta.';
    case 'network-request-failed':
      return 'Revisa tu conexión a internet.';
    case 'too-many-requests':
      return 'Demasiados intentos. Intenta más tarde.';
    case 'operation-not-allowed':
      return 'El acceso por correo aún no está habilitado.';
    default:
      return 'No se pudo completar la operación: $codigo';
  }
}
