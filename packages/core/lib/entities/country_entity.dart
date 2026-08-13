import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  const CountryEntity({
    required this.cca2,
    required this.commonName,
    required this.officialName,
    this.capital,
    required this.region,
    required this.population,
    required this.flagPng,
    this.flagAlt,
    this.area,
    this.languages,
    this.timezones,
    this.borders,
    this.currencies,
    this.latlng,
    this.subregion,
  });

  final String cca2;
  final String commonName;
  final String officialName;
  final String? capital;
  final String? subregion;
  final String region;
  final int population;
  final String flagPng;
  final String? flagAlt;

  final double? area;
  final List<String>? languages;
  final List<String>? timezones;
  final List<String>? borders;
  final List<String>? currencies;
  final List<double>? latlng;

  @override
  List<Object?> get props => [
    cca2,
    commonName,
    officialName,
    capital,
    region,
    population,
    flagPng,
  ];
}
