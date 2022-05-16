import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatefulWidget {
  final String jwt;
  const Home({Key? key, required this.jwt}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List syncData = [];
  String timestamp = "";
  bool isUpdated = false;

  Widget projectWidget() {
    return FutureBuilder(
      builder: (context, AsyncSnapshot projectSnap) {
        if (projectSnap.connectionState == ConnectionState.none &&
            projectSnap.hasData == null) {
          //print('project snapshot data is: ${projectSnap.data}');
          return Container();
        }
        return ListView.builder(
          itemCount: projectSnap.data?.length ?? 0,
          itemBuilder: (context, index) {
            // ProjectModel project = projectSnap.data[index];
            return ListTile(
              title: Text(projectSnap.data[index]['nama']),
              subtitle: Text("30000"),
            );
          },
        );
      },
      future: getData(),
    );
  }

  Future getData() async {
    http.Response response = await http.get(
        Uri.parse('https://paa-client-server.nafishandoko.repl.co/read'),
        headers: {"Authorization": 'Bearer ${widget.jwt}'});
    if (response.statusCode == 200) {
      String data = response.body;
      var decodedData = jsonDecode(data);
      // log('${decodedData}');
      // setState(() {
      //   syncData = decodedData;
      // });
      return jsonDecode(data);
    } else {
      print(response.statusCode);
      return jsonDecode("[]");
    }
  }

  syncHiveData() async {
    var box = await Hive.openBox('paa');
    var dataBarang = await getData();
    String datetime = DateTime.now().toString();
    box.put('barang', dataBarang);
    box.put('timestamp', datetime);
    hiveToState();
  }

  hiveToState() async {
    await Hive.openBox("paa");
    var box = Hive.box('paa');
    setState(() {
      syncData = box.get('barang') ?? [];
      timestamp = box.get('timestamp') ?? "";
    });
    cekUpdate();
  }

  cekUpdate() async {
    await Hive.openBox("paa");
    var box = Hive.box('paa');
    var dataBarang = await getData();
    log("hive: ${box.get('barang')}");
    log('api: ${dataBarang}');
    if (box.get('barang').toString() == dataBarang.toString()) {
      log('data sama');
      setState(() {
        isUpdated = true;
      });
    } else {
      log('data tidak sama');
      setState(() {
        isUpdated = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    hiveToState();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Client-Server Sync'),
  //     ),
  //     body: Container(child: projectWidget()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client-Server Sync'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20, left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpdated ? 'Updated' : 'Belum Diupdate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text('Terakhir diupdate: $timestamp')
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.only(top: 10),
            height: 550,
            color: Colors.amber,
            child: ListView.builder(
              itemCount: syncData.length,
              itemBuilder: (context, index) {
                // ProjectModel project = projectSnap.data[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nama barang: ${syncData[index]['nama']}"),
                      Text("Harga: Rp ${syncData[index]['harga']}"),
                      Text("Stock: tersedia ${syncData[index]['stock']}"),
                      const Divider(
                        color: Colors.black,
                        height: 25,
                        thickness: 2,
                        // indent: 5,
                        // endIndent: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          syncHiveData();
        },
        child: Text('Sync'),
      ),
    );
  }
}
