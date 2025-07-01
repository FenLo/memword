class Word {
  final String english;
  final String? turkish;
  final String? category;
  bool isLearned; // Changed from final to non-final
  bool isFavorite; // Changed to non-final as it will be toggled
  final DateTime creationDate;
  final String? englishDefinition;
  final String? example;
  final String? audioUrl;
  final String? phonetic;
  final Map<String, Map<String, String>>? allMeanings; // partOfSpeech -> {definition, example}

  Word({
    required this.english,
    this.turkish,
    this.category,
    this.isLearned = false,
    this.isFavorite = false, // Added isFavorite
    DateTime? creationDate,
    this.englishDefinition,
    this.example,
    this.audioUrl,
    this.phonetic,
    this.allMeanings,
  }) : creationDate = creationDate ?? DateTime.now();

  // Convert a Word object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'turkish': turkish,
      'category': category,
      'isLearned': isLearned,
      'isFavorite': isFavorite, // Added isFavorite
      'creationDate': creationDate.toIso8601String(),
      'englishDefinition': englishDefinition,
      'example': example,
      'audioUrl': audioUrl,
      'phonetic': phonetic,
      'allMeanings': allMeanings,
    };
  }

  // Create a Word object from a Map object
  factory Word.fromJson(Map<String, dynamic> json) {
    // Parse allMeanings correctly
    Map<String, Map<String, String>>? allMeanings;
    if (json['allMeanings'] != null) {
      allMeanings = {};
      final meaningsMap = json['allMeanings'] as Map<String, dynamic>;
      meaningsMap.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          allMeanings![key] = {
            'definition': value['definition']?.toString() ?? '',
            'example': value['example']?.toString() ?? '',
          };
        }
      });
    }

    return Word(
      english: json['english'] ?? '',
      turkish: json['turkish'],
      category: json['category'],
      isLearned: json['isLearned'] ?? false,
      isFavorite: json['isFavorite'] ?? false, // Added isFavorite
      creationDate: json['creationDate'] != null 
          ? DateTime.parse(json['creationDate'])
          : DateTime.now(),
      englishDefinition: json['englishDefinition'],
      example: json['example'],
      audioUrl: json['audioUrl'],
      phonetic: json['phonetic'],
      allMeanings: allMeanings,
    );
  }

  Word copyWith({
    String? english,
    String? turkish,
    String? category,
    bool? isLearned,
    bool? isFavorite, // Added isFavorite
    DateTime? creationDate,
    String? englishDefinition,
    String? example,
    String? audioUrl,
    String? phonetic,
    Map<String, Map<String, String>>? allMeanings,
  }) {
    return Word(
      english: english ?? this.english,
      turkish: turkish ?? this.turkish,
      category: category ?? this.category,
      isLearned: isLearned ?? this.isLearned,
      isFavorite: isFavorite ?? this.isFavorite, // Added isFavorite
      creationDate: creationDate ?? this.creationDate,
      englishDefinition: englishDefinition ?? this.englishDefinition,
      example: example ?? this.example,
      audioUrl: audioUrl ?? this.audioUrl,
      phonetic: phonetic ?? this.phonetic,
      allMeanings: allMeanings ?? this.allMeanings,
    );
  }
}
