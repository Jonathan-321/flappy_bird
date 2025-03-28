import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'my_game.dart';

class Bird extends SpriteAnimationComponent with HasGameRef<MyGame>, CollisionCallbacks {
  final double jumpVelocity = 250; // Reduced jump velocity for better control
  double currentVelocityY = 0;
  final double bottom;
  final Function() onGameOver;
  bool isGameOver = false;
  String birdColor;
  double rotation = 0;
  double maxUpwardVelocity = -180; // Limit maximum upward speed
  
  // Visual effects
  late final SpriteComponent shadow; // Shadow effect for depth
  double flapAnimationSpeed = 0.1; // Animation speed for flapping
  
  // Sprites for animation
  late final SpriteAnimation _flyingAnimation;
  
  Bird({
    required Vector2 position,
    required Vector2 size,
    required this.bottom,
    required this.onGameOver,
    this.birdColor = 'yellow',
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Load the bird sprites based on color selection
    final downflapSprite = await gameRef.loadSprite('${birdColor}bird-downflap.png');
    final midflapSprite = await gameRef.loadSprite('${birdColor}bird-midflap.png');
    final upflapSprite = await gameRef.loadSprite('${birdColor}bird-upflap.png');
    
    // Create flapping animation
    _flyingAnimation = SpriteAnimation.spriteList(
      [downflapSprite, midflapSprite, upflapSprite, midflapSprite],
      stepTime: flapAnimationSpeed,
    );
    
    // Set the initial animation
    animation = _flyingAnimation;
    
    // Add a shadow for depth effect
    final shadowPaint = Paint();
    shadowPaint.color = const Color(0x4D000000); // Black with 30% opacity
    
    shadow = SpriteComponent(
      sprite: midflapSprite,
      position: Vector2(0, 5), // Slightly below the bird
      size: size,
      anchor: Anchor.center,
      paint: shadowPaint,
    );
    add(shadow);
    
    // Add collision detection with a smaller hitbox for more forgiving gameplay
    add(RectangleHitbox(
      size: Vector2(size.x * 0.8, size.y * 0.8), // 80% of the sprite size
      position: Vector2(size.x * 0.1, size.y * 0.1), // Center the hitbox
    ));
    
    return super.onLoad();
  }

  void jump() {
    if (!isGameOver) {
      // Add a small boost if already moving upward for more responsive controls
      if (currentVelocityY < 0) {
        currentVelocityY = -jumpVelocity * 1.05;
      } else {
        currentVelocityY = -jumpVelocity;
      }
      
      // Reset rotation for a more immediate visual feedback
      rotation = -0.3;
      
      // Use the game's safe audio method instead of direct call
      gameRef.safePlayAudio('assets/audio/wing.wav');
    }
  }

  @override
  void update(double dt) {
    if (!isGameOver) {
      // Smoother gravity effect near the top of the screen
      final heightRatio = (position.y / bottom).clamp(0.0, 1.0);
      final effectiveGravity = gravity * (0.7 + heightRatio * 0.3);
      
      // Update velocity with smoother acceleration
      currentVelocityY += effectiveGravity * dt;
      
      // Limit maximum falling and rising speed
      currentVelocityY = currentVelocityY.clamp(-jumpVelocity * 0.8, jumpVelocity * 0.6);
      position.y += currentVelocityY * dt;
      
      // Clamp position to screen boundaries with a bit more space at the top
      position.y = position.y.clamp(size.y * 0.8, bottom - size.y / 2);
      
      // Smoother rotation based on velocity
      final targetRotation = (currentVelocityY / jumpVelocity).clamp(-0.3, 0.5);
      rotation = lerpDouble(rotation, targetRotation, 0.1);
      angle = rotation * pi / 3; // Reduced rotation angle
      
      // Update shadow position and opacity based on height
      if (shadow.isMounted) {
        // Shadow gets more transparent as bird gets higher
        final heightRatio = (position.y / bottom).clamp(0.2, 1.0);
        shadow.paint.color = Color.fromRGBO(0, 0, 0, 0.2 * heightRatio);
        shadow.position = Vector2(0, 5 * heightRatio); // Shadow gets closer as bird gets lower
        shadow.angle = angle; // Shadow follows bird rotation
      }
      
      // Adjust flap animation speed based on velocity
      // Flap faster when going up, slower when falling
      final newStepTime = currentVelocityY < 0 ? 0.08 : 0.12;
      if (flapAnimationSpeed != newStepTime) {
        flapAnimationSpeed = newStepTime;
        animation = SpriteAnimation.spriteList(
          _flyingAnimation.frames.map((f) => f.sprite).toList(),
          stepTime: flapAnimationSpeed,
        );
      }
      
      // Check if bird hit the ground
      if (position.y >= bottom - size.y / 2) {
        gameOver();
      }
    }
    
    super.update(dt);
  }
  
  // Helper method to interpolate between two doubles
  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void gameOver() {
    if (!isGameOver) {
      isGameOver = true;
      // Use game's safe audio method
      gameRef.safePlayAudio('assets/audio/hit.wav');
      Future.delayed(const Duration(milliseconds: 300), () {
        gameRef.safePlayAudio('assets/audio/die.wav');
      });
      onGameOver();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isGameOver) {
      super.onCollisionStart(intersectionPoints, other);
      print('Player collided with ${other.runtimeType}');
      // Small delay before game over to make it feel more natural
      Future.delayed(const Duration(milliseconds: 50), () {
        gameOver();
      });
    }
  }
}
