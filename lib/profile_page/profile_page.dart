import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eco_pulse_ai/home_page/home_page.dart';
import 'package:eco_pulse_ai/login_Page/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  String? userName = '';
  String? userEmail = '';
  String? profileImageUrl;

  final String defaultImageUrl = 'https://picsum.photos/200/300';

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _checkUserAuthentication();
  }

  void _setDefaultProfileImage() async {
    final userId = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(userId).update({
      'profileImageUrl': defaultImageUrl,
    });

    setState(() {
      profileImageUrl = defaultImageUrl;
    });
  }

  // Check if the user is authenticated and load the profile
  void _checkUserAuthentication() async {
    User? user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? 'Name not available';
          userEmail = data['email'] ?? 'Email not available';
          profileImageUrl = data['profileImageUrl'] ?? "";
        });

        if (profileImageUrl == null || profileImageUrl!.isEmpty) {
          _setDefaultProfileImage();
        }
      } else {
        setState(() {
          userName = 'Name not found';
          userEmail = 'Email not found';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error fetching name';
        userEmail = 'Error fetching email';
      });
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _profileHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _actionButtons(),
                  SizedBox(height: 24),
                  _monthYearSelector(),
                  SizedBox(height: 24),
                  isLoading ? CircularProgressIndicator() : _chart(),
                  SizedBox(
                    height: 20,
                  ),
                  _Logout(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Logout() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        side: BorderSide(color: Colors.green.shade700),
      ),
      onPressed: () async {
        await _auth.signOut(); // Sign out the user
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // Remove all previous routes from the stack
        );
      },
      icon: Icon(Icons.logout, color: Colors.green.shade700),
      label: Text('Logout', style: TextStyle(color: Colors.green.shade700)),
    );
  }

  Widget _profileHeader() {
    return Stack(
      children: [
        Center(
          child: Column(
            children: [
              SizedBox(height: 40),
              CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : NetworkImage(defaultImageUrl),
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? Icon(Icons.person, size: 50) // Default icon
                    : null,
              ),
              SizedBox(height: 10),
              Text(
                userName ?? 'Loading...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                userEmail ?? 'Loading...',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showEditProfileDialog(context),
          icon: Icon(Icons.edit, color: Colors.red),
          label: Text('Edit Profile', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            side: BorderSide(color: Colors.red),
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showChangePasswordDialog(context),
          icon: Icon(Icons.lock, color: Colors.blue),
          label: Text('Change Password', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            side: BorderSide(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _monthYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Contribution : ",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () async {
            DateTime now = DateTime.now();
            DateTime lastSelectableDate =
                DateTime(now.year, now.month); // Current month only

            DateTime? picked = await showMonthPicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: lastSelectableDate, // Restrict future months
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
            setState(() => isLoading = false);
          },
          icon: Icon(Icons.calendar_month, color: Colors.green.shade700),
          label: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text: DateFormat.yMMM().format(selectedDate),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            side: BorderSide(color: Colors.green.shade700),
          ),
        ),
      ],
    );
  }

  // Fetch the chart data from Firebase
  Future<List<ChartData>> _fetchChartData() async {
    // Fetch user data from Firestore for the selected month/year
    CollectionReference dataCollection = _firestore.collection('userData');

    QuerySnapshot snapshot = await dataCollection
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .where('month', isEqualTo: selectedDate.month)
        .where('year', isEqualTo: selectedDate.year)
        .get();

    Map<String, double> categoryAmounts =
        {}; // To aggregate amounts by category

    for (var doc in snapshot.docs) {
      // Ensure that doc.data() returns a Map<String, dynamic>
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data.forEach((key, value) {
        if (['Electricity', 'Transport', 'Food', 'Water'].contains(key)) {
          // Aggregating values for each category
          if (categoryAmounts.containsKey(key)) {
            categoryAmounts[key] = categoryAmounts[key]! + value.toDouble();
          } else {
            categoryAmounts[key] = value.toDouble();
          }
        }
      });
    }

    List<ChartData> chartData = categoryAmounts.entries.map((entry) {
      return ChartData(entry.key, entry.value);
    }).toList();

    return chartData;
  }

  // Display the chart based on fetched data
  Widget _chart() {
    return FutureBuilder<List<ChartData>>(
      future: _fetchChartData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("No data available for this month.");
        }

        return SfCircularChart(
          title: ChartTitle(),
          legend: Legend(isVisible: true),
          series: <DoughnutSeries<ChartData, String>>[
            DoughnutSeries<ChartData, String>(
              dataSource: snapshot.data!,
              xValueMapper: (ChartData data, _) => data.department,
              yValueMapper: (ChartData data, _) => data.count,
              dataLabelSettings: DataLabelSettings(isVisible: true),
              explode: true,
              explodeIndex: 0,
            )
          ],
          tooltipBehavior: TooltipBehavior(enable: true),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    TextEditingController nameController =
        TextEditingController(text: userName);
    TextEditingController emailController =
        TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profile', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name', fillColor: Colors.black),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.black))),
            ElevatedButton(
              onPressed: () async {
                // Update Firestore with new name and email
                await _updateProfile(nameController.text, emailController.text);
                // Update FirebaseAuth email
                await _updateAuthEmail(emailController.text);
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(String name, String email) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
      });

      // Update local variables
      setState(() {
        userName = name;
        userEmail = email;
      });
    }
  }

  Future<void> _updateAuthEmail(String email) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateEmail(email);
        await user.reload(); // Refresh the user object after updating the email
      } catch (e) {
        // Handle any errors (e.g., invalid email format)
        print('Error updating email: $e');
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password', style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                decoration: InputDecoration(labelText: 'Old Password'),
                obscureText: true,
              ),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.black))),
            ElevatedButton(
              onPressed: () async {
                // Handle password change
                if (newPasswordController.text ==
                    confirmPasswordController.text) {
                  await _changePassword(newPasswordController.text);
                  Navigator.pop(context);
                } else {
                  // Handle mismatch
                }
              },
              child: Text('Save', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
      } catch (e) {
        // Handle password change errors
      }
    }
  }
}

class ChartData {
  ChartData(this.department, this.count);

  final String department;
  final double count;
}
