import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/profile/edit_profile_screen.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';

import 'package:flutter/material.dart';

class ViewCompanyProfileScreen extends StatelessWidget {
  final UserProfile profile;

  const ViewCompanyProfileScreen({Key? key, required this.profile})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CompanyInfo? company = profile.companyInfo;

    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Company Profile')),
        body: Center(
          child: Text(
            '⚠️ Error: Company profile data is unavailable.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                children: [
                  CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 320),
                    painter: ProfileBackgroundPainter(
                      mainWaveColor: AppColors.primaryBlue,
                      circleColor: AppColors.secondaryBlue,
                      lightColor: AppColors.lightBlue,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const SizedBox(height: 15),

                        Text(
                          company.companyName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              const Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),

                        Text(
                          'Reg: ${company.registrationNumber}',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildCompanyInfoCard(company),

                  const SizedBox(height: 30),

                  _buildTrucksSection(context, company),

                  const SizedBox(height: 30),
                  if (company.certificates.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _buildCertificatesList(company.certificates),
                  ],
                  const SizedBox(height: 30),

                  if (company.companyDescription?.isNotEmpty == true)
                    _buildCompanyBioCard(company.companyDescription!),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget CompanyHeaderPainter({required Color color1, required Color color2}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildTrucksSection(BuildContext context, CompanyInfo company) {
    final trucks = company.trucks;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryBlue.withOpacity(0.15),
                    AppColors.secondaryBlue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),

                  Text(
                    'Fleet Vehicles (${trucks.length})',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            if (trucks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'This company has no registered trucks.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trucks.length,
                itemBuilder: (context, index) {
                  return _buildTruckExpansionTile(trucks[index]);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckExpansionTile(Truck truck) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      iconColor: AppColors.primaryOrange,
      collapsedIconColor: AppColors.textGrey,
      title: Text(
        truck.model,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        'Plate: ${truck.licensePlate} | Status: ${truck.truckType}',
        style: const TextStyle(fontSize: 13, color: Colors.black45),
      ),
      leading: Icon(
        Icons.local_shipping_rounded,
        color: AppColors.primaryBlue,
        size: 30,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTruckDetailRow(
                icon: Icons.speed_rounded,
                label: 'Max Load Capacity',
                value: '${truck.capacityTons} kg',
                iconColor: Colors.green,
              ),
              const SizedBox(height: 10),
              _buildTruckDetailRow(
                icon: Icons.color_lens_rounded,
                label: 'Color',
                value: truck.licensePlate,
                iconColor: Colors.grey,
              ),
              const SizedBox(height: 10),
              _buildTruckDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Year of Manufacture',
                value: truck.make.toString(),
                iconColor: AppColors.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTruckDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfoCard(CompanyInfo company) {
    final String? formattedDate = company.dateOfEstablishment != null
        ? DateFormat('dd/MM/yyyy').format(company.dateOfEstablishment!)
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.lightBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Company Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  if (company.companyPhoneNumber != null &&
                      company.companyPhoneNumber!.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Company Phone',
                      value: company.companyPhoneNumber!,
                      iconColor: AppColors.primaryBlue,
                    ),
                  if (company.companyPhoneNumber != null &&
                      company.companyPhoneNumber!.isNotEmpty)
                    SizedBox(height: 20),

                  // 2. New: Date of Establishment
                  if (formattedDate != null)
                    _buildInfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date of Establishment',
                      value: formattedDate,
                      iconColor: AppColors.primaryBlue,
                    ),
                  if (formattedDate != null) SizedBox(height: 20),

                  // Original field: Company Email
                  if (company.companyEmail.isNotEmpty)
                    _buildInfoRow(
                      icon: Icons.email_rounded,
                      label: 'Company Email',
                      value: company.companyEmail,
                      iconColor: AppColors.primaryBlue,
                    ),

                  SizedBox(height: 20),

                  // Original field: Registration Number
                  _buildInfoRow(
                    icon: Icons.badge_rounded,
                    label: 'Registration Number',
                    // Note: Your original code was showing 'company.registrationNumber' here,
                    // but in a previous row it was mistakenly assigned to the 'Company Phone' icon.
                    // This is the correct placement for the registration number.
                    value: company.registrationNumber,
                    iconColor: AppColors.primaryBlue,
                  ),

                  SizedBox(height: 20),

                  // Original field: Employees
                  _buildInfoRow(
                    icon: Icons.people_rounded,
                    label: 'Number of Employees',
                    value: company.numberOfEmployees.toString(),
                    iconColor: AppColors.primaryBlue,
                  ),

                  SizedBox(height: 20),

                  // Original field: Fleet Size
                  _buildInfoRow(
                    icon: Icons.local_shipping_rounded,
                    label: 'Fleet Size (Trucks)',
                    value: company.trucks.length.toString(),
                    iconColor: AppColors.secondaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyBioCard(String description) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.1), AppColors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 15),

                  Text(
                    'Company Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildCertificateDetailRow({
  required IconData icon,
  required String label,
  required String value,
  Color iconColor = Colors.black87,
  Color valueColor = Colors.black,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: AppColors.lightOrange.withOpacity(0.3), width: 1),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCertificateExpansionTile(Certificate certificate) {
  final now = DateTime.now();
  final isExpired =
      certificate.expiryDate != null && certificate.expiryDate!.isBefore(now);
  
  final isExpiringSoon =
      certificate.expiryDate != null &&
      certificate.expiryDate!.isAfter(now) &&
      certificate.expiryDate!.difference(now).inDays <= 60;

  Color statusColor = AppColors.primaryBlue;
  String statusLabel = 'Valid';
  Color backgroundColor = Colors.white;

  if (isExpired) {
    statusColor = Colors.red.shade700;
    statusLabel = 'Expired';
    backgroundColor = Colors.red.shade50;
  } else if (isExpiringSoon) {
    statusColor = Colors.orange.shade700;
    statusLabel = 'Expiring Soon';
    backgroundColor = AppColors.lightOrange;
  }

  final DateFormat formatter = DateFormat('MMM dd, yyyy');

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          backgroundColor,
          Colors.white,
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(0.15),
          blurRadius: 15,
          offset: const Offset(0, 8),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
        color: statusColor.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      iconColor: AppColors.primaryOrange,
      collapsedIconColor: AppColors.textGrey,
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.9),
              statusColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.verified_user_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      title: Text(
        certificate.name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),

      subtitle: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        ),
        child: Text(
          'Authority: ${certificate.organization} | Status: $statusLabel',
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.3),
                statusColor.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Issue Date
              _buildCertificateDetailRow(
                icon: Icons.date_range_rounded,
                label: 'Issue Date',
                value: formatter.format(certificate.issueDate),
                iconColor: AppColors.primaryBlue,
                valueColor: Colors.black87,
              ),

              // Expiry Date
              if (certificate.expiryDate != null) ...[
                _buildCertificateDetailRow(
                  icon: isExpired
                      ? Icons.error_outline_rounded
                      : (isExpiringSoon
                          ? Icons.access_time_filled_rounded
                          : Icons.check_circle_outline_rounded),
                  label: 'Expiry Date',
                  value: formatter.format(certificate.expiryDate!),
                  iconColor: statusColor,
                  valueColor: statusColor,
                ),
              ] else ...[
                _buildCertificateDetailRow(
                  icon: Icons.all_inclusive_rounded,
                  label: 'Expiry Date',
                  value: 'N/A (Perpetual)',
                  iconColor: Colors.grey,
                  valueColor: Colors.grey,
                ),
              ],

              // File Type
              _buildCertificateDetailRow(
                icon: certificate.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.insert_photo_rounded,
                label: 'File Type',
                value: certificate.isPdf ? 'PDF Document' : 'Image File',
                iconColor: AppColors.secondaryBlue,
                valueColor: AppColors.secondaryBlue,
              ),

              const SizedBox(height: 20),

              // View Document Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: certificate.filePath != null
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryOrange,
                            AppColors.secondaryOrange,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: certificate.filePath != null
                      ? [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  color: certificate.filePath != null ? null : Colors.grey.shade300,
                ),
                child: TextButton.icon(
                  onPressed: () {
                    // Handle button press
                  },
                  icon: Icon(
                    certificate.filePath != null
                        ? Icons.file_download_rounded
                        : Icons.cancel_outlined,
                    size: 20,
                    color: certificate.filePath != null ? Colors.white : Colors.grey.shade600,
                  ),
                  label: Text(
                    certificate.filePath != null
                        ? 'View Document'
                        : 'No File Attached',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: certificate.filePath != null ? Colors.white : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildCertificatesList(List<Certificate> certificates) {
  if (certificates.isEmpty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.lightOrange.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: AppColors.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No certifications provided yet.',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(0.8),
              AppColors.primaryBlue,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Compliance & Certifications (${certificates.length})',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      ...certificates
          .map(
            (certificate) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 6,
              ),
              child: _buildCertificateExpansionTile(certificate),
            ),
          )
          .toList(),
      const SizedBox(height: 24),
    ],
  );
}


  


}
