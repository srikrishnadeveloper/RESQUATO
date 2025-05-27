import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoadServicePage extends StatefulWidget {
  final String username;

  const RoadServicePage({super.key, required this.username});

  @override
  State<RoadServicePage> createState() => _RoadServicePageState();
}

class _RoadServicePageState extends State<RoadServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _customMessageController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _alternateNumberController = TextEditingController();
  final _customVehicleController = TextEditingController();

  String? _selectedVehicleType;
  String? _selectedProblemCategory;
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
      await supabase.from('road_service_requests').insert({
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
        'problem_category': _selectedProblemCategory,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Road service request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _locationController.clear();
        _customMessageController.clear();
        _phoneNumberController.clear();
        _alternateNumberController.clear();
        _customVehicleController.clear();
        setState(() {
          _selectedVehicleType = null;
          _selectedProblemCategory = null;
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
    _phoneNumberController.dispose();
    _alternateNumberController.dispose();
    _customVehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Road Service'), elevation: 4),
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
                    hintText: 'e.g., Vehicle model, specific instructions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                  maxLines: 3,
                ),
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
                const SizedBox(height: 20),
                const Text(
                  'Vehicle Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
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
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Problem Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Flat Tire',
                      child: Text('Flat Tire'),
                    ),
                    DropdownMenuItem(
                      value: 'Engine Issue',
                      child: Text('Engine Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'Battery Problem',
                      child: Text('Battery Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'Brake Failure',
                      child: Text('Brake Failure'),
                    ),
                    DropdownMenuItem(
                      value: 'Fuel Issue',
                      child: Text('Fuel Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'Overheating',
                      child: Text('Overheating'),
                    ),
                    DropdownMenuItem(
                      value: 'Transmission Issue',
                      child: Text('Transmission Issue'),
                    ),
                    DropdownMenuItem(
                      value: 'Suspension Problem',
                      child: Text('Suspension Problem'),
                    ),
                    DropdownMenuItem(
                      value: 'Electrical Issue',
                      child: Text('Electrical Issue'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProblemCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a problem category';
                    }
                    return null;
                  },
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
