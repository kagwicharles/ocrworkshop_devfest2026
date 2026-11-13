import 'package:equatable/equatable.dart';

class IdFields extends Equatable {
  const IdFields({
    this.surname,
    this.givenNames,
    this.idNumber,
    this.dateOfBirth,
    this.districtOfBirth
  });

  static const totalFields = 5;

  final String? surname;
  final String? givenNames;
  final String? idNumber;
  final String? dateOfBirth;
  final String? districtOfBirth;

  int get foundCount =>
      [surname, givenNames, idNumber, dateOfBirth, districtOfBirth].where((v) => v != null).length;

  @override
  List<Object?> get props => [surname, givenNames, idNumber, dateOfBirth, districtOfBirth];
}