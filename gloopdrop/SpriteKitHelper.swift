//
//  SpriteKitHelper.swift
//  gloopdrop
//
//  Created by Aaron on 2022/3/20.
//

import Foundation
import SpriteKit


// MARK: - SPRITEKIT HELPERS

// Set up shared z-positions
enum Layer: CGFloat {
    case background
    case foreground
    case player
    case collectible
}
// SpriteKit Physics Categories
enum PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1   // 1
    static let collectible: UInt32 = 0b10  // 2
    static let foreground:  UInt32 = 0b100 // 4
}
// MARK: - SPRITEKIT EXTENSIONS

extension SKSpriteNode {
    // Used to load texture arrays for animations
    // an atlas name, a prefix, and the start and stop frame numbers for the animation. It then uses a for-in loop to build and return the array of textures.
    func loadTextures(atlas: String, prefix: String, startAt: Int, stopsAt: Int) -> [SKTexture] {
        var textureArray = [SKTexture]()
        let textureAtlas = SKTextureAtlas(named: atlas)
        for i in startAt...stopsAt {
            let textureName = "\(prefix)\(i)"
            let temp = textureAtlas.textureNamed(textureName)
            textureArray.append(temp)
        }
        return textureArray
    }
    
    // Start the animation using a name and a count (0 = repeat forever)
    func startAnimation(textures: [SKTexture], speed: Double, name: String, count: Int, resize: Bool, restore: Bool) {
        // Run animation only if animation key doesn't already exist
        if (action(forKey: name) == nil) {
            // The first action sets up the frame-by-frame animation using the supplied textures. The code then cycles through these textures based on the value of timePerFrame. The timePerFrame is the amount of time, in seconds, each texture is displayed. The other parameters, resize and restore, indicate how the action should handle the size and final texture for the node. When resize = true, the sprite’s size matches the image size. When restore = true, the original texture is restored when the action completes.
            let animation = SKAction.animate(with: textures, timePerFrame: speed, resize: resize, restore: restore)
            if count == 0 {
                // Run animation until stopped
                // how many times to repeat the action
                let repeatAction = SKAction.repeatForever(animation)
                run(repeatAction, withKey: name)
            } else if count == 1 {
                run(animation, withKey: name)
            } else {
                // determine how often to repeat the action: when a value of 0 is passed into the method, the action repeats forever, whereas if any other number is passed in, the action repeats the specified number of times.
                let repeatAction = SKAction.repeat(animation, count: count)
                run(repeatAction, withKey: name)
            }
        }
    }
}
