import 'package:flutter/material.dart';

class CustomSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Cerca aquí...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Aquí podries mostrar els resultats de la cerca.
    return Center(
      child: Text(
        'Resultats per "$query"',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Suggereix elements mentre l'usuari escriu.
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Suggeriment 1'),
          onTap: () {
            query = 'Suggeriment 1';
            showResults(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Suggeriment 2'),
          onTap: () {
            query = 'Suggeriment 2';
            showResults(context);
          },
        ),
      ],
    );
  }
}
