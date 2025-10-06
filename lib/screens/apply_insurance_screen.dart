import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class ApplyInsuranceScreen extends StatefulWidget {
  const ApplyInsuranceScreen({super.key});

  @override
  State<ApplyInsuranceScreen> createState() => _ApplyInsuranceScreenState();
}

class _ApplyInsuranceScreenState extends State<ApplyInsuranceScreen> with TickerProviderStateMixin {
  late AnimationController _splashController;
  late Animation<Offset> _upwardAnimation;

  final _idFocusNode = FocusNode();
  final _contactFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  bool _isIdFocused = false;
  bool _isContactFocused = false;
  bool _isAddressFocused = false;

  bool _infoConfirmed = false;
  bool _termsAgreed = false;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _upwardAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _splashController, curve: Curves.easeOut));
    _splashController.forward();
  }

  @override
  void dispose() {
    _splashController.dispose();
    _idFocusNode.dispose();
    _contactFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context) ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)) : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _splashController,
          builder: (context, child) {
            return SlideTransition(
              position: _upwardAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    colors: [Colors.grey[900]!, Colors.grey[800]!, Colors.grey[400]!],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Finalize Application",
                            style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Step 2 of 2",
                            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(30).copyWith(bottom: 80), // Padding for BottomNavigationBar
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 40),
                              Text(
                                "Personal Verification",
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                  boxShadow: _isIdFocused
                                      ? [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 0))]
                                      : [],
                                ),
                                transform: Matrix4.identity()..scale(_isIdFocused ? 1.05 : 1.0),
                                child: TextField(
                                  focusNode: _idFocusNode,
                                  decoration: InputDecoration(
                                    labelText: "ID Number or Passport Number",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                  onTap: () => setState(() => _isIdFocused = true),
                                ),
                              ),
                              const SizedBox(height: 15),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                  boxShadow: _isContactFocused
                                      ? [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 0))]
                                      : [],
                                ),
                                transform: Matrix4.identity()..scale(_isContactFocused ? 1.05 : 1.0),
                                child: TextField(
                                  focusNode: _contactFocusNode,
                                  decoration: InputDecoration(
                                    labelText: "Contact Number",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                  onTap: () => setState(() => _isContactFocused = true),
                                ),
                              ),
                              const SizedBox(height: 15),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                                  boxShadow: _isAddressFocused
                                      ? [BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 0))]
                                      : [],
                                ),
                                transform: Matrix4.identity()..scale(_isAddressFocused ? 1.05 : 1.0),
                                child: TextField(
                                  focusNode: _addressFocusNode,
                                  decoration: InputDecoration(
                                    labelText: "Residential Address",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.9),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                  onTap: () => setState(() => _isAddressFocused = true),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Document Uploads",
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20),
                              ListTile(
                                leading: const Icon(Icons.upload_file),
                                title: Text("ID/Driver’s License", style: GoogleFonts.poppins()),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
                                  child: Text("Upload", style: GoogleFonts.poppins(color: Colors.white)),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                leading: const Icon(Icons.upload_file),
                                title: Text("Proof of Address", style: GoogleFonts.poppins()),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
                                  child: Text("Upload", style: GoogleFonts.poppins(color: Colors.white)),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: Text("Vehicle Photos", style: GoogleFonts.poppins()),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
                                  child: Text("Upload", style: GoogleFonts.poppins(color: Colors.white)),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                leading: const Icon(Icons.book),
                                title: Text("Vehicle Logbook or Registration Papers", style: GoogleFonts.poppins()),
                                trailing: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900]),
                                  child: Text("Upload (Optional)", style: GoogleFonts.poppins(color: Colors.white)),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Declaration",
                                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20),
                              CheckboxListTile(
                                title: Text("I confirm all information is true and accurate", style: GoogleFonts.poppins()),
                                value: _infoConfirmed,
                                onChanged: (value) => setState(() => _infoConfirmed = value ?? false),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                              CheckboxListTile(
                                title: Text("I agree to the Terms & Conditions", style: GoogleFonts.poppins()),
                                value: _termsAgreed,
                                onChanged: (value) => setState(() => _termsAgreed = value ?? false),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                              const SizedBox(height: 30),
                              Center(
                                child: ElevatedButton(
                                  onPressed: _infoConfirmed && _termsAgreed
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const HomeScreen(username: '')),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[900],
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: Text(
                                    "Submit Application",
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}