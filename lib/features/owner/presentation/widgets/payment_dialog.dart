import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final double amount;
  final String title;
  final Function(String reference, String paymentMethod) onConfirm;

  const PaymentDialog({
    super.key,
    required this.amount,
    required this.title,
    required this.onConfirm,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _referenceController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Mobile Banking',
    'Check',
    'Other',
  ];

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Colors.blue[600], size: 20),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Display
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Settlement Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '৳${widget.amount.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.amount > 0
                            ? Colors.red[700]
                            : widget.amount < 0
                            ? Colors.green[700]
                            : Colors.blue[700],
                      ),
                    ),
                    Text(
                      widget.amount > 0
                          ? '(Due from Tenant)'
                          : widget.amount < 0
                          ? '(Refund to Tenant)'
                          : '(Settled - No Payment Required)',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.amount > 0
                            ? Colors.red[600]
                            : widget.amount < 0
                            ? Colors.green[600]
                            : Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Payment Method
              Text(
                widget.amount == 0 ? 'Payment Method' : 'Payment Method *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.payment,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue!;
                    });
                  },
                ),
              ),
              SizedBox(height: 8),

              // Reference Number
              Text(
                widget.amount == 0
                    ? 'Reference Number (Optional)'
                    : 'Reference Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  hintText: 'Enter reference number (optional)',
                  prefixIcon: Icon(
                    Icons.receipt,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            // Show loading state
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Processing payment...')),
                  ],
                ),
                backgroundColor: Colors.blue[600],
                duration: Duration(seconds: 2),
              ),
            );

            widget.onConfirm(_referenceController.text, _selectedPaymentMethod);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Confirm Payment'),
        ),
      ],
    );
  }
}
