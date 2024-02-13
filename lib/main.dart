import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:aitor_radio/models/radio_station.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Custom Radio Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  late RadioStation currentRadioStation;
  bool currentListening = false;
  final TextEditingController _radioSearcher = TextEditingController();
  late Future<List<RadioStation>> _radioStationsFuture;
  List<RadioStation> _filteredRadioStations = [];

  @override
  void initState() {
    super.initState();
    _radioStationsFuture = getRadioStations();
  }

  Future<List<RadioStation>> getRadioStations() async {
    final response = await http.get(Uri.parse(
        'https://de1.api.radio-browser.info/json/stations/bycountrycodeexact/ES'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((station) => RadioStation.fromJson(station)).toList();
    } else {
      throw Exception(
          'No se han localizado radios, comprueba tu conexión a Internet.');
    }
  }

  Future<void> playRadio(String url) async {
    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _radioSearcher,
              decoration: const InputDecoration(
                hintText: 'Introduce la radio a buscar',
                labelText: 'Introduce la radio a buscar',
              ),
              onChanged: (value) {
                setState(() {
                  _filteredRadioStations = _filterRadioStations(value);
                });
              },
            ),
          ),
          currentStationExpositor(),
          Expanded(
            child: FutureBuilder<List<RadioStation>>(
              future: _radioStationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  _filteredRadioStations = snapshot.data!;
                  bool isGrey = false;
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final station = snapshot.data![index];
                      isGrey = !isGrey;
                      if (_radioSearcher.text.isEmpty ||
                          station.name
                              .toLowerCase()
                              .contains(_radioSearcher.text)) {
                        return radioExpositor(station, isGrey);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget radioExpositor(RadioStation radioStationToShow, bool isGrey) {
    return Container(
      decoration:
          BoxDecoration(color: isGrey ? Colors.grey.shade200 : Colors.white),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () async {},
              icon: const Icon(Icons.star_border),
            ),
            Expanded(
                child: Text(
              radioStationToShow.name,
              style: const TextStyle(),
            )),
            IconButton(
              onPressed: () async {
                if (currentListening == false ||
                    radioStationToShow.name != currentRadioStation.name) {
                  setState(() {
                    currentRadioStation = radioStationToShow;
                    currentListening = true;
                  });
                  await playRadio(radioStationToShow.url);
                }
              },
              icon: const Icon(Icons.play_circle),
            )
          ],
        ),
      ),
    );
  }

  Widget currentStationExpositor() {
    if (currentListening) {
      return Container(
        child: Text(
          "¡Estás escuchando ${currentRadioStation.name}!",
          style: const TextStyle(fontSize: 18),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<RadioStation> _filterRadioStations(String searchQuery) {
    if (searchQuery.isEmpty) {
      return _filteredRadioStations;
    } else {
      return _filteredRadioStations.where((station) => station.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
  }
}
