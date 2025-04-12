import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';

class LocationNotesScreen extends StatefulWidget {
  const LocationNotesScreen({super.key});

  @override
  _LocationNotesScreenState createState() => _LocationNotesScreenState();
}

class _LocationNotesScreenState extends State<LocationNotesScreen> {
  List<Map<String, dynamic>> _locationNotes = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadLocationNotes();
  }

  Future<void> _loadLocationNotes() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('location_notes');
      setState(() {
        _locationNotes = maps;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      await DatabaseHelper.instance.deleteLocationNote(id);
      _loadLocationNotes(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting note: $e')),
      );
    }
  }

  Future<void> _updateNote(Map<String, dynamic> note) async {
    try {
      await DatabaseHelper.instance.updateLocationNote(note);
      _loadLocationNotes(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _captureImage() async {
    final capturedFile = await _picker.pickImage(source: ImageSource.camera);
    if (capturedFile != null) {
      setState(() {
        _selectedImage = File(capturedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Location Notes',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _locationNotes.isEmpty
                ? Center(
                    child: Text('No location notes available'),
                  )
                : ListView.builder(
                    itemCount: _locationNotes.length,
                    itemBuilder: (context, index) {
                      final note = _locationNotes[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: note['image_path'] != null && File(note['image_path']).existsSync()
                              ? Image.file(
                                  File(note['image_path']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image, size: 50, color: Colors.grey),
                          title: Text(note['name'] ?? 'No Name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(note['address'] ?? 'No Address'),
                              Text(note['date'] ?? 'No Date'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                hoverColor: Colors.greenAccent,
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _editNoteDialog(context, note);
                                },
                              ),
                              IconButton(
                                hoverColor: Colors.redAccent,
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteNote(note['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
            onPressed: () {
              _addNoteDialog(context);
            },
            child: Text(
              'Add Notes',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNoteDialog(BuildContext context) async {
    final _nameController = TextEditingController();
    final _addressController = TextEditingController();
    File? _localImage;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Note', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 500,
            height: 230,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  SizedBox(height: 20),
                  _localImage != null
                      ? Image.file(_localImage!, height: 100, width: 100)
                      : Text('No image selected', style: TextStyle(color: Colors.redAccent)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              _localImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Text('Pick Image', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
                        onPressed: () async {
                          final capturedFile = await _picker.pickImage(source: ImageSource.camera);
                          if (capturedFile != null) {
                            setState(() {
                              _localImage = File(capturedFile.path);
                            });
                          }
                        },
                        child: Text('Capture Image', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
              onPressed: () async {
                await DatabaseHelper.instance.insertLocationNote({
                  'name': _nameController.text,
                  'address': _addressController.text,
                  'date': DateTime.now().toIso8601String(),
                  'image_path': _localImage?.path,
                });
                Navigator.pop(context);
                _loadLocationNotes();
              },
              child: Text('Save', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editNoteDialog(BuildContext context, Map<String, dynamic> note) async {
    final _nameController = TextEditingController(text: note['name']);
    final _addressController = TextEditingController(text: note['address']);
    File? _updatedImage = note['image_path'] != null ? File(note['image_path']) : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 20),
              _updatedImage != null
                  ? Image.file(_updatedImage!, height: 100, width: 100)
                  : Text('No image selected', style: TextStyle(color: Colors.redAccent)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
                    onPressed: () async {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          _updatedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Text('Pick Image', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.greenAccent)),
                    onPressed: () async {
                      final capturedFile = await _picker.pickImage(source: ImageSource.camera);
                      if (capturedFile != null) {
                        setState(() {
                          _updatedImage = File(capturedFile.path);
                        });
                      }
                    },
                    child: Text('Capture Image', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _updateNote({
                  'id': note['id'],
                  'name': _nameController.text,
                  'address': _addressController.text,
                  'image_path': _updatedImage?.path,
                });
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

class CreateLocationNoteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Location Note'),
      ),
      body: Center(
        child: Text('Create Note Screen'),
      ),
    );
  }
}
