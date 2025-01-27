import 'dart:io';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands);

    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : const Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          (bands.isNotEmpty)
              ? _showGraph()
              : const Text(
                  'No hay bandas',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
          
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTile(bands[i])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          elevation: 1, onPressed: addNewBand, child: const Icon(Icons.add)),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
          padding: const EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Delete Band', style: TextStyle(color: Colors.white)),
          )),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(band.name.substring(0, 2)),
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if (Platform.isIOS) {
      return showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
                title: const Text('New band name: '),
                content: CupertinoTextField(
                  controller: textController,
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('Add'),
                    onPressed: () => addBandToList(textController.text),
                  ),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Dismiss'),
                      onPressed: () => Navigator.pop(context))
                ],
              ));
    }

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('New band name:'),
              content: TextField(
                controller: textController,
              ),
              actions: <Widget>[
                MaterialButton(
                    elevation: 5,
                    onPressed: () => addBandToList(textController.text),
                    child: const Text('Add'))
              ],
            ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }

    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = {};
    
     for (var band in bands) {
        dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
      }

    final List<Color> colorList = [
      Colors.blue[50] as Color, //<= agregar as Color
      Colors.blue[200] as Color,
      Colors.pink[50] as Color,
      Colors.pink[200] as Color,
      Colors.yellow[50] as Color,
      Colors.yellow[200] as Color,
    ];

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 3.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 32,
        centerText: "Bandas",
        legendOptions: const LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.right,
        showLegends: true,
        legendShape: BoxShape.circle,
        legendTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
        chartValuesOptions: const ChartValuesOptions(
        showChartValueBackground: true,
        showChartValues: true,
        showChartValuesInPercentage: false,
        showChartValuesOutside: false,
        decimalPlaces: 1,
      ),
    ));
  }
}
