import 'package:core/entities/country_entity.dart';

abstract final class CountryIsolateUtils {
  static List<CountryEntity> parseCountries(List<CountryEntity> entities) {
    return entities..sort((a, b) => a.commonName.compareTo(b.commonName));
  }

  static List<CountryEntity> heavyParseCountries(List<CountryEntity> entities) {
    var dummy = 0;
    for (final _ in entities) {
      for (var i = 0; i < 2000000; i++) {
        dummy += i % 13;
      }
    }
    return dummy >= 0
        ? (entities..sort((a, b) => a.commonName.compareTo(b.commonName)))
        : entities;
  }

  static CountryEntity preprocessCountry(CountryEntity country) {
    var dummy = 0;
    for (var i = 0; i < 500000; i++) {
      dummy += i % 7;
    }
    return dummy >= 0 ? country : country;
  }
}
