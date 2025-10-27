class ApiResponse<T> {
  final String type;
  final String message;
  final T? data;
  final String? token;
  final List<dynamic>? permissions;
  final String? redirect;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.type,
    required this.message,
    this.data,
    this.token,
    this.permissions,
    this.redirect,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      type: json['type'] ?? json['status'] ?? 'error',
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      token: json['token'],
      permissions: json['permissions'],
      redirect: json['redirect'],
      errors: json['errors'],
    );
  }

  bool get isSuccess => type == 'success';
  bool get isError => type == 'error' || type == 'failed';
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}
