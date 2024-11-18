import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wtv/endpoints/api_petitions.dart';
import 'package:wtv/models/genres_group.dart';
import 'package:wtv/models/streaming_provider.dart';
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/reviews_page.dart';
import 'package:wtv/screens/social_page.dart';
import 'package:wtv/screens/splash.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  //final TextEditingController _mailController = TextEditingController();
  final Set<int> _selectedProviders = {};
  final Set<String> _selectedGenres = <String>{};
  final nameProviders = [];
  final genreNames = [];

  void initState() {
    super.initState();
    _providers = ApiPetitions.fetchProviders();
    _genres = ApiPetitions.fetchGenres();
    _checkAndAddUserToRegisteredUsers();
  }

  late Future<List<StreamingProvider>> _providers;
  late Future<List<String>> _genres = ApiPetitions.fetchGenres();
  String uName =
      FirebaseAuth.instance.currentUser!.displayName ?? 'default name';

  Future<void> _checkAndAddUserToRegisteredUsers() async {
    try {
      // Obtenir l'usuari actual
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final email = user.email;
        final uid = user.uid;

        // Comprovar si l'usuari ja existeix a la col·lecció 'registeredUsers'
        var querySnapshot = await FirebaseFirestore.instance
            .collection('registeredUsers')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Si no trobem cap document, afegim l'usuari a la col·lecció
          await FirebaseFirestore.instance.collection('registeredUsers').add({
            'email': email,
            'uid': uid,
          });
          print("Usuari afegit a registeredUsers.");
        } else {
          print("L'usuari ja existeix a registeredUsers.");
        }
      }
    } catch (e) {
      print("Error al comprovar i afegir l'usuari: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Hola $uName'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (String result) async {
              /* ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opció seleccionada: $result'))); */
              switch (result) {
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Splash()));
                  break;
                case 'settings':
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Text('Sortir'),
                      SizedBox(width: 25),
                      Icon(Icons.logout),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Text('Opcions'),
                      SizedBox(width: 5),
                      Icon(Icons.settings),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seccióna imatge de perfil
              Center(
                child: GestureDetector(
                  onTap: selectImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        FirebaseAuth.instance.currentUser?.photoURL != null
                            ? NetworkImage(
                                FirebaseAuth.instance.currentUser!.photoURL!)
                            : const AssetImage('assets/default_avatar.jpg')
                                as ImageProvider,
                    /* child: const Icon(
                      Icons.camera_alt,
                      size: 30,
                    ), */
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // nom del perfil
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: FirebaseAuth.instance.currentUser?.displayName ??
                      'Nom del perfil',
                  labelText: 'Nom del perfil',
                  border: const OutlineInputBorder(),
                  suffixIcon: InkWell(
                    onTap: () {
                      editUserName();
                    },
                    child: Icon(Icons.send),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Targetes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Primera targeta
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text("Plataformes d'Streaming"),
                            FutureBuilder<List<StreamingProvider>>(
                              future: _providers,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else {
                                  return SizedBox(
                                    height: 300, // Ajusta la altura
                                    child: GridView.builder(
                                      itemCount: snapshot.data!.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            3, // Número de columnes en la quadrícula
                                        crossAxisSpacing: 8.0,
                                        mainAxisSpacing: 8.0,
                                      ),
                                      itemBuilder: (context, index) {
                                        final provider = snapshot.data![index];
                                        nameProviders.add(provider.name);
                                        final isSelected =
                                            _selectedProviders.contains(index);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedProviders
                                                    .remove(index);
                                              } else {
                                                _selectedProviders.add(index);
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.network(
                                                  provider.logoUrl,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.contain,
                                                ),
                                                if (isSelected)
                                                  Container(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                final uid = user.uid;
                                List<Map<String, dynamic>> selectedPlatforms =
                                    [];
                                for (var index in _selectedProviders) {
                                  var tmpi = index;
                                  var platName = nameProviders[tmpi];
                                  selectedPlatforms.add({
                                    'index': index,
                                    'name': platName,
                                  });
                                }
                                try {
                                  // Guardar les plataformes seleccionades a Firestore
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                    'selectedStreamingPlatforms':
                                        selectedPlatforms,
                                  }, SetOptions(merge: true));

                                  print('Plataformas guardadas con éxito');
                                } catch (e) {
                                  print('Error al guardar en Firestore: $e');
                                }
                                print(
                                    'Canals seleccionats: $_selectedProviders');
                              },
                              child: const Text("Guardar canals"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Segona targeta
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Defineix grups de tags"),
                            FutureBuilder<List<String>>(
                              future: _genres,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else {
                                  return SizedBox(
                                    height: 300,
                                    child: ListView.builder(
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        final genre = snapshot.data![index];
                                        //genreNames.add(genre.name);
                                        final isSelected =
                                            _selectedGenres.contains(genre);

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedGenres.remove(genre);
                                              } else {
                                                _selectedGenres.add(genre);
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: isSelected
                                                  ? Colors.blue.withOpacity(0.3)
                                                  : Colors.white,
                                            ),
                                            child: Text(
                                              genre,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.black,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Botó per confirmar grups de tags
                            ElevatedButton(
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                final uid = user.uid;

                                List<String> tagNames = [];
                                for (var genre in _selectedGenres) {
                                  tagNames.add(genre);
                                }

                                GenreGroup group = GenreGroup(genres: tagNames);

                                try {
                                  // Guardar els tags a Firestore
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('groups')
                                      .add(group.toFirestore());

                                  print('Plataformas guardadas con éxito');
                                } catch (e) {
                                  print('Error al guardar en Firestore: $e');
                                }
                                print(
                                    'Canals seleccionats: $_selectedProviders');
                              },
                              child: const Text("Guardar grup"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 79, 57, 204),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
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
              MaterialPageRoute(builder: (context) => SocialPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReviewsPage()),
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

  Future<void> editUserName() async {
    var name = _nameController.text;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
    await updateUserNameinFirestore(name);
    setState(() {});
  }

  Future<void> updateUserNameinFirestore(String name) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var uid = user.uid;
      var userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      await userDoc.set({
        'displayName': name,
      }, SetOptions(merge: true));
    }
  }

  Future<void> selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final storageRef = FirebaseStorage.instance.ref();
      final userFolderRef =
          storageRef.child(FirebaseAuth.instance.currentUser!.uid);
      final imageRef = userFolderRef.child("profile.png");
      final imageFile = File(image.path);
      await imageRef.putFile(imageFile);
      final downloadUrl = await imageRef.getDownloadURL();
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
      setState(() {});
    }
  }
}
