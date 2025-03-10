import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Payment {
  final double amount;
  final String method;
  final DateTime dateTime;

  Payment({
    required this.amount,
    required this.method,
    required this.dateTime,
  });
}

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  // Controllers for each text field
  final TextEditingController terrainController = TextEditingController();
  final TextEditingController surfaceController = TextEditingController();
  final TextEditingController ppmController = TextEditingController();
  final TextEditingController fraisController = TextEditingController();
  final TextEditingController prixTotalController = TextEditingController();
  final TextEditingController payerController = TextEditingController();
  final TextEditingController resteController = TextEditingController();
  final TextEditingController methodePaymentController = TextEditingController();
  
  // Values for calculations
  double surface = 0;
  double ppm = 0;
  double frais = 0;
  double prixTotal = 0;
  double payer = 0;
  double reste = 0;
  String paymentMethod = '';
  
  // List to store payment history
  List<Payment> payments = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with default values
    prixTotalController.text = "0.00";
    resteController.text = "0.00";
    
    // Add listeners to update calculations
    surfaceController.addListener(_updateSurface);
    ppmController.addListener(_updatePPM);
    fraisController.addListener(_updateFrais);
  }

  void _updateSurface() {
    setState(() {
      try {
        // Extract numeric value, removing any non-numeric characters
        String numericText = surfaceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
        surface = numericText.isEmpty ? 0 : double.parse(numericText);
      } catch (e) {
        surface = 0;
      }
      _calculatePrixTotal();
    });
  }

  void _updatePPM() {
    setState(() {
      try {
        ppm = ppmController.text.isEmpty ? 0 : double.parse(ppmController.text);
      } catch (e) {
        ppm = 0;
      }
      _calculatePrixTotal();
    });
  }

  void _updateFrais() {
    setState(() {
      try {
        frais = fraisController.text.isEmpty ? 0 : double.parse(fraisController.text);
      } catch (e) {
        frais = 0;
      }
      _calculatePrixTotal();
    });
  }

  void _calculatePrixTotal() {
    setState(() {
      prixTotal = (surface * ppm) + frais;
      prixTotalController.text = prixTotal.toStringAsFixed(2);
      _updateReste();
    });
  }

  void _updateReste() {
    setState(() {
      payer = 0;
      // Sum all payments
      for (var payment in payments) {
        payer += payment.amount;
      }
      
      payerController.text = payer.toStringAsFixed(2);
      
      // Update payment method text
      if (payments.isNotEmpty) {
        List<String> methods = payments.map((p) => p.method).toSet().toList();
        methodePaymentController.text = methods.join(', ');
      } else {
        methodePaymentController.text = '';
      }
      
      reste = prixTotal - payer;
      resteController.text = reste.toStringAsFixed(2);
    });
  }

  void _showPaymentHistoryDialog() {
    if (payments.isEmpty) {
      // If no payments, show add payment dialog directly
      _showAddPaymentDialog();
      return;
    }
    
    // Show payment history dialog
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: payments.map((payment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${payment.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    payment.method,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(payment.dateTime),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${payer.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Add Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddPaymentDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPaymentDialog() {
    final TextEditingController amountController = TextEditingController();
    String selectedMethod = 'Cash';
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: amountController,
                    placeholder: 'Amount',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    padding: const EdgeInsets.all(10),
                    style: const TextStyle(color: Colors.white),
                    placeholderStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedMethod = 'Cash';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedMethod == 'Cash'
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Cash',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedMethod = 'Bank';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedMethod == 'Bank'
                                  ? const Color(0xFF0A84FF)
                                  : const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Bank',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Color(0xFF0A84FF),
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          if (amountController.text.isNotEmpty) {
                            try {
                              double amount = double.parse(amountController.text);
                              setState(() {
                                // Add new payment to the list
                                payments.add(Payment(
                                  amount: amount,
                                  method: selectedMethod,
                                  dateTime: DateTime.now(),
                                ));
                                
                                // Update calculations
                                _updateReste();
                              });
                              Navigator.pop(context);
                            } catch (e) {
                              // Show error if amount is not a valid number
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid amount'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Remove listeners
    surfaceController.removeListener(_updateSurface);
    ppmController.removeListener(_updatePPM);
    fraisController.removeListener(_updateFrais);
    
    // Clean up controllers
    terrainController.dispose();
    surfaceController.dispose();
    ppmController.dispose();
    fraisController.dispose();
    prixTotalController.dispose();
    payerController.dispose();
    resteController.dispose();
    methodePaymentController.dispose();
    super.dispose();
  }

  Widget _buildTableCell(String label, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, FocusNode? focusNode}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        onChanged: (value) {
          // For Surface field, add m² when typing stops
          if (label == 'Surface' && value.isNotEmpty && !value.endsWith(' m²')) {
            // Only add m² if we're not already in the process of editing
            if (!value.contains(' m²')) {
              // Extract numeric part
              String numericPart = value.replaceAll(RegExp(r'[^0-9.]'), '');
              if (numericPart.isNotEmpty) {
                // Schedule this after the current frame to avoid text selection issues
                Future.delayed(Duration.zero, () {
                  // Save current cursor position
                  final cursorPos = controller.selection.baseOffset;
                  // Update text with m² suffix
                  controller.text = '$numericPart m²';
                  // Restore cursor to before the suffix
                  if (cursorPos <= numericPart.length) {
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: cursorPos),
                    );
                  }
                });
              }
            }
          }
        },
        onEditingComplete: () {
          FocusScope.of(context).nextFocus();
        },
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF0A84FF)),
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Purchase',
          style: TextStyle(color: Colors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF0A84FF),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Table header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTableCell('Terrain', terrainController),
                        _buildTableCell(
                          'Surface', 
                          surfaceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]|m²')),
                          ],
                        ),
                        _buildTableCell(
                          'P.P.M', 
                          ppmController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                        _buildTableCell(
                          'Frais', 
                          fraisController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                        ),
                        _buildTableCell('Prix Total', prixTotalController, readOnly: true),
                        _buildTableCell('Payer', payerController, readOnly: true, onTap: _showPaymentHistoryDialog),
                        _buildTableCell('Reste', resteController, readOnly: true),
                        _buildTableCell('Methode de Payment', methodePaymentController, readOnly: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
