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
  Map<String, List<Map<String, String>>> _events = {};
  String? _selectedTime; // ドロップダウンで選択された時間

  final List<String> _timeOptions = [
    '00:00 AM',
    '01:00 AM',
    '02:00 AM',
    '03:00 AM',
    '04:00 AM',
    '05:00 AM',
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
    '09:00 PM',
    '10:00 PM',
    '11:00 PM',
  ];

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
        _events = Map<String, List<Map<String, String>>>.from(
          jsonDecode(storedEvents).map((key, value) =>
              MapEntry(key, List<Map<String, String>>.from(value as List))),
        );
      });
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('events', jsonEncode(_events));
  }

  void _addEvent(String title, String time, String details) {
    final key = _selectedDay.toString().split(' ')[0];
    if (_events[key] == null) {
      _events[key] = [];
    }
    _events[key]!.add({
      'title': title,
      'time': time,
      'details': details,
    });
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
                  .map((event) => ListTile(
                        title: Text(event['title'] ?? ''),
                        subtitle: Text(
                            '${event['time'] ?? ''}\n${event['details'] ?? ''}'),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final titleController = TextEditingController();
          final detailsController = TextEditingController();
          _selectedTime = _timeOptions.first; // 初期値を設定
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('イベントを追加'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'タイトル'),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedTime,
                    items: _timeOptions
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                    decoration: const InputDecoration(hintText: '時間'),
                  ),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(hintText: '詳細'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('エラー'),
                          content: const Text('タイトルを入力してください。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else if (_selectedTime != null &&
                        detailsController.text.isNotEmpty) {
                      _addEvent(
                        titleController.text,
                        _selectedTime!,
                        detailsController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('追加'),
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