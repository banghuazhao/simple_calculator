import 'package:simple_calculator/generated/l10n.dart';

enum MeasurementQuantity {
  length,
  mass,
  volume,
  temperature;

  List<MeasurementUnit> get units => switch (this) {
    length => const [
      MeasurementUnit.meter,
      MeasurementUnit.foot,
      MeasurementUnit.centimeter,
      MeasurementUnit.inch,
      MeasurementUnit.kilometer,
      MeasurementUnit.mile,
    ],
    mass => const [
      MeasurementUnit.kilogram,
      MeasurementUnit.pound,
      MeasurementUnit.gram,
      MeasurementUnit.ounce,
      MeasurementUnit.milligram,
    ],
    volume => const [
      MeasurementUnit.liter,
      MeasurementUnit.usGallon,
      MeasurementUnit.milliliter,
      MeasurementUnit.usCup,
      MeasurementUnit.usFluidOunce,
    ],
    temperature => const [
      MeasurementUnit.celsius,
      MeasurementUnit.fahrenheit,
      MeasurementUnit.kelvin,
    ],
  };

  String label(S strings) => switch (this) {
    length => strings.converterLength,
    mass => strings.converterMass,
    volume => strings.converterVolume,
    temperature => strings.converterTemperature,
  };
}

enum MeasurementUnit {
  meter('m', 1),
  foot('ft', 0.3048),
  centimeter('cm', 0.01),
  inch('in', 0.0254),
  kilometer('km', 1000),
  mile('mi', 1609.344),
  kilogram('kg', 1),
  pound('lb', 0.45359237),
  gram('g', 0.001),
  ounce('oz', 0.028349523125),
  milligram('mg', 0.000001),
  liter('L', 1),
  usGallon('US gal', 3.785411784),
  milliliter('mL', 0.001),
  usCup('US cup', 0.2365882365),
  usFluidOunce('US fl oz', 0.0295735295625),
  celsius('°C'),
  fahrenheit('°F'),
  kelvin('K');

  const MeasurementUnit(this.symbol, [this.factor = 1]);

  final String symbol;
  final double factor;

  String label(S strings) => switch (this) {
    meter => strings.converterMeter,
    foot => strings.converterFoot,
    centimeter => strings.converterCentimeter,
    inch => strings.converterInch,
    kilometer => strings.converterKilometer,
    mile => strings.converterMile,
    kilogram => strings.converterKilogram,
    pound => strings.converterPound,
    gram => strings.converterGram,
    ounce => strings.converterOunce,
    milligram => strings.converterMilligram,
    liter => strings.converterLiter,
    usGallon => strings.converterUsGallon,
    milliliter => strings.converterMilliliter,
    usCup => strings.converterUsCup,
    usFluidOunce => strings.converterUsFluidOunce,
    celsius => strings.converterCelsius,
    fahrenheit => strings.converterFahrenheit,
    kelvin => strings.converterKelvin,
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
