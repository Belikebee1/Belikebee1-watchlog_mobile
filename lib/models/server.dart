/// A configured watchlog server endpoint.
///
/// Stored in flutter_secure_storage as JSON inside [ServersState].
class Server {
  final String id;
  final String name;
  final String baseUrl;
  final String token;

  const Server({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.token,
  });

  Server copyWith({String? name, String? baseUrl, String? token}) => Server(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'token': token,
      };

  factory Server.fromJson(Map<String, dynamic> json) => Server(
        id: json['id'] as String,
        name: json['name'] as String,
        baseUrl: json['baseUrl'] as String,
        token: json['token'] as String,
      );
}
