class AccessLog {
  final String method;
  final bool success;
  final int timestamp;

  AccessLog({
    required this.method,
    required this.success,
    required this.timestamp,
  });
}

class OtpLog {
  final String code;
  final int expireAt;
  final bool used;
  final int createdAt;

  OtpLog({
    required this.code,
    required this.expireAt,
    required this.used,
    required this.createdAt,
  });
}