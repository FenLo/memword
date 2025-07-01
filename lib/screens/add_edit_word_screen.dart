import 'package:flutter/material.dart';
import 'package:memoword/models/word.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddEditWordScreen extends StatefulWidget {
  final Word? wordToEdit;

  const AddEditWordScreen({super.key, this.wordToEdit});

  @override
  State<AddEditWordScreen> createState() => _AddEditWordScreenState();
}

class _AddEditWordScreenState extends State<AddEditWordScreen> {
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  String? _englishDefinition;
  String? _example;
  String? _audioUrl;
  Map<String, Map<String, String>>? _allMeanings;
  bool _isLoadingDefinition = false;

  @override
  void initState() {
    super.initState();
    if (widget.wordToEdit != null) {
      _wordController.text = widget.wordToEdit!.english;
      _meaningController.text = widget.wordToEdit!.turkish ?? '';
      _englishDefinition = widget.wordToEdit!.englishDefinition;
      _example = widget.wordToEdit!.example;
      _audioUrl = widget.wordToEdit!.audioUrl;
      _allMeanings = widget.wordToEdit!.allMeanings;
    }
    _wordController.addListener(() {
      final word = _wordController.text.trim();
      if (word.isNotEmpty) {
        _fetchEnglishDefinition(word);
      } else {
        setState(() {
          _englishDefinition = null;
          _example = null;
          _audioUrl = null;
          _allMeanings = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _fetchEnglishDefinition(String word) async {
    setState(() {
      _isLoadingDefinition = true;
      _englishDefinition = null;
      _example = null;
      _audioUrl = null;
      _allMeanings = null;
    });
    try {
      final response = await http.get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final meanings = data[0]['meanings'];
          if (meanings is List && meanings.isNotEmpty) {
            // Tüm anlam türlerini topla
            Map<String, Map<String, String>> allMeanings = {};
            
            for (var meaning in meanings) {
              String partOfSpeech = meaning['partOfSpeech'] ?? 'unknown';
              final definitions = meaning['definitions'];
              
              if (definitions is List && definitions.isNotEmpty) {
                String definition = definitions[0]['definition'] ?? '';
                String example = definitions[0]['example'] ?? '';
                
                allMeanings[partOfSpeech] = {
                  'definition': definition,
                  'example': example,
                };
              }
            }
            
            // İlk anlamı varsayılan olarak ayarla (geriye uyumluluk için)
            String? firstDefinition;
            String? firstExample;
            if (allMeanings.isNotEmpty) {
              var firstMeaning = allMeanings.values.first;
              firstDefinition = firstMeaning['definition'];
              firstExample = firstMeaning['example'];
            }
            
            setState(() {
              _allMeanings = allMeanings;
              _englishDefinition = firstDefinition;
              _example = firstExample;
            });
          }
          
          // Phonetics (audio)
          final phonetics = data[0]['phonetics'];
          if (phonetics is List && phonetics.isNotEmpty) {
            final audio = phonetics.firstWhere(
              (p) => p['audio'] != null && (p['audio'] as String).isNotEmpty,
              orElse: () => null,
            );
            if (audio != null && audio['audio'] != null) {
              setState(() {
                _audioUrl = audio['audio'];
              });
            }
          }
        }
      }
    } catch (e) {
      // ignore error, leave definition/example/audio null
    }
    setState(() {
      _isLoadingDefinition = false;
    });
  }

  void _saveWord() {
    final wordText = _wordController.text.trim();
    final meaningText = _meaningController.text.trim();
    final definitionText = _englishDefinition;
    final exampleText = _example;
    final audioUrl = _audioUrl;
    final allMeanings = _allMeanings;

    if (wordText.isNotEmpty) {
      if (widget.wordToEdit != null) {
        // Editing existing word
        final updatedWord = widget.wordToEdit!.copyWith(
          english: wordText,
          turkish: meaningText.isEmpty ? null : meaningText,
          category: null,
          englishDefinition: definitionText,
          example: exampleText,
          audioUrl: audioUrl,
          allMeanings: allMeanings,
        );
        Navigator.pop(context, updatedWord);
      } else {
        // Adding new word
        final newWord = Word(
          english: wordText,
          turkish: meaningText.isEmpty ? null : meaningText,
          category: null,
          creationDate: DateTime.now(),
          isLearned: false,
          englishDefinition: definitionText,
          example: exampleText,
          audioUrl: audioUrl,
          allMeanings: allMeanings,
        );
        Navigator.pop(context, newWord);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kelimeyi girin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wordToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Kelimeyi Düzenle' : 'Yeni Kelime Ekle',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0E7FF), // #E0E7FF
              Color(0xFFF3E8FF), // #F3E8FF
              Color(0xFFFEF3C7), // #FEF3C7
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // screen padding
          child: Column(
            children: [
              TextField(
                controller: _wordController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Kelime',
                ),
              ),
              const SizedBox(height: 16.0), // itemSpacing
              TextField(
                controller: _meaningController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Anlamı',
                  hintText: 'İsteğe bağlı',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12.0),
              const SizedBox(height: 24.0), // sectionSpacing
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveWord,
                  child: Text(
                    isEditing ? 'Değişiklikleri Kaydet' : 'Kelimeyi Kaydet',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
