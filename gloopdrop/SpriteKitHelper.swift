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
    case ui
}
// SpriteKit Physics Categories
enum PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b1   // 1
    static let collectible: UInt32 = 0b10  // 2
    static let foreground:  UInt32 = 0b100 // 4
}
// MARK: - SPRITEKIT EXTENSIONS

extension SKNode {
    
    // Used to set up an endless scroller
    func setupScrollingView(imageNamed name: String, layer: Layer, emitterNamed: String?, blocks: Int, speed: TimeInterval) {
        // Create sprite nodes; set position based on the node's # and width
        for i in 0..<blocks {
            let spriteNode = SKSpriteNode(imageNamed: name)
            spriteNode.anchorPoint = CGPoint.zero
            spriteNode.position = CGPoint(x: CGFloat(i) * spriteNode.size.width, y: 0)
            spriteNode.zPosition = layer.rawValue
            spriteNode.name = name
            
            // Set up optional particles
            if let emitterNamed = emitterNamed, let particles = SKEmitterNode(fileNamed: emitterNamed) {
                particles.name = "particles"
                spriteNode.addChild(particles)
            }
            
            // Use the custom extension to scroll
            spriteNode.endlessScroll(speed: speed)
            
            // Add the sprite node to the container
            addChild(spriteNode)
        }
    }
}
extension SKSpriteNode {
    
    // Used to create an endless scrolling background
    func endlessScroll(speed: TimeInterval) {
        
        // set up actions to move and reset nodes
        let moveAction = SKAction.moveBy(x: -self.size.width, y: 0, duration: speed) // takes the sprite node and moves it to the specified x-position at the desired speed.It uses the width of the node to determine how far to move it.
        let resetAction = SKAction.moveBy(x: self.size.width, y: 0, duration: 0.0)
        
        // Set up a sequence of repeating actions
        let sequenceAction = SKAction.sequence([moveAction, resetAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        
        // Run the repeating action
        self.run(repeatAction)
    }
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

extension SKScene {
    
    // convert the view’s coordinates to scene coordinates
    // Top of View
    func viewTop() -> CGFloat {
        return convertPoint(fromView: CGPoint(x: 0, y: 0)).y
    }
    
    // Bottom of View
    func viewBottom() -> CGFloat {
        guard let view = view else { return 0.0 }
        return convertPoint(fromView: CGPoint(x: 0.0, y: view.bounds.size.height)).y
    }
    
}
