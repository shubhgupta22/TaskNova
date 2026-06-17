import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController taskController = TextEditingController();
          String selectedPriority = "Medium";
          DateTime? selectedDueDate;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      top: 25,
                      left: 20,
                      right: 20,
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 5,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: taskController,
                          decoration: const InputDecoration(
                            hintText: "Enter task...",
                          ),
                        ),
                        const SizedBox(height: 20),

                        DropdownButtonFormField(
                          initialValue: selectedPriority,

                          decoration: const InputDecoration(
                            labelText: "Priority",
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: "High",
                              child: Text("High"),
                            ),

                            DropdownMenuItem(
                              value: "Medium",
                              child: Text("Medium"),
                            ),

                            DropdownMenuItem(value: "Low", child: Text("Low")),
                          ],

                          onChanged: (value) {
                            setModalState(() {
                              selectedPriority = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        OutlinedButton.icon(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,

                              initialDate: DateTime.now(),

                              firstDate: DateTime.now(),

                              lastDate: DateTime(2035),
                            );

                            if (pickedDate != null) {
                              setModalState(() {
                                selectedDueDate = pickedDate;
                              });
                            }
                          },

                          icon: const Icon(Icons.calendar_month),

                          label: Text(
                            selectedDueDate == null
                                ? "Select Due Date"
                                : "${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}",
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedDueDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please select a due date"),
                                  ),
                                );

                                return;
                              }
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null &&
                                  taskController.text.trim().isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('tasks')
                                    .add({
                                      'task': taskController.text.trim(),
                                      'userId': user.uid,
                                      'createdAt': Timestamp.now(),
                                      'isCompleted': false,
                                      'priority': selectedPriority,
                                      'dueDate': selectedDueDate,
                                    });

                                Navigator.pop(context);
                              }
                            },
                            child: const Text("Add Task"),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 90, color: Colors.grey.shade400),

                  SizedBox(height: 20),

                  Text(
                    "No tasks yet!",
                    style: TextStyle(fontSize: 22, color: Colors.grey.shade600),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Tap + to add your first task.",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,

            itemBuilder: (context, index) {
              final task = tasks[index];
              final dueDate = task.data().containsKey('dueDate')
                  ? task['dueDate']
                  : null;

              Color priorityColor;

              switch (task['priority']) {
                case 'High':
                  priorityColor = Colors.red;
                  break;

                case 'Medium':
                  priorityColor = Colors.orange;
                  break;

                default:
                  priorityColor = Colors.green;
              }

              return Dismissible(
                key: Key(task.id),

                direction: DismissDirection.endToStart,

                onDismissed: (direction) async {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Task Deleted")));

                  await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(task.id)
                      .delete();
                },

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(18),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,

                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['task'],
                              style: TextStyle(
                                fontSize: 16,
                                decoration: task['isCompleted']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Due: ${dueDate.toDate().day}/${dueDate.toDate().month}/${dueDate.toDate().year}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Checkbox(
                        value: task['isCompleted'],

                        onChanged: (value) async {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(task.id)
                              .update({'isCompleted': value});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}