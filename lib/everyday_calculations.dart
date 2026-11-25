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

  EverydayNumber multiplyWhole(BigInt factor) =>
      EverydayNumber._(numerator * factor, denominator);
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

    // Rounded up to the nearest whole currency unit (100 cents) per person.
    final perPersonMin = extraPeople > BigInt.zero
        ? baseShare + BigInt.one
        : baseShare;
    final rem = perPersonMin % _hundred;
    roundedPerPerson = rem == BigInt.zero
        ? perPersonMin
        : perPersonMin + (_hundred - rem);
    roundedTotal = roundedPerPerson * people;
    roundedTip = roundedTotal - bill;
  }

  final BigInt people;
  late final BigInt tip;
  late final BigInt total;
  late final BigInt baseShare;
  late final BigInt extraPeople;
  late final BigInt roundedPerPerson;
  late final BigInt roundedTotal;
  late final BigInt roundedTip;
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

  double get asDouble => _numerator.toDouble() / _denominator.toDouble();

  @override
  int compareTo(UnitPrice other) => (_numerator * other._denominator).compareTo(
    other._numerator * _denominator,
  );

  /// Percentage saved by choosing `this` instead of a more expensive [other].
  double? percentSavingsOver(UnitPrice other) {
    if (other._numerator == BigInt.zero || compareTo(other) >= 0) return null;
    final diffNum =
        other._numerator * _denominator - _numerator * other._denominator;
    final denom = other._numerator * _denominator;
    if (denom == BigInt.zero) return null;
    final scaled = diffNum * BigInt.from(10000);
    return ((scaled + denom ~/ BigInt.two) ~/ denom).toDouble() / 100.0;
  }

  /// Formatted savings per base unit compared to a more expensive [other].
  String? formattedSavingsOver(UnitPrice other) {
    if (compareTo(other) >= 0) return null;
    final diffNum =
        other._numerator * _denominator - _numerator * other._denominator;
    final diffDen = _denominator * other._denominator;
    final scaled = BigInt.from(10000) * diffNum;
    final tenThousandths = (scaled + diffDen ~/ BigInt.two) ~/ diffDen;
    if (tenThousandths == BigInt.zero && diffNum > BigInt.zero) {
      return '< 0.0001';
    }
    return _fixed(tenThousandths, 4).replaceFirst(RegExp(r'0{1,2}$'), '');
  }

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

class DiscountCalculation {
  DiscountCalculation({
    required this.originalPrice,
    required this.discountPercent,
    required this.extraDiscountPercent,
    required this.taxPercent,
  }) {
    final afterFirst = originalPrice * (1 - discountPercent / 100);
    discountedSubtotal = afterFirst * (1 - extraDiscountPercent / 100);
    totalSavings = originalPrice - discountedSubtotal;
    taxAmount = discountedSubtotal * (taxPercent / 100);
    finalPrice = discountedSubtotal + taxAmount;
  }

  final double originalPrice;
  final double discountPercent;
  final double extraDiscountPercent;
  final double taxPercent;
  late final double discountedSubtotal;
  late final double totalSavings;
  late final double taxAmount;
  late final double finalPrice;
}

class PercentChangeCalculation {
  PercentChangeCalculation({required this.from, required this.to})
    : difference = to - from,
      percentChange = from == 0 ? null : ((to - from) / from.abs()) * 100;

  final double from;
  final double to;
  final double difference;
  final double? percentChange;
}

class MarginCalculation {
  MarginCalculation({required this.cost, required this.sellingPrice})
    : profit = sellingPrice - cost,
      markupPercent = cost == 0 ? null : ((sellingPrice - cost) / cost) * 100,
      marginPercent = sellingPrice == 0
          ? null
          : ((sellingPrice - cost) / sellingPrice) * 100;

  final double cost;
  final double sellingPrice;
  final double profit;
  final double? markupPercent;
  final double? marginPercent;
}

class DateDifference {
  DateDifference({required DateTime start, required DateTime end}) {
    // Use UTC midnight so DST spring-forward/fall-back transitions never
    // shorten or lengthen calendar days.
    final a = DateTime.utc(start.year, start.month, start.day);
    final b = DateTime.utc(end.year, end.month, end.day);
    final earlier = a.isBefore(b) ? a : b;
    final later = a.isBefore(b) ? b : a;
    signedDays = b.difference(a).inDays;
    totalDays = later.difference(earlier).inDays;
    weeks = totalDays ~/ 7;
    remainingDays = totalDays % 7;

    // Count Monday–Friday weekdays in [earlier, later) in O(1) time.
    final fullWeeks = totalDays ~/ 7;
    var weekdays = fullWeeks * 5;
    for (var i = 0; i < totalDays % 7; i++) {
      final day = earlier.add(Duration(days: fullWeeks * 7 + i));
      if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
        weekdays++;
      }
    }
    businessDays = weekdays;
  }

  late final int signedDays;
  late final int totalDays;
  late final int weeks;
  late final int remainingDays;
  late final int businessDays;
}

String formatCents(BigInt cents) => _fixed(cents, 2);

String _fixed(BigInt value, int fractionDigits) {
  final digits = value.toString().padLeft(fractionDigits + 1, '0');
  final decimal = digits.length - fractionDigits;
  return '${digits.substring(0, decimal)}.${digits.substring(decimal)}';
}
