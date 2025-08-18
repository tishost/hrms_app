class BdGeo {
  static const Map<String, List<String>> districtToThanas = {
    'Dhaka': [
      'Dhanmondi',
      'Gulshan',
      'Banani',
      'Mirpur',
      'Uttara',
      'Mohammadpur',
      'Tejgaon',
      'Keraniganj',
    ],
    'Chattogram': [
      'Kotwali',
      'Pahartali',
      'Panchlaish',
      'Halishahar',
      'Double Mooring',
      'Bakalia',
    ],
    'Gazipur': [
      'Gazipur Sadar',
      'Tongi',
      'Kaliakair',
      'Kapasia',
      'Sreepur',
      'Kaliganj',
    ],
    'Narayanganj': [
      'Narayanganj Sadar',
      'Sonargaon',
      'Rupganj',
      'Araihazar',
      'Bandar',
    ],
    'Cumilla': [
      'Cumilla Adarsha Sadar',
      'Cumilla Sadar Dakshin',
      'Daudkandi',
      'Debidwar',
      'Laksam',
    ],
  };

  static List<String> getDistricts() {
    final list = districtToThanas.keys.toList();
    list.sort();
    return list;
  }

  static List<String> getThanas(String district) {
    final list = List<String>.from(
      districtToThanas[district] ?? const <String>[],
    );
    list.sort();
    return list;
  }
}
