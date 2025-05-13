import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공지사항 앱',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _currentPage = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notices = [];

  List<String> keywords = ['신입생', '출석', '장학생'];
  final TextEditingController _keywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNoticesPage(0);
  }

  Future<void> fetchNoticesPage(int page) async {
    setState(() => _isLoading = true);

    try {
      final res = await http.get(Uri.parse('http://127.0.0.1:5000/api/notices?offset=${page * 10}')); // 서버 실행되는 ip주소
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _notices = data.cast<Map<String, dynamic>>();
          _currentPage = page;
        });
      }
    } catch (e) {
      print('페이지 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      title: Text(
        ['공지사항', '키워드 알림', '학사 일정', '설정'][_selectedIndex],
        style: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  Widget _buildNoticePage() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.separated(
            itemCount: _notices.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final notice = _notices[index];
              return ListTile(
                title: Text(notice['제목']),
                subtitle: Text(notice['등록일'] ?? '날짜 없음'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoticeDetailPage(notice: notice),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _currentPage > 0 ? () => fetchNoticesPage(_currentPage - 1) : null,
              child: Text('◀ 이전'),
            ),
            Text('페이지 ${_currentPage + 1}'),
            ElevatedButton(
              onPressed: () => fetchNoticesPage(_currentPage + 1),
              child: Text('다음 ▶'),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildKeywordPage() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    hintText: '알림 받을 키워드를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final keyword = _keywordController.text.trim();
                  if (keyword.isNotEmpty && keywords.length < 10) {
                    setState(() {
                      keywords.add(keyword);
                      _keywordController.clear();
                    });
                  }
                },
                child: Text('등록'),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: keywords.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(keywords[i]),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() => keywords.removeAt(i));
                },
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCalendarPage() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          availableCalendarFormats: const {CalendarFormat.month: '월'},
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Center(child: Text('일정 기능은 추후 구현 예정')),
        )
      ],
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildNoticePage();
      case 1:
        return _buildKeywordPage();
      case 2:
        return _buildCalendarPage();
      default:
        return Center(child: Text('설정 페이지'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: '알림'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  const NoticeDetailPage({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(notice['제목'] ?? '제목 없음')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('날짜: ${notice['등록일'] ?? '없음'}'),
              SizedBox(height: 10),
              Text(
                notice['본문'] ?? '본문 없음',
                style: TextStyle(fontSize: 16),
              )
            ],
          ),
        ),
      ),
    );
  }
}
