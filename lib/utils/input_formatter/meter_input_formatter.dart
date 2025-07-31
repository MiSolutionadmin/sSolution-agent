import 'package:flutter/services.dart';

/// 음수 + 소숫점을 허용하되, 이상한 형식의 입력을 막음
TextInputFormatter onlyAllowSignedDecimal() {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;

    // 빈 값은 허용
    if (text.isEmpty) return newValue;

    // 정규식: ^-? : 음수 기호는 0개 또는 1개, \d* : 숫자 0개 이상, (\.\d*)? : 소수점 이하 숫자 0개 이상 (소수점 포함 여부는 선택)
    final regExp = RegExp(r'^-?\d*\.?\d*$');

    if (regExp.hasMatch(text)) {
      // 하이픈이 두 번 이상 들어가거나, 소수점이 두 번 이상이면 허용 안 함
      if ('-'.allMatches(text).length > 1 || '.'.allMatches(text).length > 1) {
        return oldValue;
      }

      // 하이픈이 첫 번째 자리에 있는 경우만 허용
      if (text.contains('-') && !text.startsWith('-')) {
        return oldValue;
      }

      return newValue;
    }

    return oldValue;
  });
}
