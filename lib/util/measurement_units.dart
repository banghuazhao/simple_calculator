import 'package:simple_calculator/generated/l10n.dart';

enum MeasurementQuantity {
  length,
  mass,
  volume,
  temperature,
  area,
  speed,
  data,
  time;

  List<MeasurementUnit> get units => switch (this) {
    length => const [
      MeasurementUnit.meter,
      MeasurementUnit.foot,
      MeasurementUnit.centimeter,
      MeasurementUnit.millimeter,
      MeasurementUnit.inch,
      MeasurementUnit.yard,
      MeasurementUnit.kilometer,
      MeasurementUnit.mile,
    ],
    mass => const [
      MeasurementUnit.kilogram,
      MeasurementUnit.pound,
      MeasurementUnit.gram,
      MeasurementUnit.ounce,
      MeasurementUnit.milligram,
      MeasurementUnit.tonne,
    ],
    volume => const [
      MeasurementUnit.liter,
      MeasurementUnit.usGallon,
      MeasurementUnit.milliliter,
      MeasurementUnit.usCup,
      MeasurementUnit.usFluidOunce,
      MeasurementUnit.ukGallon,
      MeasurementUnit.ukFluidOunce,
      MeasurementUnit.tablespoon,
      MeasurementUnit.teaspoon,
    ],
    temperature => const [
      MeasurementUnit.celsius,
      MeasurementUnit.fahrenheit,
      MeasurementUnit.kelvin,
    ],
    area => const [
      MeasurementUnit.squareMeter,
      MeasurementUnit.squareFoot,
      MeasurementUnit.squareCentimeter,
      MeasurementUnit.squareInch,
      MeasurementUnit.hectare,
      MeasurementUnit.acre,
      MeasurementUnit.squareKilometer,
      MeasurementUnit.squareMile,
    ],
    speed => const [
      MeasurementUnit.kmPerHour,
      MeasurementUnit.milesPerHour,
      MeasurementUnit.metersPerSecond,
      MeasurementUnit.knot,
    ],
    data => const [
      MeasurementUnit.megabyte,
      MeasurementUnit.gigabyte,
      MeasurementUnit.byte,
      MeasurementUnit.kilobyte,
      MeasurementUnit.terabyte,
    ],
    time => const [
      MeasurementUnit.hour,
      MeasurementUnit.minute,
      MeasurementUnit.second,
      MeasurementUnit.day,
      MeasurementUnit.week,
    ],
  };

  String label(S strings) => switch (this) {
    length => strings.converterLength,
    mass => strings.converterMass,
    volume => strings.converterVolume,
    temperature => strings.converterTemperature,
    area => strings.converterArea,
    speed => strings.converterSpeed,
    data => strings.converterData,
    time => strings.converterTime,
  };
}

enum MeasurementUnit {
  // Length (base: meter)
  meter('m', 1),
  foot('ft', 0.3048),
  centimeter('cm', 0.01),
  millimeter('mm', 0.001),
  inch('in', 0.0254),
  yard('yd', 0.9144),
  kilometer('km', 1000),
  mile('mi', 1609.344),

  // Mass (base: kilogram)
  kilogram('kg', 1),
  pound('lb', 0.45359237),
  gram('g', 0.001),
  ounce('oz', 0.028349523125),
  milligram('mg', 0.000001),
  tonne('t', 1000),

  // Volume (base: liter)
  liter('L', 1),
  usGallon('US gal', 3.785411784),
  milliliter('mL', 0.001),
  usCup('US cup', 0.2365882365),
  usFluidOunce('US fl oz', 0.0295735295625),
  ukGallon('UK gal', 4.54609),
  ukFluidOunce('UK fl oz', 0.0284130625),
  tablespoon('tbsp', 0.01478676478125),
  teaspoon('tsp', 0.00492892159375),

  // Temperature
  celsius('°C'),
  fahrenheit('°F'),
  kelvin('K'),

  // Area (base: square meter)
  squareMeter('m²', 1),
  squareFoot('ft²', 0.09290304),
  squareCentimeter('cm²', 0.0001),
  squareInch('in²', 0.00064516),
  hectare('ha', 10000),
  acre('acre', 4046.8564224),
  squareKilometer('km²', 1000000),
  squareMile('mi²', 2589988.110336),

  // Speed (base: m/s)
  kmPerHour('km/h', 1 / 3.6),
  milesPerHour('mph', 0.44704),
  metersPerSecond('m/s', 1),
  knot('kn', 1852 / 3600),

  // Data (base: byte, IEC binary 1024)
  byte('B', 1),
  kilobyte('KB', 1024),
  megabyte('MB', 1048576),
  gigabyte('GB', 1073741824),
  terabyte('TB', 1099511627776),

  // Time (base: second)
  second('s', 1),
  minute('min', 60),
  hour('h', 3600),
  day('d', 86400),
  week('wk', 604800);

  const MeasurementUnit(this.symbol, [this.factor = 1]);

  final String symbol;
  final double factor;

  String label(S strings) => switch (this) {
    meter => strings.converterMeter,
    foot => strings.converterFoot,
    centimeter => strings.converterCentimeter,
    millimeter => strings.converterMillimeter,
    inch => strings.converterInch,
    yard => strings.converterYard,
    kilometer => strings.converterKilometer,
    mile => strings.converterMile,
    kilogram => strings.converterKilogram,
    pound => strings.converterPound,
    gram => strings.converterGram,
    ounce => strings.converterOunce,
    milligram => strings.converterMilligram,
    tonne => strings.converterTonne,
    liter => strings.converterLiter,
    usGallon => strings.converterUsGallon,
    milliliter => strings.converterMilliliter,
    usCup => strings.converterUsCup,
    usFluidOunce => strings.converterUsFluidOunce,
    ukGallon => strings.converterUkGallon,
    ukFluidOunce => strings.converterUkFluidOunce,
    tablespoon => strings.converterTablespoon,
    teaspoon => strings.converterTeaspoon,
    celsius => strings.converterCelsius,
    fahrenheit => strings.converterFahrenheit,
    kelvin => strings.converterKelvin,
    squareMeter => strings.converterSquareMeter,
    squareFoot => strings.converterSquareFoot,
    squareCentimeter => strings.converterSquareCentimeter,
    squareInch => strings.converterSquareInch,
    hectare => strings.converterHectare,
    acre => strings.converterAcre,
    squareKilometer => strings.converterSquareKilometer,
    squareMile => strings.converterSquareMile,
    kmPerHour => strings.converterKmPerHour,
    milesPerHour => strings.converterMilesPerHour,
    metersPerSecond => strings.converterMetersPerSecond,
    knot => strings.converterKnot,
    byte => strings.converterByte,
    kilobyte => strings.converterKilobyte,
    megabyte => strings.converterMegabyte,
    gigabyte => strings.converterGigabyte,
    terabyte => strings.converterTerabyte,
    second => strings.converterSecond,
    minute => strings.converterMinute,
    hour => strings.converterHour,
    day => strings.converterDay,
    week => strings.converterWeek,
  };

  double convertTo(
    double amount,
    MeasurementUnit target,
    MeasurementQuantity quantity,
  ) {
    if (this == target) return amount;
    if (quantity != MeasurementQuantity.temperature) {
      return amount * (factor / target.factor);
    }

    final celsiusAmount = switch (this) {
      fahrenheit => (amount - 32) * (5 / 9),
      kelvin => amount - 273.15,
      _ => amount,
    };
    return switch (target) {
      fahrenheit => celsiusAmount * (9 / 5) + 32,
      kelvin => celsiusAmount + 273.15,
      _ => celsiusAmount,
    };
  }
}
