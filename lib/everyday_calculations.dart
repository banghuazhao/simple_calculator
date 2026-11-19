import 'package:simple_calculator/processor.dart';

/// A non-negative decimal value retained as a fraction for cent rounding and
/// comparisons between packages measured in different units.
class EverydayNumber {
  const EverydayNumber._(this.numerator, this.denominator);

  final BigInt numerator;
  final BigInt denominator;

  static EverydayNumber? parse(String text) {
    final value = Processor.parseNumericInput(text);
    if (value == null || value < 0) return null;

    final normalized = text.trim().replaceAll(',', '').replaceAll('−', '-');
    final unsigned = normalized.startsWith(RegExp(r'^[+-]'))
        ? normalized.substring(1)
        : normalized;
    final parts = unsigned.toLowerCase().split('e');
    final digits = parts.first.split('.');
    final numerator = BigInt.parse(digits.join());
    if (numerator == BigInt.zero) {
      return EverydayNumber._(BigInt.zero, BigInt.one);
    }
    // The shared numeric parser bounds nonzero exponents to finite doubles.
    // Reject a nonzero literal that underflowed to zero before scaling it.
    if (value == 0) return null;
    final exponent = parts.length == 2 ? int.parse(parts.last) : 0;
    final scale = (digits.length == 2 ? digits.last.length : 0) - exponent;
    final ten = BigInt.from(10);
    return scale < 0
        ? EverydayNumber._(numerator * ten.pow(-scale), BigInt.one)
        : EverydayNumber._(numerator, ten.pow(scale));
  }

  bool get isPositive => numerator > BigInt.zero;

  BigInt? get wholeNumber =>
      numerator % denominator == BigInt.zero ? numerator ~/ denominator : null;

  BigInt? get cents {
    final scaled = numerator * _hundred;
    return scaled % denominator == BigInt.zero ? scaled ~/ denominator : null;
  }
}

final _hundred = BigInt.from(100);

class BillSplit {
  BillSplit({
    required BigInt bill,
    required EverydayNumber tipPercent,
    required this.people,
  }) {
    final divisor = tipPercent.denominator * _hundred;
    tip = (bill * tipPercent.numerator + divisor ~/ BigInt.two) ~/ divisor;
    total = bill + tip;
    baseShare = total ~/ people;
    extraPeople = total % people;
  }

  final BigInt people;
  late final BigInt tip;
  late final BigInt total;
  late final BigInt baseShare;
  late final BigInt extraPeople;
}

class UnitPrice implements Comparable<UnitPrice> {
  UnitPrice({
    required BigInt price,
    required EverydayNumber size,
    required EverydayNumber baseUnits,
  }) : _numerator = price * size.denominator * baseUnits.denominator,
       _denominator = _hundred * size.numerator * baseUnits.numerator;

  final BigInt _numerator;
  final BigInt _denominator;

  @override
  int compareTo(UnitPrice other) => (_numerator * other._denominator).compareTo(
    other._numerator * _denominator,
  );

  String get formatted {
    final scaled = BigInt.from(10000) * _numerator;
    final tenThousandths =
        (scaled + _denominator ~/ BigInt.two) ~/ _denominator;
    if (tenThousandths == BigInt.zero && _numerator > BigInt.zero) {
      return '< 0.0001';
    }
    return _fixed(tenThousandths, 4).replaceFirst(RegExp(r'0{1,2}$'), '');
  }
}

String formatCents(BigInt cents) => _fixed(cents, 2);

String _fixed(BigInt value, int fractionDigits) {
  final digits = value.toString().padLeft(fractionDigits + 1, '0');
  final decimal = digits.length - fractionDigits;
  return '${digits.substring(0, decimal)}.${digits.substring(decimal)}';
}
