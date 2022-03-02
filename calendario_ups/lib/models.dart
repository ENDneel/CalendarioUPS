class Anuncio {
  final int id;
  final String fecha_publicacion;
  final String descripcion;
  final String imagen;

  const Anuncio({
    required this.id,
    required this.fecha_publicacion,
    required this.descripcion,
    required this.imagen,
  });

  factory Anuncio.fromJson(Map<String, dynamic> json) {
    return Anuncio(
        id: json['id'],
        fecha_publicacion: json['fecha_publicacion'],
        descripcion: json['descripcion'],
        imagen: json['imagen']);
  }
}

class Calendario {
  final int id;
  final String fecha_i;
  final int duracion;
  final String titulo;

  const Calendario({
    required this.id,
    required this.fecha_i,
    required this.duracion,
    required this.titulo,
  });

  factory Calendario.fromJson(Map<String, dynamic> json) {
    return Calendario(
        id: json['id'],
        fecha_i: json['fecha_i'],
        duracion: json['duracion'],
        titulo: json['titulo']);
  }
}
