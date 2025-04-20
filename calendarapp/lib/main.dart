import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEvents = prefs.getString('events');
    if (storedEvents != null) {
      setState(() {
        _events = Map<String, List<String>>.from(
          jsonDecode(storedEvents).map((key, value) =>
              MapEntry(key, List<String>.from(value as List<dynamic>))),
        );
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', jsonEncode(_events));
  }

  void _addEvent(String event) {
    final key = _selectedDay.toString().split(' ')[0];
    if (_events[key] == null) {
      _events[key] = [];
    }
    _events[key]!.add(event);
    _saveEvents();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Calendar App'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              final key = day.toString().split(' ')[0];
              return _events[key] ?? [];
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              children: (_events[_selectedDay.toString().split(' ')[0]] ?? [])
                  .map((event) => ListTile(title: Text(event)))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Event'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Enter event name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _addEvent(controller.text);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}