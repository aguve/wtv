import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wtv/config.dart';
import 'package:wtv/endpoints/api_petitions.dart';
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/screens/reviews_page.dart';
import 'package:wtv/screens/splash.dart';
import 'package:wtv/styles/app_sytles.dart';

class SocialPage extends StatefulWidget {
  @override
  _SocialPageState createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  late Future<List<List<String>>> genresFromFirestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _friendsList =
      []; // Llista per guardar els contactes
  Set<int> _selectedFriends = {};
  List<Map<String, dynamic>> _groupsList = [];
  int? _selectedGroupIndex;
  List<String> friendTags = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends(); // Carregar els contactes quan s'inicia la pantalla
    _fetchGroups();
    genresFromFirestore = ApiPetitions.getGenresLists(
        FirebaseAuth.instance.currentUser!.uid,
        friendTags: friendTags);
  }

  // Funció per recuperar els contactes de la col·lecció 'friends' de Firestore
  Future<void> _fetchFriends() async {
    String userId = _auth.currentUser!.uid; // Obtenir l'ID de l'usuari actual

    try {
      // Consultar la col·lecció 'friends' dins del document de l'usuari
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      // Si no hi ha documents a la col·lecció, afegir un missatge de debug
      if (snapshot.docs.isEmpty) {
        print("No s'han trobat contactes.");
      }

      // Mapejar els documents recuperats i afegir-los a la llista
      setState(() {
        _friendsList = snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'email': doc['email'],
            'tags': doc['tags'],
            'channels': doc['channels'],
            'uid': doc['uid'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error recuperant contactes: $e");
    }
  }

  void _createGroup() async {
    // Obtenir els ids dels contactes seleccionats
    List selectedContactIds =
        _selectedFriends.map((index) => _friendsList[index]['name']).toList();
    if (selectedContactIds.length == 0) return;
    final userId = _auth.currentUser!.uid;
    List<List<String>> myTags = await getGenresLists(userId);
    List<Map<String, dynamic>> myChannels = await getSelectedPlatforms(userId);
    List<String> myTagsList = [];
    List<String> myChannelsList = [];
    for (var tags in myTags) {
      for (var tag in tags) {
        myTagsList.add(tag);
      }
    }
    myChannels.forEach((item) {
      myChannelsList.add(item['name']);
    });

    // Afegir tags i canals de l'usuari
    List<String> allTags = List.from(myTagsList);
    List<String> allChannels = List.from(myChannelsList);

    // Afegir tags i canals dels contactes seleccionats
    for (var index in _selectedFriends) {
      final friend = _friendsList[index];
      // Afegir els tags i canals de cada amic seleccionat
      allTags.addAll(List<String>.from(friend['tags'] ?? []));
      allChannels.addAll(List<String>.from(friend['channels'] ?? []));
    }

    // Eliminar duplicats
    allTags = allTags.toSet().toList();
    allChannels = allChannels.toSet().toList();

    try {
      // Crear un grup a Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('groupsOfFriends')
          .add({
        'members': selectedContactIds,
        'tags': allTags,
        'channels': allChannels,
        'createdAt': Timestamp.now(),
      });

      // Mostrar missatge d'èxit
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Grup creat correctament!"),
      ));
    } catch (e) {
      print("Error al crear el grup: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al crear el grup."),
      ));
    }

    // Actualitzar l'estat per mostrar el grup a la targeta
    setState(() {
      _fetchGroups();
      _selectedFriends.map((index) => _selectedFriends.remove(index));
    });
  }

  Future<Map<String, dynamic>> checkIfEmailExists(String email) async {
    try {
      // Comprovar si el correu existeix a la col·lecció 'registeredUsers'
      var querySnapshot = await FirebaseFirestore.instance
          .collection('registeredUsers')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si trobem el correu a la col·lecció, retornem el correu i l'uid
        var userDoc = querySnapshot.docs.first;
        return {
          'exists': true,
          'email': userDoc['email'],
          'uid': userDoc['uid'],
        };
      } else {
        // Si no trobem cap document, retornar que no existeix
        return {'exists': false};
      }
    } catch (e) {
      print("Error checking if email exists: $e");
      return {'exists': false}; // En cas d'error, retornem que no existeix
    }
  }

  // Funció per obrir el popup de "Nou Amic"
  void _openAddFriendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Afegir Nou Amic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correu electrònic",
                ),
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nom",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                var result = await checkIfEmailExists(_emailController.text);
                bool emailExists = result['exists'];

                if (!emailExists) {
                  // Si el correu no existeix, mostrar un missatge
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("El correu no existeix a Firebase!"),
                    ));
                    Navigator.pop(context); // Tancar el popup
                  }
                } else {
                  // Si el correu existeix, desar a Firestore
                  if (mounted) {
                    await _saveFriendToFirestore(result['uid']);
                    // Tancar el popup
                    Navigator.pop(context);
                  }
                }
                setState(() {
                  _fetchFriends();
                });
              },
              child: Text("Desar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tancar el popup sense desar
              },
              child: Text("Cancel·lar"),
            ),
          ],
        );
      },
    );
  }

  // Funció per desar el contacte a Firestore
  Future<void> _saveFriendToFirestore(String friendID) async {
    List<Map<String, dynamic>> friendPlatforms =
        await getSelectedPlatforms(friendID);
    List<List<String>> friendGenresLists = await getGenresLists(friendID);
    List selectedPlatformNames =
        friendPlatforms.map((platform) => platform['name']).toList();
    List friendGenres = [];
    for (var tags in friendGenresLists) {
      for (var tag in tags) {
        friendGenres.add(tag);
      }
    }

    try {
      String userId = _auth.currentUser!.uid;
      String email = _emailController.text;
      String name = _nameController.text;

      // Afegix el contacte a la col·lecció 'friends' dins el document de l'usuari
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .add({
        'uid': friendID,
        'email': email,
        'name': name,
        'tags': friendGenres,
        'channels': selectedPlatformNames,
        'createdAt': Timestamp.now(),
      });

      // Reiniciar els camps de text després de desar
      _emailController.clear();
      _nameController.clear();
    } catch (e) {
      print("Error al desar el contacte: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getSelectedPlatforms(String uid) async {
    // Obtener el documento del usuario desde Firestore
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Asegúrate de que el documento existe
    if (userDoc.exists) {
      // Obtener las plataformas seleccionadas (array)
      List<dynamic> selectedPlatformsData =
          userDoc['selectedStreamingPlatforms'] ?? [];

      List<Map<String, dynamic>> selectedPlatforms = [];

      // Usamos forEach para recorrer cada elemento del array y devolverlo en el formato deseado
      selectedPlatformsData.forEach((platform) {
        selectedPlatforms.add({
          'id': platform['index'], // El índice de la plataforma
          'name': platform['name'], // El nombre de la plataforma
        });
      });

      return selectedPlatforms;
    } else {
      print('El documento del usuario no existe');
      return [];
    }
  }

  Future<List<List<String>>> getGenresLists(String uid) async {
    List<List<String>> genresLists = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('groups')
          .get();

      for (var doc in querySnapshot.docs) {
        List<String> genres = List<String>.from(doc['genres']);
        genresLists.add(genres);
      }

      return genresLists;
    } catch (e) {
      print('Error obtenint llistes de tags: $e');
      return [];
    }
  }

  // Funció per recuperar els grups de la col·lecció 'groupsOfFriends' de Firestore
  Future<void> _fetchGroups() async {
    String userId = _auth.currentUser!.uid; // Obtenir l'ID de l'usuari actual

    try {
      // Consultar la col·lecció 'groupsOfFriends' dins del document de l'usuari
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('groupsOfFriends')
          .get();

      // Mapejar els documents recuperats i afegir-los a la llista
      setState(() {
        _groupsList = snapshot.docs.map((doc) {
          return {
            'members': doc['members'],
            'tags': doc['tags'],
            'channels': doc['channels'],
            'createdAt': doc['createdAt'],
          };
        }).toList();
      });
    } catch (e) {
      print("Error recuperant els grups: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Social',
          style: TextStyle(
            color: AppSytles.platinium,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppSytles.platinium,
            ),
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
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Targeta de Contactes
              Card(
                color: AppSytles.columbiaBlue,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Contactes",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppSytles.oxfordBlue),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: ListView.builder(
                          itemCount: _friendsList
                              .length, // La mida de la llista es determina dinàmicament
                          itemBuilder: (context, index) {
                            final friend =
                                _friendsList[index]; // Obtenir el contacte
                            final isSelected = _selectedFriends.contains(index);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedFriends.remove(index);
                                  } else {
                                    _selectedFriends.add(index);
                                  }
                                });
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: AssetImage(
                                      'assets/default_avatar.jpg'), // Imatge de perfil per defecte
                                ),
                                title: Text(friend['name']),
                                subtitle: Text(friend['email']),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isSelected ? Colors.blue : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Separador entre les targetes

              // Tarjeta de Grups
              Card(
                color: AppSytles.columbiaBlue,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Grups",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppSytles.oxfordBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: ListView.builder(
                          itemCount: _groupsList
                              .length, // Usar el numero de grups recuperats
                          itemBuilder: (context, index) {
                            final group = _groupsList[
                                index]; // Obtenir les dades del grup
                            return Card(
                              color: AppSytles.columbiaBlue,
                              child: GestureDetector(
                                child: ListTile(
                                  title: Text(
                                      "${group['members'].join(', ')} i jo"), // Nom del grup
                                  subtitle: Text(
                                      "Tags: ${group['tags'].join(', ')}"), // Mostrar tags del grup
                                  onTap: () {
                                    setState(() {
                                      _selectedGroupIndex = index;
                                    });

                                    friendTags =
                                        List<String>.from(group['tags']);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botons per afegir contacte o grup.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppSytles.sapphire,
                      foregroundColor: AppSytles.columbiaBlue,
                    ),
                    onPressed: _openAddFriendDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Nou Amic"),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppSytles.sapphire,
                      foregroundColor: AppSytles.columbiaBlue,
                    ),
                    onPressed: _createGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text("Nou Grup"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_selectedGroupIndex != null) ...[
                Card(
                  color: AppSytles.columbiaBlue,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Per al grup!",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppSytles.oxfordBlue),
                        ),
                        SizedBox(
                          height: 450,
                          child: FutureBuilder<List<List<String>>>(
                            future: genresFromFirestore,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (snapshot.hasData) {
                                final selectedTags = snapshot.data!;

                                return ListView.builder(
                                  itemCount: selectedTags.length,
                                  itemBuilder: (context, index) {
                                    final tagList = selectedTags[index];

                                    return FutureBuilder<
                                        List<List<Map<String, dynamic>>>>(
                                      future: Future.wait([
                                        ApiPetitions.searchMovies(
                                            tagList,
                                            Config.apiKey,
                                            FirebaseAuth.instance.currentUser!
                                                .uid), // Buscar pelis
                                        ApiPetitions.searchSeries(
                                            tagList,
                                            Config.apiKey,
                                            FirebaseAuth.instance.currentUser!
                                                .uid), // Buscar series
                                      ]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Error: ${snapshot.error}'));
                                        } else if (snapshot.hasData) {
                                          final movies =
                                              snapshot.data![0]; // pelis
                                          final series =
                                              snapshot.data![1]; // series

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Pelis',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppSytles.oxfordBlue),
                                                ),
                                              ),
                                              // ListView de pelis
                                              SizedBox(
                                                height: 200,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: movies.length,
                                                  itemBuilder:
                                                      (context, movieIndex) {
                                                    final movie =
                                                        movies[movieIndex];
                                                    return Card(
                                                      color:
                                                          AppSytles.oxfordBlue,
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      child: Column(
                                                        children: [
                                                          Image.network(
                                                              movie['imageUrl'],
                                                              height: 165,
                                                              width: 110,
                                                              fit:
                                                                  BoxFit.cover),
                                                          Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 8.0,
                                                                      left: 4.0,
                                                                      right:
                                                                          4.0),
                                                              child: Text(
                                                                  '${movie['platforms'].join(', ')}'))
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Series',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppSytles.oxfordBlue),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 200,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: series.length,
                                                  itemBuilder:
                                                      (context, seriesIndex) {
                                                    final serie =
                                                        series[seriesIndex];
                                                    return Card(
                                                      color:
                                                          AppSytles.oxfordBlue,
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      child: Column(
                                                        children: [
                                                          Image.network(
                                                              serie['imageUrl'],
                                                              height: 165,
                                                              width: 110,
                                                              fit:
                                                                  BoxFit.cover),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 8.0,
                                                                    left: 4.0,
                                                                    right:
                                                                        4.0), // Afegir un padding superior
                                                            child: Text(
                                                              '${serie['platforms'].join(', ')}',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: 15),
                                            ],
                                          );
                                        } else {
                                          return Center(
                                              child: Text(
                                                  'No s\'han trobat resultats.'));
                                        }
                                      },
                                    );
                                  },
                                );
                              } else {
                                return const Center(
                                    child: Text('No s\'han trobat gèneres.'));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppSytles.prussianBlue,
        selectedItemColor: AppSytles.platinium,
        unselectedItemColor: AppSytles.sapphire,
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
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.home),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.manage_accounts),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.groups),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.reviews_outlined),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
