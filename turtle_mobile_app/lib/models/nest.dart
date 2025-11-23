class Nest {
  final String id;
  final String name;
  final String location;
  final double temp;
  final double humidity;
  final String gif;

  const Nest({
    required this.id,
    required this.name,
    required this.location,
    required this.temp,
    required this.humidity,
    this.gif = 'assets/turtle1.gif',
  });

  factory Nest.fromMap(String id, Map data) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    dynamic _pick(Map m, List<String> keys) {
      for (final k in keys) {
        if (m.containsKey(k)) return m[k];
      }
      return null;
    }

    final name = (_pick(data, ['name', 'Name']) ?? id).toString();
    final location = (_pick(data, ['location', 'Location']) ?? '').toString();
    final tNum = _pick(data, ['temperature', 'Temperature']) ?? 0;
    final hNum = _pick(data, ['humidity', 'Humidity']) ?? 0;

    return Nest(
      id: id,
      name: name,
      location: location,
      temp: _toDouble(tNum),
      humidity: _toDouble(hNum),
    );
  }

  Map<String, dynamic> toCardMap() => {
        'id': id,
        'name': name,
        'location': location,
        'temp': temp,
        'humidity': humidity,
        'gif': gif,
      };
}
