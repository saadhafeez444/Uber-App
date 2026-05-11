class Truck {
  final String truckId;
  final String make;
  final String model;
  final String licensePlate;
  final String truckType;
  final double capacityTons;
  final int axles;
  final String? vin;
  final List<String> imageURLs;

  Truck({
    required this.truckId,
    required this.make,
    required this.model,
    required this.licensePlate,
    required this.truckType,
    required this.capacityTons,
    required this.axles,
    this.vin,
    this.imageURLs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'make': make,
      'model': model,
      'licensePlate': licensePlate,
      'truckType': truckType,
      'capacityTons': capacityTons,
      'axles': axles,
      'vin': vin,
      'imageURLs': imageURLs,
    };
  }

  factory Truck.fromMap(Map<String, dynamic> map) {
    return Truck(
      truckId: map['truckId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      truckType: map['truckType'] ?? '',
      capacityTons: (map['capacityTons'] ?? 0).toDouble(),
      axles: map['axles'] ?? 0,
      vin: map['vin'],
      imageURLs: List<String>.from(map['imageURLs'] ?? []),
    );
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String? bio;
  final String? profileImage;
  final UserType userType;
  final DriverInfo? driverInfo;
  final CompanyInfo? companyInfo;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    this.bio,
    this.profileImage,
    required this.userType,
    this.driverInfo,
    this.companyInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'profileImage': profileImage,
      'userType': userType.name,
      'driverInfo': driverInfo?.toMap(),
      'companyInfo': companyInfo?.toMap(),
    };
  }

factory UserProfile.fromMap(Map<String, dynamic> map) {
  print('Raw map data: $map'); // Debug print

  final rawType = (map['userType'] ?? '').toString().toLowerCase();

  UserType parsedType;
  switch (rawType) {
    case 'user':
      parsedType = UserType.user;
      break;
    case 'driver':
      parsedType = UserType.driver;
      break;
    case 'company':
      parsedType = UserType.company;
      break;
    default:
      parsedType = UserType.user;
  }

  // Handle profile image - check multiple possible field names
  String? profileImage;
  
  // Try different possible field names for profile image
  if (map['profileImage'] != null && map['profileImage'].toString().isNotEmpty) {
    profileImage = map['profileImage'].toString();
  } else if (map['profileImageURL'] != null && map['profileImageURL'].toString().isNotEmpty) {
    profileImage = map['profileImageURL'].toString();
  } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
    profileImage = map['imageUrl'].toString();
  } else if (map['photoURL'] != null && map['photoURL'].toString().isNotEmpty) {
    profileImage = map['photoURL'].toString();
  }

  print('Extracted profile image: $profileImage'); // Debug

  return UserProfile(
    id: map['id']?.toString() ?? '',
    fullName: map['fullName']?.toString() ?? '',
    email: map['email']?.toString() ?? '',
    phoneNumber: map['phoneNumber']?.toString() ?? '',
    dateOfBirth: map['dateOfBirth'] != null
        ? DateTime.tryParse(map['dateOfBirth'].toString())
        : null,
    bio: map['bio']?.toString(),
    profileImage: profileImage, // Use the extracted profile image
    userType: parsedType,
    driverInfo: map['driverInfo'] != null
        ? DriverInfo.fromMap(Map<String, dynamic>.from(map['driverInfo']))
        : null,
    companyInfo: map['companyInfo'] != null
        ? CompanyInfo.fromMap(Map<String, dynamic>.from(map['companyInfo']))
        : null,
  );
}

}



class CompanyInfo {
  final String companyName;
  final String companyEmail;
  final String? tradeMarkImageURL;
  final String? companyDescription;
  final String registrationNumber;
  final int numberOfEmployees;
  final int numberOfTrucks;
  final List<Truck> trucks;
  final String? companyPhoneNumber;
  final DateTime? dateOfEstablishment;
  final List<Certificate> certificates;

  CompanyInfo({
    required this.companyName,
    required this.companyEmail,
    this.tradeMarkImageURL,
    this.companyDescription,
    required this.registrationNumber,
    required this.numberOfEmployees,
    required this.numberOfTrucks,
    this.trucks = const [],
    this.companyPhoneNumber,
    this.dateOfEstablishment,
    this.certificates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyEmail': companyEmail,
      'tradeMarkImageURL': tradeMarkImageURL,
      'companyDescription': companyDescription,
      'registrationNumber': registrationNumber,
      'numberOfEmployees': numberOfEmployees,
      'numberOfTrucks': numberOfTrucks,
      'trucks': trucks.map((t) => t.toMap()).toList(),
      'companyPhoneNumber': companyPhoneNumber,
      'dateOfEstablishment': dateOfEstablishment?.toIso8601String(),
      'certificates': certificates.map((c) => c.toMap()).toList(),
    };
  }

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      companyName: map['companyName'] ?? '',
      companyEmail: map['companyEmail'] ?? '',
      tradeMarkImageURL: map['tradeMarkImageURL'],
      companyDescription: map['companyDescription'],
      registrationNumber: map['registrationNumber'] ?? '',
      numberOfEmployees: map['numberOfEmployees'] ?? 0,
      numberOfTrucks: map['numberOfTrucks'] ?? 0,
      trucks: (map['trucks'] as List<dynamic>? ?? [])
          .map((t) => Truck.fromMap(Map<String, dynamic>.from(t)))
          .toList(),
      companyPhoneNumber: map['companyPhoneNumber'],
      dateOfEstablishment: map['dateOfEstablishment'] != null
          ? DateTime.tryParse(map['dateOfEstablishment'])
          : null,
      certificates: (map['certificates'] as List<dynamic>? ?? [])
          .map((c) => Certificate.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

class DriverInfo {
  final String licenseNumber;
  final String licenseImage;
  final double experienceYears;
  final String vehicleModel;
  final String vehiclePlate;
  final double rating;
  final int totalRides;
  final List<Certificate> certificates;

  DriverInfo({
    required this.licenseNumber,
    required this.licenseImage,
    required this.experienceYears,
    required this.vehicleModel,
    required this.vehiclePlate,
    required this.rating,
    required this.totalRides,
    this.certificates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseImage': licenseImage,
      'experienceYears': experienceYears,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
      'rating': rating,
      'totalRides': totalRides,
      'certificates': certificates.map((c) => c.toMap()).toList(),
    };
  }

  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      licenseNumber: map['licenseNumber'] ?? '',
      licenseImage: map['licenseImage'] ?? '',
      experienceYears: (map['experienceYears'] ?? 0).toDouble(),
      vehicleModel: map['vehicleModel'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      certificates: (map['certificates'] as List<dynamic>? ?? [])
          .map((c) => Certificate.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

class Certificate {
  final String id;
  final String name;
  final String organization;
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? filePath;
  final bool isPdf;

  Certificate({
    required this.id,
    required this.name,
    required this.organization,
    required this.issueDate,
    this.expiryDate,
    this.filePath,
    this.isPdf = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'organization': organization,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'filePath': filePath,
      'isPdf': isPdf,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      organization: map['organization'] ?? '',
      issueDate: DateTime.tryParse(map['issueDate'] ?? '') ?? DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'])
          : null,
      filePath: map['filePath'],
      isPdf: map['isPdf'] ?? false,
    );
  }
}

enum UserType { user, driver, company }
