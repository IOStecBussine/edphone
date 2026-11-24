
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

String? errorFirebase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    errorFirebase = e.toString();
    debugPrint('Error Firebase: $e');
  }

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
      home: const Bienvenida(),
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
                if (errorFirebase != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'No se pudo conectar con Firebase.',
                    style: TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Acceso extends StatelessWidget {
  const Acceso({super.key});

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
            const Campo(
              etiqueta: 'Correo electrónico',
              icono: Icons.email,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Campo(
              etiqueta: 'PIN',
              icono: Icons.lock,
              secreto: true,
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 25),
            BotonPrincipal(
              texto: 'CONTINUAR',
              icono: Icons.arrow_forward,
              onPressed: () {
                mensaje(
                  context,
                  'El inicio de sesión se habilitará en el siguiente paso.',
                );
              },
            ),
            TextButton(
              onPressed: () {
                mensaje(
                  context,
                  'La recuperación de cuenta se habilitará próximamente.',
                );
              },
              child: const Text('¿Olvidaste tu PIN?'),
            ),
          ],
        ),
      ),
    );
  }
}

class Registro extends StatelessWidget {
  const Registro({super.key});

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
            const Campo(
              etiqueta: 'Nombre y apellido',
              icono: Icons.person,
            ),
            const SizedBox(height: 15),
            const Campo(
              etiqueta: 'Correo electrónico',
              icono: Icons.email,
              teclado: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            const Campo(
              etiqueta: 'Teléfono',
              icono: Icons.phone,
              teclado: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            const Campo(
              etiqueta: 'Crear PIN',
              icono: Icons.lock,
              secreto: true,
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 28),
            BotonPrincipal(
              texto: 'REGISTRARME',
              icono: Icons.check_circle,
              onPressed: () {
                mensaje(
                  context,
                  'El registro se habilitará en el siguiente paso.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Campo extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool secreto;
  final TextInputType teclado;

  const Campo({
    super.key,
    required this.etiqueta,
    required this.icono,
    this.secreto = false,
    this.teclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: secreto,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: azul),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDPHONE'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const Bienvenida(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
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
