import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'my_game.dart';
import 'bird.dart';

class Pipe extends SpriteComponent with HasGameRef<MyGame> {
  final bool isTop;
  static Sprite? pipeSprite;
  bool _passed = false;
  
  // Visual enhancement elements
  late RectangleComponent pipeHighlight;
  late RectangleComponent pipeShadow;

  Pipe({required Vector2 position, required Vector2 size, this.isTop = false})
      : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    sprite = pipeSprite;

    if (isTop) {
      // Flip the sprite vertically for top pipes
      scale.y = -1;
    }
    
    // Add visual enhancements
    // Highlight on one side of the pipe
    final highlightPaint = Paint();
    highlightPaint.color = const Color(0x33FFFFFF); // White with 20% opacity
    
    pipeHighlight = RectangleComponent(
      position: Vector2(size.x * 0.05, 0),
      size: Vector2(size.x * 0.1, size.y),
      paint: highlightPaint,
    );
    add(pipeHighlight);
    
    // Shadow on the other side of the pipe
    final shadowPaint = Paint();
    shadowPaint.color = const Color(0x33000000); // Black with 20% opacity
    
    pipeShadow = RectangleComponent(
      position: Vector2(size.x * 0.85, 0),
      size: Vector2(size.x * 0.1, size.y),
      paint: shadowPaint,
    );
    add(pipeShadow);

    // Add a hitbox for collision detection that's slightly smaller than the pipe
    // This makes the game more forgiving and fun to play
    add(RectangleHitbox(
      size: Vector2(size.x * 0.9, size.y * 0.95), // 90% width, 95% height
      position: Vector2(size.x * 0.05, size.y * 0.025), // Center the hitbox
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Move the pipe to the left
    position += Vector2(-speed * dt, 0);

    // Check if the pipe has passed the bird and hasn't been counted yet
    final bird = gameRef.character;
    if (!_passed && position.x + size.x / 2 < bird.position.x && !isTop) {
      _passed = true;
      gameRef.incrementScore(); // Increment score when a pipe is passed
    }

    // Remove the pipe when it's off-screen
    if (position.x + size.x < 0) {
      removeFromParent();
    }

    super.update(dt);
  }
}
