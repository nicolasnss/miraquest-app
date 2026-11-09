class MateriaModel {
  const MateriaModel({required this.nome, required this.totalQuestoes});

  final String nome;
  final int totalQuestoes;

  factory MateriaModel.fromJson(Map<String, dynamic> json) {
    final total = json['totalQuestoes'];
    return MateriaModel(
      nome: (json['nome'] ?? '').toString(),
      totalQuestoes: total is num ? total.toInt() : int.tryParse('$total') ?? 0,
    );
  }
}
