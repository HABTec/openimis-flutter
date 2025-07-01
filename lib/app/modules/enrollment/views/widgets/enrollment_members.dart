import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/enrollment_controller.dart';
import 'contribution.dart';
import 'enrollment_form.dart';
import 'family_detail.dart';

class EnrollmentDetailsPage extends StatelessWidget {
  final String chfid;
  final int? enrollmentId;

  EnrollmentDetailsPage({required this.chfid, this.enrollmentId});

  final EnrollmentController enrollmentController =
      Get.put(EnrollmentController());

  @override
  Widget build(BuildContext context) {
    // Fetch data when the page is initialized
    enrollmentController.fetchEnrollmentDetails(enrollmentId!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Enrollment Details'),
        actions: [
          Row(
            children: [
              Tooltip(
                message: 'Voucher',
                child: IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {
                    // Call the method to pick the voucher image
                    enrollmentController.pickVoucherImage();
                  },
                ),
              ),
              Tooltip(
                message: 'Enroll',
                child: IconButton(
                  icon: Icon(Icons.people_rounded),
                  onPressed: () async {
                    // Call the method to pick the voucher image
                    enrollmentController.onEnrollmentOnline(
                        enrollmentController.familyId.value);
                  },
                ),
              ),
              // Wrap IconButton with Builder to access the right context
              Tooltip(
                message: 'Open Sidebar',
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu), // Drawer icon
                      onPressed: () {
                        Scaffold.of(context)
                            .openEndDrawer(); // Open the right drawer
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      // Right-side drawer (endDrawer)
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(1.0),
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text('Contribution and Voucher',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.attach_file),
              title: Text('Voucher Image'),
              onTap: () {
                enrollmentController.pickVoucherImage();
              },
            ),
            Obx(() {
              if (enrollmentController.voucherImage.value != null) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        File(enrollmentController.voucherImage.value!.path),
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      title: Text('Remove Voucher'),
                      trailing: Icon(Icons.delete),
                      onTap: () {
                        enrollmentController.clearVoucherImage();
                      },
                    ),
                  ],
                );
              } else {
                return ListTile(
                  title: Text('No Voucher Image'),
                );
              }
            }),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Contribution Information:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                    'Premium Amount: ${enrollmentController.premiumAmount.value} ${enrollmentController.currency.value}'),
                Text(
                    'Per Member: ${enrollmentController.perMember.value} ${enrollmentController.currency.value}'),
                Text('Validity: ${enrollmentController.validity.value}'),
                SizedBox(height: 10),
                Obx(() {
                  return Text(
                    'Total Contribution: ${enrollmentController.calculateTotalContribution()} ${enrollmentController.currency.value}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  );
                }),
              ],
            ),
            Contribution(enrollmentController)
          ],
        ),
      ),
      body: SafeArea(child: Obx(() {
        if (enrollmentController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (enrollmentController.errorMessage.isNotEmpty) {
          return Center(child: Text(enrollmentController.errorMessage.value));
        } else if (enrollmentController.family.isEmpty) {
          return Center(child: Text('No data found'));
        }

        final family = enrollmentController.family;
        final members = enrollmentController.members;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50, // Background color of the Card
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15.0), // Rounded corners
                  ),
                  elevation: 4, // Shadow effect for the card
                  child: Padding(
                    padding:
                        const EdgeInsets.all(2.0), // Padding inside the card
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to the left
                      children: [
                        Text(
                          'CHFID: ${family['chfid']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Colors.white, // Text color for better contrast
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Sync Status: ${family['sync'] == 1 ? 'Synced' : 'Not Synced'}',
                          style: TextStyle(
                            color: Colors.white, // Text color for sync status
                          ),
                        ),
                        SizedBox(height: 20),
                        FamilyDetail(
                          family: family,
                          enrollmentController: enrollmentController,
                        ),
                      ],
                    ),
                  ),
                ),
                Text('Members:'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        iconColor: Colors.brown,
                        leading: CircleAvatar(
                          backgroundImage: member['photo'] != null
                              ? MemoryImage(base64Decode(member['photo']))
                              : AssetImage('assets/images/placeholder.png')
                                  as ImageProvider,
                          radius: 30,
                        ),
                        title: Text('Member Name: ${member['name']}'),
                        subtitle: Text('CHFID: ${member['chfid']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize
                              .min, // Ensures the Row takes up minimum width
                          children: [
                            IconButton(
                              icon: Icon(Icons.info_outline),
                              onPressed: () {
                                _showMemberDetailsPopup(
                                    context, member['json_content']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              color: Colors
                                  .red, // Set the color of the delete button to red
                              onPressed: () {
                                enrollmentController
                                    .deleteFamilyMember(member['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      })),

      // Footer-style button with loading indicator
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          return enrollmentController.enrollmentState.when(
            idle: () {
              return Row(
                children: [
                  Expanded(
                    flex: 4, // 80% of the width
                    child: ElevatedButton(
                      onPressed: () {
                        // Trigger the state change to loading
                        enrollmentController.onEnrollmentOnline(
                            enrollmentController.familyId.value);
                      },
                      child: Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.blue, // Button color
                      ),
                    ),
                  ),
                  SizedBox(width: 16), // Add some spacing between the buttons
                  Expanded(
                    flex: 1, // 20% of the width
                    child: ElevatedButton(
                      onPressed: () => _showAddMemberBottomSheet(context),
                      child: Icon(Icons.add_box_outlined),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.blue, // Button color
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () {
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton(
                      onPressed: null, // Disable the button while loading
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor:
                            Colors.grey, // Button color during loading
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: null, // Disable the icon button while loading
                      child: Icon(Icons.attach_money),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor:
                            Colors.grey, // Button color during loading
                      ),
                    ),
                  ),
                ],
              );
            },
            success: (data) {
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton(
                      onPressed: null, // Disable the button after success
                      child: Text('Success!'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.green, // Success color
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: null, // Disable the icon button after success
                      child: Icon(Icons.attach_money),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.green, // Success color
                      ),
                    ),
                  ),
                ],
              );
            },
            failure: (reason) {
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle retry logic here
                      },
                      child: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.red, // Failure color
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle dollar icon button action on failure
                      },
                      child: Icon(Icons.attach_money),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.red, // Failure color
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  void _showMemberDetailsPopup(BuildContext context, String jsonContent) {
    final Map<String, dynamic> memberDetails = jsonDecode(jsonContent);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Member Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: memberDetails.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('${entry.key}:',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('${entry.value}')),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMemberBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: EnrollmentForm(
                chfid: chfid, enrollmentId: enrollmentId), // Pass CHFID to form
          ),
        );
      },
    );
  }
}
