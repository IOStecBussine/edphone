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
    if (correo.text.trim().isEmpty || clave.text.isEmpty) {
      mensaje('Completa los campos.');
      return;
    }

    setState(() => cargando = true);

    try {
      final resultado = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: correo.text.trim(),
        password: clave.text,
      );

      final uid = resultado.user!.uid;

      final documento = await FirebaseFirestore.instance
          .collection('administradores')
          .doc(uid)
          .get();

      if (!documento.exists ||
          documento.data()?['rol'] != 'admin') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Esta cuenta no tiene acceso de administrador.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PanelAdmin()),
      );
    } catch (e) {
      if (mounted) mensaje('Error: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
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

class PanelAdmin extends StatefulWidget {
  const PanelAdmin({super.key});

  @override
  State<PanelAdmin> createState() => _PanelAdminState();
}

class _PanelAdminState extends State<PanelAdmin> {
  int pagina = 0;

  Future<void> cambiarEstado(String id, String estado) async {
    await FirebaseFirestore.instance
        .collection('reparaciones')
        .doc(id)
        .update({'estado': estado});
  }

  Future<void> salir() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AccesoAdmin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pagina == 0
            ? 'EDPHONE ADMIN'
            : 'MENSAJES DE CLIENTES'),
        backgroundColor: tarjeta,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: salir,
          ),
        ],
      ),
      body: pagina == 0
          ? reparaciones()
          : const ListaConversaciones(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: tarjeta,
        selectedIndex: pagina,
        onDestinationSelected: (valor) {
          setState(() => pagina = valor);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build),
            label: 'Reparaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Mensajes',
          ),
        ],
      ),
    );
  }

  Widget reparaciones() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reparaciones')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('Error al cargar las reparaciones.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
            final estado = datos['estado'] ?? 'Pendiente';

            return Card(
              color: tarjeta,
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
class ListaConversaciones extends StatelessWidget {
  const ListaConversaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversaciones')
          .orderBy('actualizado', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error al cargar los mensajes.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversaciones = snapshot.data!.docs;

        if (conversaciones.isEmpty) {
          return const Center(
            child: Text('Todavía no hay mensajes de clientes.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: conversaciones.length,
          itemBuilder: (context, index) {
            final doc = conversaciones[index];
            final datos = doc.data() as Map<String, dynamic>;

            return Card(
              color: tarjeta,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: azul,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(datos['cliente'] ?? 'Cliente'),
                subtitle: Text(datos['ultimoMensaje'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatAdmin(
                        uid: doc.id,
                        nombre: datos['cliente'] ?? 'Cliente',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class ChatAdmin extends StatefulWidget {
  final String uid;
  final String nombre;

  const ChatAdmin({
    super.key,
    required this.uid,
    required this.nombre,
  });

  @override
  State<ChatAdmin> createState() => _ChatAdminState();
}

class _ChatAdminState extends State<ChatAdmin> {
  final texto = TextEditingController();
  bool enviando = false;

  Future<void> enviar() async {
    final contenido = texto.text.trim();

    if (contenido.isEmpty || enviando) return;

    setState(() => enviando = true);

    try {
      final db = FirebaseFirestore.instance;

      final conversacion =
          db.collection('conversaciones').doc(widget.uid);

      final nuevoMensaje =
          conversacion.collection('mensajes').doc();

      final lote = db.batch();

      lote.set(
        conversacion,
        {
          'ultimoMensaje': contenido,
          'actualizado': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      lote.set(nuevoMensaje, {
        'autor': 'admin',
        'texto': contenido,
        'fecha': FieldValue.serverTimestamp(),
      });

      await lote.commit();

      texto.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar el mensaje.'),
          ),
        );
      }
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
    final mensajes = FirebaseFirestore.instance
        .collection('conversaciones')
        .doc(widget.uid)
        .collection('mensajes')
        .orderBy('fecha')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        backgroundColor: tarjeta,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: mensajes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar la conversación.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final lista = snapshot.data!.docs;

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Todavía no hay mensajes.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final datos =
                        lista[index].data() as Map<String, dynamic>;

                    final esAdmin = datos['autor'] == 'admin';

                    return Align(
                      alignment: esAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esAdmin ? azul : tarjeta,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esAdmin ? 'Tú - EDPHONE' : widget.nombre,
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
                      hintText: 'Escribe tu respuesta...',
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
      ),
    );
  }
}
