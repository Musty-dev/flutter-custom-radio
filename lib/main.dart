import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

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
      home: const MyHomePage(title: 'Aitor Radio List'),
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
  TextEditingController _radioSearcher = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<List<RadioStation>> getRadioStations() async {
    final response = await http.get(Uri.parse('https://de1.api.radio-browser.info/json/stations/bycountrycodeexact/ES'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((station) => RadioStation.fromJson(station)).toList();
    } else {
      throw Exception('No se han localizado radios, comprueba tu conexión a Internet.');
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
                labelText: 'Introduce la radio a buscar'
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RadioStation>>(
              future: getRadioStations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final station = snapshot.data![index];
                      if (_radioSearcher.text.isEmpty || station.name.toLowerCase().contains(_radioSearcher.text)) {
                        return radioExpositor(station);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                }
              },
            ),
          ),
          currentStationExpositor()
        ],
      ),
    );
  }

  Widget radioExpositor(RadioStation radioStationToShow) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(radioStationToShow.name, style: TextStyle(),)),
          IconButton(
              onPressed: () async {
                if(radioStationToShow.name != currentRadioStation.name) {
                  setState(() {
                    currentRadioStation = radioStationToShow;
                  });
                  await playRadio(radioStationToShow.url);
                }
              },
              icon: const Icon(Icons.play_circle),
          )
        ],
      ),
    );
  }

  Widget currentStationExpositor () {
    if(currentRadioStation != null) {

    }
    return Container(
      child: Text("La radio actual es ${currentRadioStation.name}"),
    );
  }
}


class RadioStation {
  final String name;
  final String url;
  final String homepage;
  final String favicon;
  final String tags;
  final String country;
  final String state;
  final String language;
  final int votes;

  RadioStation({
    required this.name,
    required this.url,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.state,
    required this.language,
    required this.votes,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      name: json['name'],
      url: json['url'],
      homepage: json['homepage'],
      favicon: json['favicon'],
      tags: json['tags'],
      country: json['country'],
      state: json['state'],
      language: json['language'],
      votes: json['votes'],
    );
  }
}