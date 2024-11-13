import 'package:flutter/material.dart';
import 'package:wtv/screens/custom_search_delegate.dart';
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/screens/reviews_page.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        leading: IconButton(
          onPressed: () {
            showSearch(context: context, delegate: CustomSearchDelegate());
          },
          icon: const Icon(Icons.search),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Acció per a l'icona de perfil
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tarjetas de Contactos y Grupos
            Row(
              children: [
                // Tarjeta de Contactos
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Contactes",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount:
                                  5, // Cambia esto por el número real de contactos
                              itemBuilder: (context, index) {
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: AssetImage(
                                          'assets/contact_avatar.png'), // Imagen de perfil
                                    ),
                                    title: Text("Nom del Contacte $index"),
                                    subtitle: Text("Grup(s): Exemple $index"),
                                    onTap: () {
                                      // Acción al tocar un contacto para añadirlo/quitarlo del grupo
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Tarjeta de Grupos
                Expanded(
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Grups",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount:
                                  3, // Cambia esto por el número real de grupos
                              itemBuilder: (context, index) {
                                return Card(
                                  child: ListTile(
                                    title: Text("Nom del Grup $index"),
                                    onTap: () {
                                      // Acción al tocar un grupo para gestionarlo
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botones de agregar contacto y definir grupo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción para agregar un nuevo contacto
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text("Afegir Contacte"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Acción para definir un nuevo grupo
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text("Nou Grup"),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 79, 57, 204),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SocialPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReviewsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews_outlined),
            label: '',
          ),
        ],
      ),
    );
  }
}
