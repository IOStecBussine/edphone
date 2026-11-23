
import 'package:flutter/material.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

void main() {
  runApp(const EdphoneApp());
}

class EdphoneApp extends StatelessWidget {
  const EdphoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDPHONE ASISTENCIA TÉCNICA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          brightness: Brightness.dark,
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
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, size: 85, color: azul),
                const SizedBox(height: 20),
                const Text(
                  'EDPHONE',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const Text(
                  'ASISTENCIA TÉCNICA',
                  style: TextStyle(
                    color: azul,
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Tu servicio técnico, siempre cerca.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 45),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Acceso(),
                      ),
                    ),
                    child: const Text('INGRESAR'),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Registro(),
                      ),
                    ),
                    child: const Text('CREAR CUENTA'),
                  ),
                ),
                const SizedBox(height: 50),
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

class Acceso extends StatelessWidget {
  const Acceso({super.key});

  @override
  Widget build(BuildContext context) {
    final correo = TextEditingController();
    final pin = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: azul, size: 65),
            const SizedBox(height: 25),
            const Text(
              'Bienvenido nuevamente',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El acceso se conectará con Firebase.'),
                    ),
                  );
                },
                child: const Text('CONTINUAR'),
              ),
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
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.person_add_alt_1, color: azul, size: 60),
            const SizedBox(height: 15),
            const Text(
              'Registro de cliente',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            const Campo(label: 'Nombre y apellido', icon: Icons.person),
            const SizedBox(height: 15),
            const Campo(label: 'Correo electrónico', icon: Icons.email),
            const SizedBox(height: 15),
            const Campo(label: 'Teléfono', icon: Icons.phone),
            const SizedBox(height: 15),
            const Campo(
              label: 'Crear PIN',
              icon: Icons.lock,
              secreto: true,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El registro se conectará con Firebase.'),
                    ),
                  );
                },
                child: const Text('REGISTRARME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Campo extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool secreto;

  const Campo({
    super.key,
    required this.label,
    required this.icon,
    this.secreto = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: secreto,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
    Icons.build,
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const Bienvenida(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconos[seleccionado], color: azul, size: 65),
            const SizedBox(height: 18),
            Text(
              titulos[seleccionado],
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aquí encontrarás tus servicios de EDPHONE.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: seleccionado,
        onDestinationSelected: (i) {
          setState(() => seleccionado = i);
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
