import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../components/my_user_tile.dart';
import '../services/database/database_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // text controller
  final _searchController = TextEditingController();

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    //providers
    final databaseProvider = Get.find<DatabaseProvider>();
    final listeningProvider =
        Get.find<DatabaseProvider>();
    //SCAFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      //App Bar
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search",
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8.0), // Adjust radius as needed
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, // Border color
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8.0), // Adjust radius as needed
              borderSide: const BorderSide(
                color: Colors.deepPurple, // Border color when focused
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(8.0), // Adjust radius as needed
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary, // Border color when enabled
              ),
            ),
          ),
          onChanged: (value) {
            // Search users
            if (value.isNotEmpty) {
              databaseProvider.searchUsers(value);
            }

            //clear search
            else {
              databaseProvider.searchUsers("");
            }
          },
        ),
      ),

      //body
      body: listeningProvider.searchResults.isEmpty
          ?

          //no user found
          Center(
              child: Text(
                "No user found",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            )
          :

          //user found
          ListView.builder(
              itemCount: listeningProvider.searchResults.length,
              itemBuilder: (context, index) {
                final user = listeningProvider.searchResults[index];
                return MyUserTile(user: user);
              }),
    );
  }
}
