import 'package:flutter/material.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  OverlayEntry? _overlayEntry;
  GlobalKey? _currentItemKey;
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleScaleAnimation;
  late Animation<double> _bubbleOpacityAnimation;
  
  // Sample todo data
  List<TodoItem> _todos = [
    TodoItem(
      id: '1',
      title: 'Complete Math Assignment',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TodoStatus.pending,
    ),
    TodoItem(
      id: '2',
      title: 'Read Chapter 5 of Physics',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TodoStatus.pending,
    ),
    TodoItem(
      id: '3',
      title: 'Write Essay Draft',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: TodoStatus.pending,
    ),
    TodoItem(
      id: '4',
      title: 'Practice Piano Scales',
      dueDate: DateTime.now().add(const Duration(hours: 6)),
      status: TodoStatus.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bubbleScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _bubbleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bubbleAnimationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentItemKey = null;
  }

  void _showStatusBubble(BuildContext context, TodoItem todo, GlobalKey itemKey) {
    _removeOverlay(); // Remove any existing overlay
    
    _currentItemKey = itemKey;
    final RenderBox? renderBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent overlay to handle taps outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Animated bubble positioned above the checkbox
          Positioned(
            top: position.dy - 80,
            left: position.dx + 20,
            child: AnimatedBuilder(
              animation: _bubbleAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bubbleScaleAnimation.value,
                  child: Opacity(
                    opacity: _bubbleOpacityAnimation.value,
                    child: Material(
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: BubblePainter(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusButton(
                                context,
                                'O',
                                () => _updateTodoStatus(todo.id, TodoStatus.completed),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusButton(
                                context,
                                'X',
                                () => _updateTodoStatus(todo.id, TodoStatus.failed),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusButton(
                                context,
                                '~',
                                () => _updateTodoStatus(todo.id, TodoStatus.inProgress),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    _bubbleAnimationController.forward();
  }

  Widget _buildStatusButton(BuildContext context, String symbol, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        _removeOverlay();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E), // navy blue
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _updateTodoStatus(String todoId, TodoStatus status) {
    setState(() {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex != -1) {
        _todos[todoIndex] = _todos[todoIndex].copyWith(status: status);
      }
    });
  }

  void _resetTodoStatus(String todoId) {
    setState(() {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex != -1) {
        _todos[todoIndex] = _todos[todoIndex].copyWith(status: TodoStatus.pending);
      }
    });
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.inDays > 0) {
      return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Due in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Due in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Due now';
    }
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddTaskModal() {
    String taskTitle = '';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        taskTitle = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Due Date Field
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setModalState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedDate != null
                                      ? _formatDateForDisplay(selectedDate!)
                                      : 'Due Date',
                                  style: TextStyle(
                                    color: selectedDate != null ? Colors.black : Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xFF1A237E), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setModalState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF1A237E)),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime != null
                                  ? selectedTime!.format(context)
                                  : 'Select Time',
                              style: TextStyle(
                                color: selectedTime != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (taskTitle.isNotEmpty && selectedDate != null && selectedTime != null) {
                            final dueDateTime = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              selectedTime!.hour,
                              selectedTime!.minute,
                            );
                            
                            setState(() {
                              _todos.add(TodoItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: taskTitle,
                                dueDate: dueDateTime,
                                status: TodoStatus.pending,
                              ));
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Study Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF888DFF),
                  labelColor: const Color(0xFF888DFF),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'To-Do'),
                    Tab(text: 'Study Plan'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodoTab(),
                    _buildStudyPlanTab(),
                  ],
                ),
              ),
            ],
          ),
          
          // Floating Action Button
          Positioned(
            bottom: 24.0,
            right: 24.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddTaskModal,
                backgroundColor: const Color(0xFF1A237E), // navy blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return _buildTodoItem(todo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(TodoItem todo) {
    final itemKey = GlobalKey();
    
    return Container(
      key: itemKey,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: todo.status == TodoStatus.pending 
                ? () => _showStatusBubble(context, todo, itemKey)
                : null,
            onLongPress: todo.status != TodoStatus.pending 
                ? () => _resetTodoStatus(todo.id)
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: _buildStatusIcon(todo.status),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: todo.status == TodoStatus.completed ? Colors.grey : Colors.black87,
                    decoration: todo.status == TodoStatus.completed 
                        ? TextDecoration.lineThrough 
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                if (todo.dueDate != null)
                  Text(
                    _formatDueDate(todo.dueDate!),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.completed:
        return const Center(
          child: Text(
            'O',
            style: TextStyle(
              color: Color(0xFF1A237E), // navy blue
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );
      case TodoStatus.failed:
        return const Center(
          child: Text(
            'X',
            style: TextStyle(
              color: Color(0xFF1A237E), // navy blue
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );
      case TodoStatus.inProgress:
        return const Center(
          child: Text(
            '~',
            style: TextStyle(
              color: Color(0xFF1A237E), // navy blue
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );
      case TodoStatus.pending:
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudyPlanTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Study Plan Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

enum TodoStatus {
  pending,
  completed,
  failed,
  inProgress,
}

class BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFF1A237E) // navy blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw shadow with subtle offset
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(20),
      ));
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw main cloud-style bubble
    final bubblePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));
    
    // Draw the bubble with fill and border
    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(bubblePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TodoItem {
  final String id;
  final String title;
  final DateTime? dueDate;
  final TodoStatus status;

  TodoItem({
    required this.id,
    required this.title,
    this.dueDate,
    required this.status,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    TodoStatus? status,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
} 