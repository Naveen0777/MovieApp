import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movies App',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const HomePage(),
    );
  }
}

class Movie {
  final String name;
  final String director;
  final String poster;

  Movie({
    required this.name,
    required this.director,
    required this.poster,
  });

  factory Movie.fromString(String str) {
    final parts = str.split(';');
    return Movie(
      name: parts[0],
      director: parts[1],
      poster: parts[2],
    );
  }

  @override
  String toString() {
    return '$name;$director;$poster';
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _directorController = TextEditingController();
  final _imageController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<Movie> _moviesList = [];

  Future<void> _addMovie() async {
    final prefs = await SharedPreferences.getInstance();
    final movie = Movie(
      name: _nameController.text,
      director: _directorController.text,
      poster: _imageController.text,
    );
    setState(() {
      _moviesList.add(movie);
    });
    prefs.setStringList(
        'movies', _moviesList.map((e) => e.toString()).toList());
    _nameController.clear();
    _directorController.clear();
    _imageController.clear();
  }

  Future<void> _deleteMovie(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moviesList.removeAt(index);
    });
    prefs.setStringList(
        'movies', _moviesList.map((e) => e.toString()).toList());
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageController.text = pickedFile!.path;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final movies = prefs.getStringList('movies');
    setState(() {
      _moviesList = movies?.map((e) => Movie.fromString(e)).toList() ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Latest Movies',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
          ),
          body: ListView.builder(
            itemCount: _moviesList.length,
            itemBuilder: (context, index) {
              final movie = _moviesList[index];
              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteMovie(index),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                child: ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: Image.file(File(movie.poster))),
                  ),
                  title: Text(movie.name),
                  subtitle: Text(movie.director),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: "Add a Movie",
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Flexible(
                    child: AlertDialog(
                        title: const Text('Add a movie'),
                        content: Form(
                            key: _formKey,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Please enter a name';
                                        }
                                        return null;
                                      }),
                                  TextFormField(
                                      controller: _directorController,
                                      decoration: const InputDecoration(
                                        labelText: 'Director',
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Please enter a director';
                                        }
                                        return null;
                                      }),
                                  TextFormField(
                                    controller: _imageController,
                                    decoration: const InputDecoration(
                                        labelText: 'Poster Image (URL)'),
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter a poster image URL';
                                      }
                                      return null;
                                    },
                                  ),
                                  // const SizedBox(height: 10.0),
                                  ElevatedButton(
                                      onPressed: _pickImage,
                                      child: const Text('Pick Image')),
                                  ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _addMovie();
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      child: const Text('Add Movie')),
                                ]))),
                  );
                },
              );
            },
            child: const Icon(Icons.add),
          )),
    );
  }
}
