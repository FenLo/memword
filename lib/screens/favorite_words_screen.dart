import 'package:flutter/material.dart';
import 'package:memoword/models/word.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/word_card.dart';

class FavoriteWordsScreen extends StatefulWidget {
  const FavoriteWordsScreen({super.key});

  @override
  State<FavoriteWordsScreen> createState() => _FavoriteWordsScreenState();
}

class _FavoriteWordsScreenState extends State<FavoriteWordsScreen> {
  List<Word> favoriteWords = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteWords();
  }

  Future<void> _loadFavoriteWords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? wordsString = prefs.getString('myWords'); // Load from the same storage as MyWordNotebookScreen
    if (wordsString != null) {
      final List<dynamic> jsonList = jsonDecode(wordsString);
      List<Word> allWords = jsonList.map((json) => Word.fromJson(json)).toList();
      
      List<Word> words = allWords.where((word) => word.isFavorite).toList();
      
      // Load learned status for Feelings category words
      final learnedWords = prefs.getStringList('learnedFeelingsWords') ?? [];
      
      // Update learned status for Feelings words
      for (var word in words) {
        if (word.category == 'Feelings' || word.turkish == null) {
          word.isLearned = learnedWords.contains(word.english);
        }
      }
      
      setState(() {
        favoriteWords = words;
      });
    }
  }

  Future<void> _toggleFavorite(Word word) async {
    // This screen only displays favorites, so toggling means removing from favorites
    // We need to update the main list of words and then reload favorites
    final prefs = await SharedPreferences.getInstance();
    final String? wordsString = prefs.getString('myWords');
    if (wordsString != null) {
      List<dynamic> jsonList = jsonDecode(wordsString);
      List<Word> allWords = jsonList.map((json) => Word.fromJson(json)).toList();

      int index;
      if (word.category == 'Feelings' || word.turkish == null) {
        // For Feelings category words, check by english and category
        index = allWords.indexWhere((w) => w.english == word.english && w.category == 'Feelings');
      } else {
        // For regular words, check by english and turkish
        index = allWords.indexWhere((w) => w.english == word.english && w.turkish == word.turkish);
      }
      
      if (index != -1) {
        allWords[index].isFavorite = !allWords[index].isFavorite; // Toggle favorite status
        await prefs.setString('myWords', jsonEncode(allWords.map((w) => w.toJson()).toList()));
        _loadFavoriteWords(); // Reload favorite words after update
      }
    }
  }

  Future<void> _toggleLearnedStatus(Word word) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (word.category == 'Feelings' || word.turkish == null) {
      // Handle Feelings category words
      final learnedWords = prefs.getStringList('learnedFeelingsWords') ?? [];
      
      if (word.isLearned) {
        learnedWords.remove(word.english);
      } else {
        learnedWords.add(word.english);
      }
      
      await prefs.setStringList('learnedFeelingsWords', learnedWords);
      
      // Update the word in the local list
      setState(() {
        word.isLearned = !word.isLearned;
      });
    } else {
      // Handle regular words from myWords
      final String? wordsString = prefs.getString('myWords');
      if (wordsString != null) {
        List<dynamic> jsonList = jsonDecode(wordsString);
        List<Word> allWords = jsonList.map((json) => Word.fromJson(json)).toList();

        int index;
        if (word.category == 'Feelings' || word.turkish == null) {
          // For Feelings category words, check by english and category
          index = allWords.indexWhere((w) => w.english == word.english && w.category == 'Feelings');
        } else {
          // For regular words, check by english and turkish
          index = allWords.indexWhere((w) => w.english == word.english && w.turkish == word.turkish);
        }
        
        if (index != -1) {
          allWords[index].isLearned = !allWords[index].isLearned;
          await prefs.setString('myWords', jsonEncode(allWords.map((w) => w.toJson()).toList()));
          
          // Update the word in the local list
          setState(() {
            word.isLearned = !word.isLearned;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Words',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF666666)),
      ),
      body: favoriteWords.isEmpty
          ? const Center(
              child: Text(
                'No favorite words yet.',
                style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              itemCount: favoriteWords.length,
              itemBuilder: (context, index) {
                final word = favoriteWords[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: WordCard(
                    word: word,
                    onFavoriteToggle: () => _toggleFavorite(word),
                    onLearnToggle: () => _toggleLearnedStatus(word),
                    showFavorite: true,
                    showEdit: false,
                    showDelete: false,
                    showLearnButton: true,
                  ),
                );
              },
            ),
    );
  }
}
