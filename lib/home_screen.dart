import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'my_game.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Selected customization options
  String selectedBirdColor = 'yellow';
  String selectedPipeColor = 'green';
  bool isNightMode = false;
  
  // Available options
  final List<String> birdColors = ['yellow', 'red', 'blue'];
  final List<String> pipeColors = ['green', 'red'];
  
  @override
  void initState() {
    super.initState();
    // Preload audio files
    _preloadAudio();
  }
  
  Future<void> _preloadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'assets/audio/swoosh.wav',
      ]);
    } catch (e) {
      print('Audio preloading error: $e');
      // Continue even if audio loading fails
    }
  }
  
  void gameOver() => Navigator.of(context).pop();
  
  void _startGame() {
    try {
      FlameAudio.play('assets/audio/swoosh.wav');
    } catch (e) {
      print('Audio play error: $e');
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => GameWidget(
        game: MyGame(
          onGameOver: gameOver,
          birdColor: selectedBirdColor,
          pipeColor: selectedPipeColor,
          isNightMode: isNightMode,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: isNightMode ? Colors.indigo.shade900 : Colors.lightBlue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game title
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Flappy Bird',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black),
                    ],
                  ),
                ),
              ),
              
              // Customization options
              Container(
                width: 400,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Bird color selection
                    Text('Bird Color', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: birdColors.map((color) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedBirdColor = color;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedBirdColor == color ? Colors.blue : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/images/${color}bird-midflap.png',
                                width: 50,
                                height: 50,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Pipe color selection
                    Text('Pipe Color', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: pipeColors.map((color) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPipeColor = color;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedPipeColor == color ? Colors.blue : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                'assets/images/pipe-${color}.png',
                                width: 40,
                                height: 80,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Day/Night mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Day/Night Mode:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Switch(
                          value: isNightMode,
                          onChanged: (value) {
                            setState(() {
                              isNightMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Start game button
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(offset: Offset(0, 3), blurRadius: 5, color: Colors.black.withOpacity(0.3)),
                    ],
                  ),
                  child: Text(
                    'Start Game',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
