import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'bird.dart';
import 'pipe.dart';

// Component to update the score display
class ScoreDisplayComponent extends Component {
  final TextComponent textComponent;
  final MyGame game;
  
  ScoreDisplayComponent(this.textComponent, this.game);
  
  @override
  void update(double dt) {
    textComponent.text = game.score.toString();
  }
}

const speed = 60; // Reduced speed for easier gameplay
const gapInSeconds = 4.0; // Even more time between pipes for easier gameplay
const gravity = 500; // Reduced gravity for more manageable falling
const pipeGapSize = 200.0; // Reasonable gap between pipes

class MyGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Bird character;
  double baseHeight = 0; // Initialize with a default value
  late Sprite baseSprite;
  double delta = 0;
  int score = 0;
  final List<SpriteComponent> bases = [];
  final List<Component> backgrounds = []; // Changed to Component to accept different component types
  final Random _random = Random();
  
  // Game settings
  String birdColor = 'yellow'; // Default bird color
  String pipeColor = 'green'; // Default pipe color
  bool isNightMode = false; // Default background mode

  final Function() onGameOver;

  MyGame({
    required this.onGameOver,
    this.birdColor = 'yellow',
    this.pipeColor = 'green',
    this.isNightMode = false,
  });

  // Helper method to play audio safely - disabled for web to avoid errors
  void safePlayAudio(String audioPath) {
    // Skip audio on web platform to avoid format errors
    if (kIsWeb) {
      // Just print for debugging
      print('Audio skipped on web: $audioPath');
      return;
    }
    
    try {
      FlameAudio.play(audioPath);
    } catch (e) {
      // Silently handle audio errors
      print('Audio play error: $e');
    }
  }
  
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Set a fixed game size for better scaling
    // We'll use the default viewport instead of a custom one
    
    // We won't preload audio for web as it causes issues
    // Instead, we'll handle errors when playing audio

    // Create a solid color background based on day/night setting
    final Paint bgPaint = Paint()
      ..color = isNightMode ? const Color(0xFF1A237E) : const Color(0xFF03A9F4)
      ..style = PaintingStyle.fill;
    
    // Load pipe sprite based on color setting
    Pipe.pipeSprite = await loadSprite('pipe-${pipeColor}.png');

    // Create scrolling background
    createScrollingBackground(bgPaint);

    // Load base sprite and set up the ground
    baseSprite = await loadSprite('base.png');
    // Set baseHeight as percentage of screen height
    baseHeight = size.y * 0.15;
    
    // Ensure baseHeight is initialized
    if (baseHeight <= 0) {
      baseHeight = size.y * 0.15; // Default to 15% of screen height
    }
    
    // Create the bird character with the selected color
    character = Bird(
      position: Vector2(100, size.y / 2),
      size: Vector2(50, 35),
      bottom: (size.y - baseHeight / 2),
      onGameOver: onGameOver,
      birdColor: birdColor,
    );
    
    // Add a score display
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 3),
        ],
      ),
    );
    
    final scoreDisplay = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, size.y * 0.1),
      anchor: Anchor.center,
      textRenderer: textPaint,
    );
    add(scoreDisplay);
    
    // Create a simple update function for the score display
    add(ScoreDisplayComponent(scoreDisplay, this));
    add(character);
    
    // Set up the ground
    reloadBases();
    
    // Create initial pipes
    createPipePair();
  }

  @override
  void onTapDown(TapDownInfo info) {
    character.jump();
  }

  // Create scrolling background with parallax effect
  void createScrollingBackground(Paint bgPaint) {
    // Ensure baseHeight is initialized with a reasonable value if it's still 0
    if (baseHeight <= 0) {
      baseHeight = size.y * 0.15; // Default to 15% of screen height
    }
    
    // Create a background rectangle that fills the screen
    final bgRect = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(size.x, size.y - baseHeight),
      paint: bgPaint,
    );
    add(bgRect);
    
    // Add a subtle gradient overlay for better aesthetics
    final gradientPaint = Paint();
    final Rect gradientRect = Rect.fromLTWH(0, 0, size.x, size.y - baseHeight);
    
    // Create a simple gradient from transparent to a light color
    gradientPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0x00FFFFFF), // Transparent
        isNightMode ? const Color(0x333F51B5) : const Color(0x3303A9F4), // Semi-transparent indigo or light blue
      ],
    ).createShader(gradientRect);
    
    // Add the gradient as a rectangle component
    final gradientComponent = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(size.x, size.y - baseHeight),
      paint: gradientPaint,
    );
    add(gradientComponent);
    
    // Add some cloud components for visual effect
    final random = Random();
    for (int i = 0; i < 5; i++) {
      // Create cloud using SpriteComponent with a white rectangle texture
      final cloudWidth = random.nextDouble() * 100 + 50;
      final cloudHeight = random.nextDouble() * 30 + 20;
      final cloudX = random.nextDouble() * size.x;
      final cloudY = random.nextDouble() * (size.y - baseHeight - cloudHeight);
      
      // Create a white rectangle for the cloud
      final cloud = RectangleComponent(
        position: Vector2(cloudX, cloudY),
        size: Vector2(cloudWidth, cloudHeight),
        paint: Paint()..color = Colors.white.withOpacity(0.7),
      );
      
      // Add the cloud to the game and to our list for tracking
      backgrounds.add(cloud);
      add(cloud);
    }
  }
  
  // Create a pair of pipes with random height
  void createPipePair() {
    final pipeWidth = size.x * 0.1; // Even thinner pipes for easier passage
    
    // More balanced gap positioning with wider range
    final minY = size.y * 0.3; // Higher minimum height
    final maxY = size.y * 0.6; // Lower maximum height
    final gapY = minY + _random.nextDouble() * (maxY - minY);
    
    // Ensure we have a valid range for the gap
    if (gapY + pipeGapSize > size.y - baseHeight) {
      print('Warning: Not enough vertical space for pipes');
      return;
    }
    
    // Create top pipe with more reasonable height
    final topPipeHeight = gapY - pipeGapSize/2;
    final topPipe = Pipe(
      position: Vector2(size.x + pipeWidth/2, topPipeHeight/2),
      size: Vector2(pipeWidth, topPipeHeight),
      isTop: true,
    );
    
    // Create bottom pipe with more reasonable height
    final bottomPipeHeight = size.y - gapY - pipeGapSize/2 - baseHeight;
    final bottomPipe = Pipe(
      position: Vector2(size.x + pipeWidth/2, gapY + pipeGapSize/2 + bottomPipeHeight/2),
      size: Vector2(pipeWidth, bottomPipeHeight),
      isTop: false,
    );
    
    // Add visual indicator for the gap
    final gapIndicator = RectangleComponent(
      position: Vector2(size.x + pipeWidth/2, gapY),
      size: Vector2(pipeWidth * 0.1, pipeGapSize * 0.1),
      paint: Paint()..color = Colors.white.withOpacity(0.3),
      anchor: Anchor.center,
    );
    
    add(topPipe);
    add(bottomPipe);
    add(gapIndicator);
  }

  @override
  void update(double dt) {
    // Update scrolling background - only update cloud positions
    for (final bg in backgrounds) {
      if (bg is RectangleComponent && bg.position.x != 0) { // Skip the main background rectangle
        bg.position.x -= speed * dt * 0.5; // Clouds move slower than pipes for parallax effect
        
        // If cloud is off-screen, move it to the right
        if (bg.position.x <= -bg.size.x) {
          bg.position.x = size.x + _random.nextDouble() * 100;
          bg.position.y = _random.nextDouble() * (size.y - baseHeight - bg.size.y);
          
          // Randomize cloud opacity for more natural look
          if (bg.paint != null) {
            bg.paint!.color = Colors.white.withOpacity(0.5 + _random.nextDouble() * 0.3);
          }
        }
      }
    }
    
    // Update base positions
    for (final base in bases) {
      base.position.x -= speed * dt;
      
      // If base is off-screen, move it to the right
      if (base.position.x <= -base.size.x) {
        base.position.x += base.size.x * bases.length;
      }
    }
    
    // Generate new pipes
    delta += dt;
    if (delta > gapInSeconds) {
      delta %= gapInSeconds;
      createPipePair();
    }

    super.update(dt);
  }

  void reloadBases() {
    for (final base in bases) {
      base.removeFromParent();
    }
    bases.clear();

    // Create two base components for seamless scrolling
    for (int i = 0; i < 2; i++) {
      final base = SpriteComponent()
        ..sprite = baseSprite
        ..size = Vector2(size.x, baseHeight)
        ..position = Vector2(i * size.x, size.y - (baseHeight / 2));
      
      bases.add(base);
      add(base);
    }
  }
  
  // Method to increment score when bird passes a pipe
  void incrementScore() {
    score++;
    safePlayAudio('assets/audio/point.wav');
    
    // Simple score notification
    print('Score increased to: $score');
  }
}
