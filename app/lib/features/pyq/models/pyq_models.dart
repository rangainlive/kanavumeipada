class PyqOption {
  final String id;
  final String text;
  final String? textTamil;
  final bool isCorrect;

  PyqOption({
    required this.id,
    required this.text,
    this.textTamil,
    required this.isCorrect,
  });

  factory PyqOption.fromJson(Map<String, dynamic> j) => PyqOption(
        id: j['id'],
        text: j['text'] ?? '',
        textTamil: j['textTamil'],
        isCorrect: j['isCorrect'] ?? false,
      );

  String display(bool isTamil) =>
      isTamil && textTamil != null && textTamil!.trim().isNotEmpty ? textTamil! : text;
}

class PyqQuestion {
  final String id;
  final String chapterId;
  final String? topic;
  final String text;
  final String? textTamil;
  final String? examName;
  final int? examYear;
  final bool answerMarked;
  final List<PyqOption> options;

  PyqQuestion({
    required this.id,
    required this.chapterId,
    this.topic,
    required this.text,
    this.textTamil,
    this.examName,
    this.examYear,
    required this.answerMarked,
    required this.options,
  });

  factory PyqQuestion.fromJson(Map<String, dynamic> j) => PyqQuestion(
        id: j['id'],
        chapterId: j['chapterId'] ?? '',
        topic: j['topic'],
        text: j['text'] ?? '',
        textTamil: j['textTamil'],
        examName: j['examName'],
        examYear: j['examYear'],
        answerMarked: j['answerMarked'] ?? false,
        options: (j['options'] as List? ?? [])
            .map((o) => PyqOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );

  String display(bool isTamil) =>
      isTamil && textTamil != null && textTamil!.trim().isNotEmpty ? textTamil! : text;
}

class PyqTopic {
  final String topic;
  final int count;
  PyqTopic({required this.topic, required this.count});
  factory PyqTopic.fromJson(Map<String, dynamic> j) =>
      PyqTopic(topic: j['topic'] ?? '', count: j['count'] ?? 0);
}
