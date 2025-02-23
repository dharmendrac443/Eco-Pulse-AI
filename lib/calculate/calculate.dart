import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CalculateScreen extends StatefulWidget {
  const CalculateScreen({super.key});

  @override 
  State<CalculateScreen> createState() => _CalculateState();
}

class _CalculateState extends State<CalculateScreen> {
  final Map<String, TextEditingController> controllers = {
    "LastMonthElectricity": TextEditingController(),
    "ThisMonthElectricity": TextEditingController(),
    "Electricity": TextEditingController(),
    "Transport": TextEditingController(),
    "Food": TextEditingController(),
    "Water": TextEditingController(),
  };
  bool isLoading = false;
  String? selectedCategory = 'Electricity'; // Default selected category
  String? selectedUsedTransport;
  String? selectedInsteadOfTransport;
  bool showAdditionalDetails = false;
  double? electricityCarbonFootprintResult;
  double? showElectricityCarbonFootprintResult;
  double? transportCarbonFootprintResult;
  double? showTransportCarbonFootprintResult;
  double? waterCarbonFootprintResult;
  double? showWaterCarbonFootprintResult;
  double? foodCarbonFootprintResult;
  double? showFoodCarbonFootprintResult;
  double? totalCarbonFootprintResult;

  // Vehicle hierarchy
  final List<String> vehicleHierarchy = [
    'Walk',
    'Cycle',
    'Bike',
    'Car',
    'Truck',
    'Aeroplane',
  ];

  // Vehicle icons
  final Map<String, IconData> vehicleIcons = {
    'Walk': Icons.directions_walk,
    'Cycle': Icons.directions_bike,
    'Bike': Icons.motorcycle,
    'Car': Icons.directions_car,
    'Truck': Icons.local_shipping,
    'Aeroplane': Icons.flight,
  };

  // Conversion factors
  final Map<String, double> transportEmissionFactors = {
    'Walk': 0.0,
    'Cycle': 0.0,
    'Bike': 0.1,
    'Car': 0.12,
    'Truck': 0.5,
    'Aeroplane': 0.2,
  };

  Future<void> _updateTotalContribution(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final monthlyRef = FirebaseFirestore.instance
        .collection('monthly')
        .where('userId', isEqualTo: userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final querySnapshot = await monthlyRef.get();

      double totalContribution = 0.0;
      for (var doc in querySnapshot.docs) {
        totalContribution +=
            (doc.data()['totalCarbonFootprint'] ?? 0).toDouble();
      }

      transaction.update(userRef, {
        'totalContributions': totalContribution,
      });
    });
  }

  Future<void> _updateMonthlyTotal(
      String userId, int year, int month, double newCarbonFootprint) async {
    final monthRef = FirebaseFirestore.instance
        .collection('monthly')
        .doc('$userId-$year-$month');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final monthSnapshot = await transaction.get(monthRef);
      double previousTotal = monthSnapshot.exists
          ? (monthSnapshot.data()?['totalCarbonFootprint'] ?? 0.0).toDouble()
          : 0.0;

      // Update monthly total directly
      transaction.set(
          monthRef,
          {
            'userId': userId,
            'year': year,
            'month': month,
            'totalCarbonFootprint': previousTotal + newCarbonFootprint,
          },
          SetOptions(merge: true));
    });

    // Update user's total contribution
    await _updateTotalContribution(userId);
  }

  // Save data to Firestore
  Future<void> saveData() async {
    final DateTime today = DateTime.now();
    final User? user = FirebaseAuth.instance.currentUser;
    await _updateStreak();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Prepare the data for all categories
      Map<String, double> categoryAmounts = {};

      for (var category in controllers.keys) {
        String valueText = controllers[category]!.text.trim();
        if (valueText.isNotEmpty) {
          double? amount = double.tryParse(valueText);
          if (amount != null && amount > 0) {
            categoryAmounts[category] = amount;
          }
        }
      }

      // Calculate carbon footprint

      if (categoryAmounts.containsKey('LastMonthElectricity') &&
          categoryAmounts.containsKey('ThisMonthElectricity')) {
        double lastMonthElectricity = categoryAmounts['LastMonthElectricity']!;
        double thisMonthElectricity = categoryAmounts['ThisMonthElectricity']!;
        double electricityDifference =
            lastMonthElectricity - thisMonthElectricity;
        if (electricityDifference < 0) electricityDifference = 0;
        categoryAmounts['Electricity'] = electricityDifference * 0.417;
// Kg CO₂ per KWh

        setState(() {
          electricityCarbonFootprintResult = electricityDifference * 0.417;
        });
      }

      if (categoryAmounts.containsKey('Transport') &&
          selectedUsedTransport != null &&
          selectedInsteadOfTransport != null) {
        double usedTransportEmission = categoryAmounts['Transport']! *
            transportEmissionFactors[selectedUsedTransport]!;
        double insteadOfTransportEmission = categoryAmounts['Transport']! *
            transportEmissionFactors[selectedInsteadOfTransport]!;
        double transportDifference =
            insteadOfTransportEmission - usedTransportEmission;
        categoryAmounts['Transport'] = transportDifference;

        setState(() {
          transportCarbonFootprintResult = transportDifference;
        });
      }

      if (categoryAmounts.containsKey('Food')) {
        double foodEmission = categoryAmounts['Food']! * 3.3;
        categoryAmounts['Food'] = foodEmission;

        setState(() {
          foodCarbonFootprintResult = foodEmission;
        });
      }

      if (categoryAmounts.containsKey('Water')) {
        double waterEmission = categoryAmounts['Water']! * 0.0003;
        categoryAmounts['Water'] = waterEmission;

        setState(() {
          waterCarbonFootprintResult = waterEmission;
        });
      }

      setState(() {
        totalCarbonFootprintResult = (electricityCarbonFootprintResult ?? 0) +
            (transportCarbonFootprintResult ?? 0) +
            (foodCarbonFootprintResult ?? 0) +
            (waterCarbonFootprintResult ?? 0);
      });

      if (categoryAmounts.isNotEmpty) {
        // Format today's date as a string (year-month-day)
        String todayString =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        // Check if data already exists for this user and date (compare by date string)
        var querySnapshot = await FirebaseFirestore.instance
            .collection('userData')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: todayString) // Compare by formatted date
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // If data exists, update the existing document
          var existingData = querySnapshot.docs.first.data();
          double existingElectricity =
              (existingData['Electricity'] ?? 0).toDouble();
          double existingTransport =
              (existingData['Transport'] ?? 0).toDouble();
          double existingFood = (existingData['Food'] ?? 0).toDouble();
          double existingWater = (existingData['Water'] ?? 0).toDouble();
          double existingCarbonFootprint =
              (existingData['carbonFootprint'] ?? 0).toDouble();
          // If data exists, update the existing document
          await FirebaseFirestore.instance
              .collection('userData')
              .doc(
                  querySnapshot.docs.first.id) // Get the existing document's ID
              .update({
            // ...categoryAmounts, // Update with the new category amounts
            'Transport':
                existingTransport + (transportCarbonFootprintResult ?? 0),
            'Electricity':
                existingElectricity + (electricityCarbonFootprintResult ?? 0),
            'Food': existingFood + (foodCarbonFootprintResult ?? 0),
            'Water': existingWater + (waterCarbonFootprintResult ?? 0),
            'carbonFootprint':
                existingCarbonFootprint + (totalCarbonFootprintResult ?? 0.0),
          });

          setState(() {
            showElectricityCarbonFootprintResult =
                (existingData['Electricity'] ?? 0).toDouble() +
                    (electricityCarbonFootprintResult ?? 0);
            showTransportCarbonFootprintResult =
                (existingData['Transport'] ?? 0).toDouble() +
                    (transportCarbonFootprintResult ?? 0);
            showFoodCarbonFootprintResult =
                (existingData['Food'] ?? 0).toDouble() +
                    (foodCarbonFootprintResult ?? 0);
            showWaterCarbonFootprintResult =
                (existingData['Water'] ?? 0).toDouble() +
                    (waterCarbonFootprintResult ?? 0);

            transportCarbonFootprintResult = 0;
            electricityCarbonFootprintResult = 0;
            foodCarbonFootprintResult = 0;
            waterCarbonFootprintResult = 0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data updated successfully!')),
          );
        } else {
          // If no existing data, create a new document
          await FirebaseFirestore.instance.collection('userData').add({
            'userId': user.uid,
            'date': todayString, // Store the date as a string
            'month': today.month,
            'year': today.year,
            // ...categoryAmounts, // Add the categories and amounts
            'Transport': (categoryAmounts['Transport']?? 0).toDouble(),
            'Electricity': (categoryAmounts['Electricity']?? 0).toDouble(),
            'Food': (categoryAmounts['Food']?? 0).toDouble(),
            'Water': (categoryAmounts['Water']?? 0).toDouble(),
            'carbonFootprint': (totalCarbonFootprintResult?? 0).toDouble(),
          });

          setState(() {
            showElectricityCarbonFootprintResult =
                categoryAmounts['Electricity'];
            showTransportCarbonFootprintResult = categoryAmounts['Transport'];
            showFoodCarbonFootprintResult = categoryAmounts['Food'];
            showWaterCarbonFootprintResult = categoryAmounts['Water'];

            transportCarbonFootprintResult = 0;
            electricityCarbonFootprintResult = 0;
            foodCarbonFootprintResult = 0;
            waterCarbonFootprintResult = 0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data added successfully!')),
          );
        }

        if (totalCarbonFootprintResult != null) {
          await _updateMonthlyTotal(
              user.uid, today.year, today.month, totalCarbonFootprintResult!);
          setState(() {
            totalCarbonFootprintResult = 0;
          });
        }

        // Clear inputs after saving
        for (var controller in controllers.values) {
          controller.clear();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please enter values for at least one category.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateStreak() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('streak').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      if (!snapshot.exists) {
        // First entry for the user
        transaction.set(userDoc, {
          'currentStreak': 1,
          'maxStreak': 1,
          'lastLogin': Timestamp.fromDate(today),
        });
        return;
      }

      Map<String, dynamic> data = snapshot.data()!;
      int currentStreak = data['currentStreak'] ?? 0;
      int maxStreak = data['maxStreak'] ?? 0;
      DateTime lastLogin =
          (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime(2000);
      DateTime lastLoginDate =
          DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

      if (lastLoginDate == today.subtract(const Duration(days: 1))) {
        // Consecutive day: Increment streak
        currentStreak += 1;
      } else if (lastLoginDate
          .isBefore(today.subtract(const Duration(days: 1)))) {
        // Missed a day: Reset streak
        currentStreak = 1;
      }

      // Update max streak if needed
      maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;

      transaction.update(userDoc, {
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'lastLogin': Timestamp.fromDate(today),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculate your carbon footprint',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Container(
                  height: 300,
                  width: 300,
                  child: GridView.count(
                    crossAxisCount: 2, // Ensures two categories per row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true, // Makes GridView fit inside the Column
                    physics:
                        NeverScrollableScrollPhysics(), // Prevents internal scrolling
                    children: [
                      _buildCategoryBox(
                        'Electricity',
                        Icon(Icons.electrical_services,
                            size: 50, color: Colors.green),
                      ),
                      _buildCategoryBox(
                        'Transport',
                        Icon(Icons.directions_car,
                            size: 50, color: Colors.green),
                      ),
                      _buildCategoryBox(
                        'Water',
                        Icon(Icons.water, size: 50, color: Colors.green),
                      ),
                      _buildCategoryBox(
                        'Food',
                        Icon(Icons.fastfood, size: 50, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 26),
              if (selectedCategory != null) ...[
                if (selectedCategory == 'Electricity') ...[
                  _buildElectricityOptions(),
                ] else if (selectedCategory == 'Transport') ...[
                  _buildTransportOptions(),
                ] else if (selectedCategory == 'Water') ...[
                  _buildWaterOptions(),
                ] else if (selectedCategory == 'Food') ...[
                  _buildFoodOptions(),
                ],
                SizedBox(height: 26),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[100],
                          iconColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Calculate',
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                SizedBox(height: 20),
                if (showElectricityCarbonFootprintResult != null ||
                    showTransportCarbonFootprintResult != null ||
                    showWaterCarbonFootprintResult != null ||
                    showFoodCarbonFootprintResult != null) ...[
                  Text(
                    'Carbon Footprint Saved by',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  if (showElectricityCarbonFootprintResult != null)
                    _buildFootprintItem(
                        'Electricity', showElectricityCarbonFootprintResult!),
                  if (showTransportCarbonFootprintResult != null)
                    _buildFootprintItem(
                        'Transport', showTransportCarbonFootprintResult!),
                  if (showWaterCarbonFootprintResult != null)
                    _buildFootprintItem(
                        'Water', showWaterCarbonFootprintResult!),
                  if (showFoodCarbonFootprintResult != null)
                    _buildFootprintItem('Food', showFoodCarbonFootprintResult!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBox(String category, Icon icon) {
    bool isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          selectedUsedTransport = null;
          selectedInsteadOfTransport = null;
        });
      },
      child: Container(
        height: 120,
        width: 120,
        child: Card(
          color: Colors.white,
          elevation: isSelected ? 5 : 2,
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: 24,
                ),
                icon,
                SizedBox(height: 8),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.black,
                    //fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElectricityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controllers['LastMonthElectricity'],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'KWh',
            hintText: 'Enter last month Units',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.grey, width: 1), // Default border
            ),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: controllers['ThisMonthElectricity'],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'KWh',
            hintText: 'Enter this month Units',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.grey, width: 1), // Default border
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Select Used Transport',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.grey, width: 1), // Default border
            ),
          ),
          value: selectedUsedTransport,
          onChanged: (String? newValue) {
            setState(() {
              selectedUsedTransport = newValue;
              selectedInsteadOfTransport = null; // Reset instead of transport
            });
          },
          items: vehicleHierarchy.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(vehicleIcons[value], size: 24),
                  SizedBox(width: 8),
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        if (selectedUsedTransport != null)
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Instead Of Transport',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: Colors.grey, width: 1), // Default border
              ),
            ),
            value: selectedInsteadOfTransport,
            onChanged: (String? newValue) {
              setState(() {
                selectedInsteadOfTransport = newValue;
              });
            },
            items: vehicleHierarchy
                .where((vehicle) =>
                    vehicleHierarchy.indexOf(vehicle) >
                    vehicleHierarchy.indexOf(selectedUsedTransport!))
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(vehicleIcons[value], size: 24),
                    SizedBox(width: 8),
                    Text(value),
                  ],
                ),
              );
            }).toList(),
          ),
        SizedBox(height: 10),
        TextField(
          controller: controllers['Transport'],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'Km',
            hintText: 'Enter kilometers traveled',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.grey, width: 1), // Default border
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterOptions() {
    return TextField(
      controller: controllers['Water'],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        suffixText: 'L',
        hintText: 'Enter how much water saved',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: Colors.grey, width: 1), // Default border
        ),
      ),
    );
  }

  Widget _buildFoodOptions() {
    return TextField(
      controller: controllers['Food'],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        suffixText: 'Kg',
        hintText: 'Enter how much food saved',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: Colors.grey, width: 1), // Default border
        ),
      ),
    );
  }

  Widget _buildFootprintItem(String category, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '$category: ${value.toStringAsFixed(2)} kg CO₂', // Format value to 2 decimal places
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
