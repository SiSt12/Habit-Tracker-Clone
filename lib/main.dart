import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  
  // Check "Remember Me" logic
  final rememberMe = prefs.getBool('remember_me') ?? false;
  if (!rememberMe) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(HabitApp(prefs: prefs));
}

class HabitApp extends StatelessWidget {
  final SharedPreferences prefs;

  const HabitApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      routes: {
        '/auth': (context) => AuthScreen(prefs: prefs),
        '/home': (context) => const HomePage(),
      },
      home: AuthScreen(prefs: prefs),
    );
  }
}

class Habit {
  String id;
  String name;
  IconData icon;
  Color color;
  List<bool> history;
  bool archived;
  DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.history,
    this.archived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'color': color.value,
      'history': history,
      'archived': archived,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      history: _parseHistory(json['history']),
      archived: json['archived'] ?? false,
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(json['createdAt'].toString()),
    );
  }

  static List<bool> _parseHistory(dynamic historyJson) {
    if (historyJson == null || historyJson is! List) {
      return List.filled(5, false);
    }
    final list = historyJson.map((e) => e as bool).toList();
    if (list.length < 5) {
      return [...list, ...List.filled(5 - list.length, false)];
    }
    return list;
  }
  }
}

class AuthScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const AuthScreen({super.key, required this.prefs});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  void _checkUserLoggedIn() {
    // FirebaseAuth handles persistence automatically.
    // We just check if there is a current user.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  Future<void> _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres')),
      );
      return;
    }

    try {
      // Create a dummy email from username (sanitize: lowercase, no spaces)
      final sanitizedUsername = _usernameController.text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (sanitizedUsername.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome de usuário inválido')),
        );
        return;
      }
      final email = '$sanitizedUsername@habit.app';
      
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
      
      // Update display name with original text
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_usernameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrado com sucesso!')),
        );
        _handleLoginSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Erro ao registrar';
        if (e.code == 'weak-password') {
          message = 'A senha é muito fraca.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Este usuário já existe.';
        } else {
          message = 'Erro (${e.code}): ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado: $e')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    try {
      final sanitizedUsername = _usernameController.text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final email = '$sanitizedUsername@habit.app';
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );
      
      if (mounted) {
        _handleLoginSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Erro ao fazer login')),
        );
      }
    }
  }

  void _handleLoginSuccess() {
    // Save "Remember Me" preference
    widget.prefs.setBool('remember_me', _rememberMe);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Dinho Tracker',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Usuário',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: Colors.purple,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Manter conectado', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLogin ? _login : _register,
                      child: Text(
                        _isLogin ? 'Login' : 'Registrar',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Não tem conta? Registre-se' : 'Já tem conta? Faça login',
                      style: const TextStyle(color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late FirestoreService _firestoreService;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService(_currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showSettingsDialog(context),
            child: const Icon(Icons.settings),
          ),
        ),
        title: const Text('Dinho Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showArchivedHabits(context),
              child: const Icon(Icons.archive),
            ),
          ),
          const SizedBox(width: 16),
          _buildAnimatedAddButton(context),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              _buildDateHeader(),
              Expanded(child: _buildHabitList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildAnimatedAddButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showNewHabitDialog(context),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purple.withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.add, color: Colors.purple),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(5, (index) {
          final day = today.subtract(Duration(days: 4 - index));
          final isToday = index == 4;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  DateFormat('E').format(day).substring(0, 2),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d').format(day),
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                    color: isToday ? Colors.white : Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHabitList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getHabitsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final habitsData = snapshot.data ?? [];
        final activeHabits = habitsData.where((h) => h['archived'] == false).toList();

        if (activeHabits.isEmpty) {
          return const Center(child: Text('Nenhum hábito ativo'));
        }

        return ListView.builder(
          itemCount: activeHabits.length,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemBuilder: (context, index) {
            final data = activeHabits[index];
            final habit = Habit.fromJson(data);
            
            return GestureDetector(
              onTap: () => _showHabitDetailDialog(context, habit),
              child: HabitListItem(
                habit: habit,
                onToggle: (dayIndex) {
                  final newHistory = List<bool>.from(habit.history);
                  newHistory[dayIndex] = !newHistory[dayIndex];
                  _firestoreService.updateHabitHistory(habit.id, newHistory);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showNewHabitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NewHabitScreen(
        onSave: (name, icon, color) {
          _firestoreService.addHabit(name, icon.codePoint, color.value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Settings'),
        content: const Text('Settings menu'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHabitDetailDialog(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => HabitDetailScreen(
        habit: habit,
        onDelete: () {
          _firestoreService.toggleArchive(habit.id, habit.archived);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hábito arquivado')),
          );
        },
        onUpdate: () {
          // Firestore updates automatically via stream
        },
      ),
    );
  }

  void _showArchivedHabits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getHabitsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final habitsData = snapshot.data ?? [];
          final archivedHabits = habitsData
              .map((h) => Habit.fromJson(h))
              .where((h) => h.archived)
              .toList();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hábitos Arquivados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (archivedHabits.isEmpty)
                  const Text('Nenhum hábito arquivado')
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: archivedHabits.length,
                      itemBuilder: (context, index) {
                        final habit = archivedHabits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: habit.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(habit.icon, color: habit.color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _firestoreService.toggleArchive(habit.id, true);
                                },
                                child: const Icon(Icons.restore, color: Colors.purple),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class HabitCard extends StatelessWidget {
  final Habit habit;
  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: habit.color, radius: 16, child: Icon(habit.icon, size: 16, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ]),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HabitListItem extends StatefulWidget {
  final Habit habit;
  final Function(int) onToggle;

  const HabitListItem({super.key, required this.habit, required this.onToggle});

  @override
  State<HabitListItem> createState() => _HabitListItemState();
}

class _HabitListItemState extends State<HabitListItem> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleDay(int dayIndex) {
    _controllers[dayIndex].forward().then((_) {
      _controllers[dayIndex].reverse();
    });
    widget.onToggle(dayIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.habit.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.habit.icon, color: widget.habit.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.habit.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.habit.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(5, (dayIndex) {
            final filled = widget.habit.history[dayIndex];
            return ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: _controllers[dayIndex], curve: Curves.elasticOut),
              ),
              child: GestureDetector(
                onTap: () => _toggleDay(dayIndex),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: filled ? widget.habit.color : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: widget.habit.color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class NewHabitScreen extends StatefulWidget {
  final Function(String, IconData, Color) onSave;

  const NewHabitScreen({super.key, required this.onSave});

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  String _habitName = '';
  Color _selectedColor = Colors.green;
  IconData _selectedIcon = Icons.favorite;

  final List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.grey,
    Colors.blueGrey,
  ];

  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.favorite,
    Icons.fitness_center,
    Icons.local_drink,
    Icons.book,
    Icons.code,
    Icons.self_improvement,
    Icons.menu_book,
    Icons.accessibility_new,
    Icons.school,
    Icons.music_note,
    Icons.camera,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
                const Text('New Habit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(_selectedIcon, color: _selectedColor, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Name',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _habitName = value),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Description',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.withOpacity(0.3) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
                      ),
                      child: Center(
                        child: Icon(icon, color: isSelected ? Colors.purple : Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_habitName.isNotEmpty) {
                    widget.onSave(_habitName, _selectedIcon, _selectedColor);
                  }
                },
                child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late String _habitName;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late DateTime _calendarMonth;

  final List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.grey,
    Colors.blueGrey,
  ];

  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.favorite,
    Icons.fitness_center,
    Icons.local_drink,
    Icons.book,
    Icons.code,
    Icons.self_improvement,
    Icons.menu_book,
    Icons.accessibility_new,
    Icons.school,
    Icons.music_note,
    Icons.camera,
  ];

  @override
  void initState() {
    super.initState();
    _habitName = widget.habit.name;
    _selectedColor = widget.habit.color;
    _selectedIcon = widget.habit.icon;
    _calendarMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const Icon(Icons.close),
                  ),
                ),
                const Text('Habit Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _showDeleteConfirm,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(_selectedIcon, color: _selectedColor, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Name',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              controller: TextEditingController(text: _habitName),
              onChanged: (value) {
                _habitName = value;
                widget.habit.name = value;
              },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Calendar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            _buildHabitCalendar(),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((color) {
                final isSelected = color == _selectedColor;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        widget.habit.color = color;
                      });
                      widget.onUpdate();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                        widget.habit.icon = icon;
                      });
                      widget.onUpdate();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.withOpacity(0.3) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.purple, width: 2) : null,
                      ),
                      child: Center(
                        child: Icon(icon, color: isSelected ? Colors.purple : Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onUpdate();
                  Navigator.pop(context);
                },
                child: const Text('Update', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
                  child: const Icon(Icons.chevron_left),
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_calendarMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1)),
                  child: const Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(_calendarMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final today = DateTime.now();

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstDayWeekday = firstDay.weekday;
    
    List<Widget> dayWidgets = [];

    // Adicionar headers dos dias da semana
    for (var day in weekDays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Dias vazios antes do primeiro dia
    for (int i = 0; i < firstDayWeekday - 1; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Dias do mês
    for (int i = 1; i <= lastDay.day; i++) {
      final date = DateTime(month.year, month.month, i);
      final daysAgo = today.difference(date).inDays;
      final isCompleted = daysAgo >= 0 && daysAgo < widget.habit.history.length && widget.habit.history[daysAgo];
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

      dayWidgets.add(
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? widget.habit.color : (isToday ? Colors.grey[700] : Colors.grey[800]),
            borderRadius: BorderRadius.circular(6),
            border: isToday ? Border.all(color: Colors.grey[500]!, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '$i',
              style: TextStyle(fontSize: 12, color: isCompleted ? Colors.black : Colors.white),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Habit?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
