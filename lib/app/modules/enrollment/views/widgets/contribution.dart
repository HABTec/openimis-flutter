import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/local/services/enhanced_contribution_service.dart';
import '../../../../di/locator.dart';

class EnhancedContributionWidget extends StatefulWidget {
  final String? selectedMembershipTypeId;
  final List<Map<String, dynamic>> familyMembers;
  final Function(double amount, String breakdown)? onCalculationComplete;

  const EnhancedContributionWidget({
    Key? key,
    this.selectedMembershipTypeId,
    this.familyMembers = const [],
    this.onCalculationComplete,
  }) : super(key: key);

  @override
  _EnhancedContributionWidgetState createState() =>
      _EnhancedContributionWidgetState();
}

class _EnhancedContributionWidgetState
    extends State<EnhancedContributionWidget> {
  final EnhancedContributionService _contributionService =
      getIt.get<EnhancedContributionService>();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();

  ContributionBreakdown? _currentBreakdown;
  bool _isCalculating = false;
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _calculateContribution();
  }

  @override
  void didUpdateWidget(EnhancedContributionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMembershipTypeId != widget.selectedMembershipTypeId ||
        oldWidget.familyMembers != widget.familyMembers) {
      _calculateContribution();
    }
  }

  Future<void> _calculateContribution() async {
    if (widget.selectedMembershipTypeId == null ||
        widget.familyMembers.isEmpty) {
      setState(() {
        _currentBreakdown = null;
      });
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      // Convert family members to calculation format
      List<FamilyMemberForCalculation> members =
          widget.familyMembers.map((member) {
        return FamilyMemberForCalculation(
          name: '${member['givenName'] ?? ''} ${member['lastName'] ?? ''}',
          age: member['age'] ??
              FamilyMemberForCalculation.calculateAge(member['dob'] ?? ''),
          isHead: member['isHead'] ?? false,
          disabled: member['disabled'] ?? false,
        );
      }).toList();

      final result = await _contributionService.calculateContribution(
        membershipTypeId: widget.selectedMembershipTypeId!,
        familyMembers: members,
      );

      setState(() {
        if (result.success) {
          _currentBreakdown = result.breakdown;
          _amountPaidController.text =
              result.breakdown!.totalAmount.toStringAsFixed(2);

          // Notify parent widget
          widget.onCalculationComplete?.call(
            result.breakdown!.totalAmount,
            result.breakdown!.getFormattedBreakdown(),
          );
        } else {
          _currentBreakdown = null;
          Get.snackbar(
              'Calculation Error', result.errorMessage ?? 'Unknown error');
        }
      });
    } catch (e) {
      setState(() {
        _currentBreakdown = null;
      });
      Get.snackbar('Error', 'Failed to calculate contribution: $e');
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contribution Calculation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_currentBreakdown != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showBreakdown = !_showBreakdown;
                      });
                    },
                    icon: Icon(
                        _showBreakdown ? Icons.expand_less : Icons.expand_more),
                    label:
                        Text(_showBreakdown ? 'Hide Details' : 'Show Details'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCalculating)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_currentBreakdown == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 48, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      'Select membership type and add family members to calculate contribution',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else ...[
              // Total amount display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentBreakdown!.totalAmount.toStringAsFixed(2)} ETB',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rate legend
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premium Rate: ${_currentBreakdown!.premiumAdultRate.toStringAsFixed(2)} ETB per adult',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showBreakdown) ...[
                const SizedBox(height: 16),
                _buildDetailedBreakdown(),
              ],

              const SizedBox(height: 16),

              // Payment inputs
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountPaidController,
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        suffixText: 'ETB',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _receiptController,
                      decoration: const InputDecoration(
                        labelText: 'Receipt Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Member contributions table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildTableHeader('Member'),
                  _buildTableHeader('Role'),
                  _buildTableHeader('Amount'),
                ],
              ),
              ...(_currentBreakdown!.memberBreakdowns
                  .map((member) => TableRow(
                        children: [
                          _buildTableCell(member.memberName),
                          _buildTableCell(member.isHead ? 'Head' : 'Member'),
                          _buildTableCell(
                              '${member.amount.toStringAsFixed(2)} ETB'),
                        ],
                      ))
                  .toList()),
              TableRow(
                decoration: BoxDecoration(color: Colors.blue.shade50),
                children: [
                  _buildTableCell('Members Total', bold: true),
                  _buildTableCell(''),
                  _buildTableCell(
                      '${_currentBreakdown!.memberContributions.toStringAsFixed(2)} ETB',
                      bold: true),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Fees breakdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildTableHeader('Fee Type'),
                  _buildTableHeader('Amount'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Registration Fee'),
                  _buildTableCell(
                      '${_currentBreakdown!.registrationFee.toStringAsFixed(2)} ETB'),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('Lump Sum'),
                  _buildTableCell(
                      '${_currentBreakdown!.lumpSum.toStringAsFixed(2)} ETB'),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade50),
                children: [
                  _buildTableCell('TOTAL', bold: true),
                  _buildTableCell(
                      '${_currentBreakdown!.totalAmount.toStringAsFixed(2)} ETB',
                      bold: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style:
            TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        textAlign: TextAlign.center,
      ),
    );
  }

  String get receiptNumber => _receiptController.text;
  double get amountPaid => double.tryParse(_amountPaidController.text) ?? 0.0;
}

// Keep the old widget for backward compatibility
class Contribution extends StatefulWidget {
  const Contribution({Key? key}) : super(key: key);

  @override
  _ContributionState createState() => _ContributionState();
}

class _ContributionState extends State<Contribution> {
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _voucherNumberController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountPaidController,
            decoration: const InputDecoration(
              labelText: 'Amount Paid',
            ),
            onChanged: (e) {},
          ),
          TextField(
            controller: _voucherNumberController,
            decoration: const InputDecoration(
              labelText: 'Voucher Number',
            ),
            onChanged: (e) {},
          ),
        ],
      ),
    );
  }
}
