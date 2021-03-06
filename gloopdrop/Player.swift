//
//  Player.swift
//  gloopdrop
//
//  Created by Aaron on 2022/3/20.
//

import Foundation
import SpriteKit

enum PlayerAnimationType: String {
    case walk
    case die
}

class Player: SKSpriteNode {
    // MARK: - PROPERTIES
    
    private var walkTextures: [SKTexture]?
    private var dieTextures: [SKTexture]?
    // MARK: - INIT
    
    init() {
        // Set default texture
        let texture = SKTexture(imageNamed: "blob-walk_0")
        
        // Call to super.init
        super.init(texture: texture, color: .clear, size: texture.size())
        
        // Set up animation textures
        self.walkTextures = self.loadTextures(atlas: "blob", prefix: "blob-walk_", startAt: 0, stopsAt: 2)
        self.dieTextures = self.loadTextures(atlas: "blob", prefix: "blob-die_", startAt: 0, stopsAt: 0)
        // Set up other properties after init
        self.name = "player"
        self.setScale(1.0)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.0) // center-bottom
        self.zPosition = Layer.player.rawValue
        
        // Add physics body
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: self.size.height / 2))
        self.physicsBody?.affectedByGravity = false
        
        // Set up physics categories for contacts
        self.physicsBody?.categoryBitMask = PhysicsCategory.player
        self.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        self.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        // Add crosshairs
        let crosshairs = SKSpriteNode(imageNamed: "crosshairs")
        crosshairs.name = "crosshairs"
        crosshairs.position = CGPoint(x: 0.0, y: size.height * 2.12)
        crosshairs.alpha = 0.25
        self.addChild(crosshairs)

        // Add controller ring
        let moveController = SKSpriteNode(imageNamed: "controller")
        moveController.zPosition = Layer.player.rawValue
        moveController.position = CGPoint(x: 0, y: -51)
        moveController.name = "controller"
        self.addChild(moveController)
            
        // The player hit marker was too small; this makes it easier to control
        let playerController = SKShapeNode(rect: CGRect(x: -self.size.width/1.5,
                                                     y: 0.0,
                                                     width: self.size.width * 1.5,
                                                     height: self.size.height * 1.5))
            
        playerController.name = "controller"
        playerController.fillColor = .clear
        playerController.alpha = 1.0
        playerController.strokeColor = .clear
        playerController.zPosition = Layer.player.rawValue
        self.addChild(playerController)
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    // MARK: - METHODS
    
    func setupConstraints(floor: CGFloat) {
        let range = SKRange(lowerLimit: floor, upperLimit: floor)
        let lockToPlatform = SKConstraint.positionY(range)
        
        constraints = [ lockToPlatform ]
    }
    
    func mumble() {
        let random = Int.random(in: 1...3)
        let playSound = SKAction.playSoundFileNamed("blob_mumble-\(random)", waitForCompletion: true)
        self.run(playSound, withKey: "mumble")
    }
    func walk() {
        // Check for textures
        guard let walkTextures = walkTextures else {
            preconditionFailure("Could not find textures!")
        }
        
        // Stop the die animation
        removeAction(forKey: PlayerAnimationType.die.rawValue)
        
        // Run animation (forever)
        startAnimation(textures: walkTextures, speed: 0.25, name: PlayerAnimationType.walk.rawValue, count: 0, resize: true, restore: true)
    }
    
    func die() {
        // Check for textures
        guard let dieTextures = dieTextures else {
            preconditionFailure("Could not find textures!")
        }
        
        // Stop the walk animation
        removeAction(forKey: PlayerAnimationType.walk.rawValue)
        
        // Run animation(forever)
        startAnimation(textures: dieTextures, speed: 0.25, name: PlayerAnimationType.die.rawValue, count: 0, resize: true, restore: true)

    }
    
    func moveToPosition(pos: CGPoint, direction: String, speed: TimeInterval) {
        switch direction {
        case "L":
            xScale = -abs(xScale)
        default:
            xScale = abs(xScale)
        }
        let moveAction = SKAction.move(to: pos, duration: speed)
        run(moveAction)
    }
}
