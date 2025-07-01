import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoword/models/word.dart';
import 'package:memoword/screens/category_screen.dart';
import 'package:memoword/widgets/word_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryWordsScreen extends StatefulWidget {
  final JsonCategory category;
  final Function(Word) onToggleFavorite;

  const CategoryWordsScreen({super.key, required this.category, required this.onToggleFavorite});

  @override
  State<CategoryWordsScreen> createState() => _CategoryWordsScreenState();
}

class _CategoryWordsScreenState extends State<CategoryWordsScreen> {
  List<Word> _words = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    if (widget.category.title == 'Feelings') {
      // Load words from words_data.json for Feelings category
      await _loadWordsFromJson();
      // Load learn status after words are loaded
      await _loadLearnStatus();
    } else {
      // Use existing category words
      _words = widget.category.words;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadWordsFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/words_data.json');
      final List<dynamic> jsonData = json.decode(response);
      
      _words = jsonData.map((json) {
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
          turkish: null, // Turkish meanings are not provided in words_data.json
          category: 'Feelings', // Set category for Feelings words
          isLearned: false,
          isFavorite: false,
          creationDate: DateTime.now(),
          phonetic: json['phonetic']?.toString() ?? '',
          allMeanings: allMeanings,
          audioUrl: json['audioUrl']?.toString(),
        );
      }).toList();
    } catch (e) {
      print('Error loading words from JSON: $e');
      _words = [];
    }
  }

  void _toggleLearnStatus(Word word) {
    setState(() {
      word.isLearned = !word.isLearned;
    });
    _saveLearnStatus();
  }

  Future<void> _saveLearnStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedWords = _words.where((word) => word.isLearned).map((word) => word.english).toList();
    await prefs.setStringList('learnedFeelingsWords', learnedWords);
  }

  Future<void> _loadLearnStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final learnedWords = prefs.getStringList('learnedFeelingsWords') ?? [];
    
    setState(() {
      for (var word in _words) {
        word.isLearned = learnedWords.contains(word.english);
      }
    });
  }

  Future<void> _saveFeelingsWordToMyWords(Word word) async {
    final prefs = await SharedPreferences.getInstance();
    final String? wordsString = prefs.getString('myWords');
    List<Word> myWords = [];
    
    if (wordsString != null) {
      myWords = (jsonDecode(wordsString) as List).map((i) => Word.fromJson(i)).toList();
    }

    // Check if word already exists in myWords (for Feelings words, check by english and category)
    int index = myWords.indexWhere((w) => w.english == word.english && w.category == 'Feelings');

    if (index != -1) {
      // Word exists, update its favorite status
      myWords[index].isFavorite = word.isFavorite;
    } else {
      // Word doesn't exist, add it with Feelings category
      myWords.add(word.copyWith(category: 'Feelings'));
    }

    await prefs.setString('myWords', jsonEncode(myWords.map((w) => w.toJson()).toList()));
  }

  double get _progressPercentage {
    if (_words.isEmpty) return 0.0;
    final learnedCount = _words.where((word) => word.isLearned).length;
    return learnedCount / _words.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF666666)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _words.isEmpty
              ? const Center(
                  child: Text(
                    'No words in this category yet.',
                    style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                  ),
                )
              : widget.category.title == 'Feelings'
                  ? Column(
                      children: [
                        // Progress Card
                        Container(
                          margin: const EdgeInsets.all(20.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.psychology,
                                    color: Color(0xFF6B5AED),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Feelings Progress',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_words.where((word) => word.isLearned).length}/${_words.length}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B5AED),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _progressPercentage,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B5AED)),
                                borderRadius: BorderRadius.circular(10),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_progressPercentage * 100).toInt()}% Complete',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Words List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20.0),
                            itemCount: _words.length,
                            itemBuilder: (context, index) {
                              final word = _words[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: WordCard(
                                  word: word,
                                  showEdit: false,
                                  showDelete: false,
                                  showFavorite: true,
                                  showLearnButton: true,
                                  onFavoriteToggle: () {
                                    setState(() {
                                      word.isFavorite = !word.isFavorite;
                                    });
                                    
                                    // For Feelings category, also save to myWords for favorites screen
                                    if (widget.category.title == 'Feelings') {
                                      _saveFeelingsWordToMyWords(word);
                                    }
                                    
                                    widget.onToggleFavorite(word);
                                  },
                                  onLearnToggle: () => _toggleLearnStatus(word),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: _words.length,
                      itemBuilder: (context, index) {
                        final word = _words[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showWordDetailsPopup(context, word),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              word.english,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1A1A1A),
                                              ),
                                            ),
                                            if (word.phonetic != null && word.phonetic!.isNotEmpty)
                                              Text(
                                                word.phonetic!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF666666),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            if (word.turkish != null && word.turkish!.isNotEmpty)
                                              Text(
                                                word.turkish!,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          word.isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: word.isFavorite ? Colors.red : null,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            word.isFavorite = !word.isFavorite;
                                          });
                                          widget.onToggleFavorite(word);
                                        },
                                      ),
                                    ],
                                  ),
                                  if (word.allMeanings != null && word.allMeanings!.isNotEmpty)
                                    ...word.allMeanings!.entries.map((entry) {
                                      final partOfSpeech = entry.key;
                                      final meanings = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              partOfSpeech.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF999999),
                                              ),
                                            ),
                                            if (meanings['definition'] != null && meanings['definition']!.isNotEmpty)
                                              Text(
                                                meanings['definition']!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                            if (meanings['example'] != null && meanings['example']!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  '"${meanings['example']!}"',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF666666),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showWordDetailsPopup(BuildContext context, Word word) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word.english),
              if (word.phonetic != null && word.phonetic!.isNotEmpty)
                Text(
                  word.phonetic!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (word.turkish != null && word.turkish!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Turkish: ${word.turkish}'),
                  ),
                if (word.allMeanings != null && word.allMeanings!.isNotEmpty)
                  ...word.allMeanings!.entries.map((entry) {
                    final partOfSpeech = entry.key;
                    final meanings = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partOfSpeech.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          ),
                          if (meanings['definition'] != null && meanings['definition']!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('Definition: ${meanings['definition']}'),
                            ),
                          if (meanings['example'] != null && meanings['example']!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Example: "${meanings['example']}"',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                const Divider(),
                Text('Learned: ${word.isLearned ? 'Yes' : 'No'}'),
                Text('Favorite: ${word.isFavorite ? 'Yes' : 'No'}'),
                Text('Creation Date: ${word.creationDate.toLocal().toString().split(' ')[0]}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}