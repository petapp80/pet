import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For File handling

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController petTypeController = TextEditingController();
  TextEditingController breedController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController sexController = TextEditingController();
  TextEditingController colourController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController aboutController = TextEditingController();

  File? _selectedFile;
  String _selectedCurrency = 'USD'; // Currency selection

  // Function to pick a file using FilePicker
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic'], // allowed file types
    );

    if (result != null) {
      setState(() {
        // Assign the selected file
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // Function to remove the selected file
  void _removeFile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("File Canceled"),
      duration: Duration(seconds: 1),
    ));
    setState(() {
      _selectedFile = null; // Remove the selected file
    });
  }

  // Date picker for Age
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        ageController.text =
            '${picked.toLocal()}'.split(' ')[0]; // Format as yyyy-mm-dd
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Pet Type
              TextFormField(
                controller: petTypeController,
                decoration: const InputDecoration(
                  labelText: 'Pet Type',
                  icon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pet type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Breed
              TextFormField(
                controller: breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  icon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the breed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Age (Using Date Picker)
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  icon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the age';
                  }
                  return null;
                },
                readOnly:
                    true, // Make it read-only so the user clicks to select a date
                onTap: () =>
                    _selectDate(context), // Show date picker when tapped
              ),
              const SizedBox(height: 10),

              // Sex
              TextFormField(
                controller: sexController,
                decoration: const InputDecoration(
                  labelText: 'Sex',
                  icon: Icon(Icons.male),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the sex';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Colour
              TextFormField(
                controller: colourController,
                decoration: const InputDecoration(
                  labelText: 'Colour',
                  icon: Icon(Icons.color_lens),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the colour';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Weight
              TextFormField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  icon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the weight';
                  } else if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Location
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  icon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Price
              Row(
                children: [
                  // Currency Dropdown Button
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCurrency = newValue!;
                      });
                    },
                    items: <String>['USD', 'INR']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  // Price Input Field
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        icon: _selectedCurrency == 'USD'
                            ? const Icon(Icons.attach_money)
                            : const Icon(Icons.currency_rupee),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the price';
                        } else if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // About (Multi-line text area)
              TextFormField(
                controller: aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some details about the pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // File Selection Button
              ElevatedButton(
                onPressed: _pickFile,
                child: Text(_selectedFile == null
                    ? 'Select Image'
                    : 'File Selected: ${_selectedFile!.path.split('/').last}'),
              ),
              const SizedBox(height: 10),

              // Display selected file with close button
              if (_selectedFile != null)
                Center(
                  child: Stack(
                    alignment: Alignment.topRight, // Close button at top right
                    children: [
                      // Displaying the selected file as an image
                      Image.file(
                        _selectedFile!,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                      // Close button positioned above the image
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              // Publish Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publishing...')),
                    );
                    // You can add your publishing logic here (e.g., send data to a backend)
                  }
                },
                child: const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
