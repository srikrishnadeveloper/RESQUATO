import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookServicePage extends StatefulWidget {
  final String username;

  const BookServicePage({super.key, required this.username});

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _customMessageController = TextEditingController();
  final _customVehicleController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _alternateNumberController = TextEditingController();

  String? _selectedVehicleType;
  String? _selectedTimeSlot;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isCustomVehicleVisible = false;
  double? _latitude;
  double? _longitude;

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Location services are disabled. Please enable them.",
              ),
              action: SnackBarAction(
                label: "Enable",
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        String address =
            placemarks.isNotEmpty
                ? "${placemarks.first.name}, ${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.administrativeArea}, ${placemarks.first.country}"
                : "Address not found";

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text = address;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Location permission denied.")));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch location: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    try {
      await supabase.from('book_service_requests').insert({
        'username': widget.username,
        'location_text': _locationController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'custom_message':
            _customMessageController.text.isEmpty
                ? null
                : _customMessageController.text,
        'phone_number': _phoneNumberController.text,
        'alternate_number':
            _alternateNumberController.text.isEmpty
                ? null
                : _alternateNumberController.text,
        'vehicle_type':
            _selectedVehicleType == 'Custom'
                ? _customVehicleController.text
                : _selectedVehicleType,
        'preferred_date': _selectedDate?.toIso8601String(),
        'preferred_time_slot': _selectedTimeSlot,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _locationController.clear();
        _customMessageController.clear();
        _customVehicleController.clear();
        _phoneNumberController.clear();
        _alternateNumberController.clear();
        setState(() {
          _selectedVehicleType = null;
          _selectedTimeSlot = null;
          _selectedDate = null;
          _latitude = null;
          _longitude = null;
          _isCustomVehicleVisible = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _customMessageController.dispose();
    _customVehicleController.dispose();
    _phoneNumberController.dispose();
    _alternateNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service'), elevation: 4),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location Address',
                    hintText: 'Enter address or fetch coordinates',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {
                          _latitude = null;
                          _longitude = null;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter or fetch your location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchLocation,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.my_location, color: Colors.white),
                  label: const Text(
                    'Fetch Current Location',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _customMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Message (Optional)',
                    hintText: 'e.g., Specific instructions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Preferred Date:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Blue background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Box-like appearance
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : 'Selected Date: ${_selectedDate!.toLocal()}'.split(
                          ' ',
                        )[0],
                    style: const TextStyle(color: Colors.white), // White text
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Preferred Time Slot:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Time Slot',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '9:00 AM - 12:00 PM',
                      child: Text('9:00 AM - 12:00 PM'),
                    ),
                    DropdownMenuItem(
                      value: '12:00 PM - 3:00 PM',
                      child: Text('12:00 PM - 3:00 PM'),
                    ),
                    DropdownMenuItem(
                      value: '3:00 PM - 6:00 PM',
                      child: Text('3:00 PM - 6:00 PM'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeSlot = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a time slot';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vehicle Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Car', child: Text('Car')),
                    DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                  ],
                  value: _selectedVehicleType,
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleType = value;
                      _isCustomVehicleVisible = value == 'Custom';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a vehicle type';
                    }
                    return null;
                  },
                ),
                if (_isCustomVehicleVisible) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customVehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Vehicle Type',
                      hintText: 'Enter your vehicle type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_selectedVehicleType == 'Custom' &&
                          (value == null || value.isEmpty)) {
                        return 'Please enter your custom vehicle type';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _alternateNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Alternate Phone Number (Optional)',
                    hintText: 'Enter an alternate phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      label: const Text(
                        'Send Request',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
