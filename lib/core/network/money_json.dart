int centsFromJson(num amount) => (amount * 100).round();

num amountToJson(int cents) => cents % 100 == 0 ? cents ~/ 100 : cents / 100;
