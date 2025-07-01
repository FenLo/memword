import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:memoword/models/word.dart';
import 'package:memoword/screens/category_words_screen.dart';
import 'package:memoword/screens/favorite_words_screen.dart';
import 'package:memoword/screens/my_word_notebook_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class JsonCategory {
  final String title;
  final List<Word> words;

  JsonCategory({required this.title, required this.words});

  factory JsonCategory.fromJson(Map<String, dynamic> json) {
    var wordsList = json['words'] as List? ?? [];
    List<Word> words = wordsList.map((i) => Word.fromJson(i)).toList();
    return JsonCategory(title: json['category'] ?? '', words: words);
  }
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<JsonCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromJson();
  }

  Future<void> _loadCategoriesFromJson() async {
    final String response = await rootBundle.loadString('assets/categories.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _categories = data.map((json) => JsonCategory.fromJson(json)).toList();
    });
  }

  Future<void> _toggleFavorite(Word word) async {
    // For Feelings category, the word is already handled in CategoryWordsScreen
    // So we don't need to do anything here
    if (word.category == 'Feelings' || word.turkish == null) {
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final String? wordsString = prefs.getString('myWords');
    List<Word> myWords = [];
    if (wordsString != null) {
      myWords = (jsonDecode(wordsString) as List).map((i) => Word.fromJson(i)).toList();
    }

    // For regular category words
    int index = myWords.indexWhere((w) => w.english == word.english && w.turkish == word.turkish);

    if (index != -1) {
      // Word is already in myWords, just toggle its favorite status
      myWords[index].isFavorite = !myWords[index].isFavorite;
    } else {
      // Word is not in myWords, add it as a favorite
      myWords.add(word.copyWith(isFavorite: true));
    }

    await prefs.setString('myWords', jsonEncode(myWords.map((w) => w.toJson()).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryCard(
            category: category,
            onToggleFavorite: _toggleFavorite,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Words',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyWordNotebookScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteWordsScreen()));
          }
        },
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final JsonCategory category;
  final Function(Word) onToggleFavorite;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onToggleFavorite,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  double _progressPercentage = 0.0;
  int _totalWords = 0;
  int _learnedWords = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category.title == 'Feelings') {
      _loadFeelingsProgress();
    }
  }

  Future<void> _loadFeelingsProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final learnedWords = prefs.getStringList('learnedFeelingsWords') ?? [];
      
      // Load total words count from words_data.json
      final String response = await rootBundle.loadString('assets/words_data.json');
      final List<dynamic> jsonData = json.decode(response);
      
      setState(() {
        _totalWords = jsonData.length;
        _learnedWords = learnedWords.length;
        _progressPercentage = _totalWords > 0 ? _learnedWords / _totalWords : 0.0;
      });
    } catch (e) {
      print('Error loading feelings progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryWordsScreen(
              category: widget.category,
              onToggleFavorite: widget.onToggleFavorite,
            ),
          ),
        ).then((_) {
          // Refresh progress when returning from CategoryWordsScreen
          if (widget.category.title == 'Feelings') {
            _loadFeelingsProgress();
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.category.title == 'Feelings')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$_learnedWords/$_totalWords words learned',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_progressPercentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B5AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _progressPercentage,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B5AED)),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                    ),
                  ],
                )
              else
                Text('${widget.category.words.length} words'),
            ],
          ),
        ),
      ),
    );
  }
}
