import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:permission_handler/permission_handler.dart'; // Import permission handler
import 'package:geocoding/geocoding.dart'; // Import geocoding package

class FuelDeliveryPage extends StatefulWidget {
  final dynamic username; // Accept dynamic username

  const FuelDeliveryPage({super.key, required this.username});

  @override
  State<FuelDeliveryPage> createState() => _FuelDeliveryPageState();
}

class _FuelDeliveryPageState extends State<FuelDeliveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _customMessageController = TextEditingController();
  final _fuelQuantityController = TextEditingController();
  final _paymentAmountController = TextEditingController();

  String? _selectedFuelType;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true; // Show loader while fetching location
    });
    try {
      // Check and request location permissions
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

        // Fetch address using reverse geocoding
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
          _locationController.text = address; // Display full address
        });
      } else if (status.isDenied || status.isPermanentlyDenied) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Location permission denied. Please allow location access.",
            ),
          ),
        );
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
      // Check if fuel type is selected, as it's not part of form validation
      if (_selectedFuelType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a fuel type.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final fuelQuantity = double.tryParse(_fuelQuantityController.text);
    final paymentAmount = double.tryParse(_paymentAmountController.text);

    if (fuelQuantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid fuel quantity.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (paymentAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment amount.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await supabase.from('fuel_requests').insert({
        'username': widget.username,
        'location_text': _locationController.text, // Send location text
        'latitude': _latitude, // Send latitude
        'longitude': _longitude, // Send longitude
        'custom_message':
            _customMessageController.text.isEmpty
                ? null
                : _customMessageController.text,
        'fuel_quantity': fuelQuantity,
        'fuel_type': _selectedFuelType,
        'payment_amount': paymentAmount,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _locationController.clear();
        _customMessageController.clear();
        _fuelQuantityController.clear();
        _paymentAmountController.clear();
        setState(() {
          _selectedFuelType = null;
          _latitude = null;
          _longitude = null;
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
    _fuelQuantityController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fuel Delivery - ${widget.username}')),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ), // Adjust padding
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter or fetch your location';
                    }
                    return null;
                  },
                  minLines: 1,
                  maxLines: 1, // Reduce maxLines to minimize height
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : _fetchLocation, // Disable button when loading
                  icon:
                      _isLoading && _locationController.text.isEmpty
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
                    style: TextStyle(color: Colors.white), // White text
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Blue background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Box-like appearance
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  controller: _fuelQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Quantity',
                    hintText: 'e.g., 10',
                    border: OutlineInputBorder(),
                    suffixText: 'liters',
                    prefixIcon: Icon(Icons.local_gas_station_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fuel quantity';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Please enter a valid quantity (e.g., 1, 5, 10)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fuel Type:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Petrol'),
                        value: 'Petrol',
                        groupValue: _selectedFuelType,
                        onChanged: (value) {
                          setState(() {
                            _selectedFuelType = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Diesel'),
                        value: 'Diesel',
                        groupValue: _selectedFuelType,
                        onChanged: (value) {
                          setState(() {
                            _selectedFuelType = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentAmountController,
                  decoration: InputDecoration(
                    labelText: 'Estimated Payment Amount',
                    hintText: 'e.g., 50',
                    border: const OutlineInputBorder(),
                    prefixText:
                        '${Theme.of(context).brightness == Brightness.dark ? "₹" : "₹"} ', // Currency symbol
                    prefixIcon: const Icon(
                      Icons.currency_rupee_outlined,
                    ), // Or Icons.attach_money
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payment amount';
                    }
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Please enter a valid amount (e.g., 10, 50, 100)';
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
                        backgroundColor: Colors.blue, // Blue accent color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // No rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                      label: const Text(
                        'Send Request',
                        style: TextStyle(
                          color: Colors.white,
                        ), // Ensure text is white
                      ),
                    ),
                const SizedBox(height: 20), // Add some padding at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
