import 'package:equatable/equatable.dart';

class IdFields extends Equatable {
  const IdFields({
    this.surname,
    this.givenNames,
    this.idNumber,
    this.dateOfBirth,
  });

  static const totalFields = 4;

  final String? surname;
  final String? givenNames;
  final String? idNumber;
  final String? dateOfBirth;

  /// How many of the four fields were found.
  int get foundCount =>
      [surname, givenNames, idNumber, dateOfBirth].where((v) => v != null).length;

  @override
  List<Object?> get props => [surname, givenNames, idNumber, dateOfBirth];
}