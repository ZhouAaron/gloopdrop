//
//  GameScene.swift
//  gloopdrop
//
//  Created by Aaron on 2022/3/19.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let player = Player()
    let playerSPeed: CGFloat = 1.5
    
    // Player movement
    var movingPlayer = false
    var lastPosition: CGPoint?
    
    var level: Int = 1
    var numberOfDrops: Int = 10
    var dropSpeed: CGFloat = 1.0
    var minDropSpeed: CGFloat = 0.12 // (slowest drop)
    var maxDropSpeed: CGFloat = 1.0 // (fastest drop)
    
    override func didMove(to view: SKView) {
        
        // Set up the physics world contact delegate
        physicsWorld.contactDelegate = self
        
        // Set up background
        let background = SKSpriteNode(imageNamed: "background_1")
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = Layer.background.rawValue
        addChild(background)
        
        // Set up foreground
        let foreground = SKSpriteNode(imageNamed: "foreground_1")
        foreground.anchorPoint = CGPoint(x: 0, y: 0)
        foreground.position = CGPoint(x: 0, y: 0)
        foreground.zPosition = Layer.foreground.rawValue
        
        // Add physics body
        foreground.physicsBody = SKPhysicsBody(edgeLoopFrom: foreground.frame)
        foreground.physicsBody?.affectedByGravity = false
        
        // Set up physics categories for contacts
        foreground.physicsBody?.categoryBitMask = PhysicsCategory.foreground
        foreground.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
        foreground.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(foreground)
        
        // Set up player
        player.position = CGPoint(x: size.width/2, y: foreground.frame.maxY)
        addChild(player)
        player.setupConstraints(floor: foreground.frame.maxY)
        player.walk()
        
        spawnMultipleGloops()
        
       
    }
    
    
    // MARK: - GAME FUNCTIONS
    /* ####################################################################### */
    /*                      GAME FUNCTIONS START HERE                          */
    /* ####################################################################### */
    
    func spawnMultipleGloops() {
        
        // Set number of drops based on the level
        switch level {
        case 1, 2, 3, 4, 5:
            numberOfDrops = level * 10
        case 6:
            numberOfDrops = 75
        case 7:
            numberOfDrops = 100
        case 8:
            numberOfDrops = 150
        default:
            numberOfDrops = 150
        }
        
        // Set up drop speed
        dropSpeed = 1 / (CGFloat(level) + (CGFloat(level) / CGFloat(numberOfDrops)))
        if dropSpeed < minDropSpeed {
            dropSpeed = minDropSpeed
        } else if dropSpeed > maxDropSpeed {
            dropSpeed = maxDropSpeed
        }
        
        // Set up repeating action
        let wait = SKAction.wait(forDuration: TimeInterval(dropSpeed))
        let spawn = SKAction.run { [unowned self] in self.spawnGloop() }
        let sequence = SKAction.sequence([wait, spawn])
        let repeatAction = SKAction.repeat(sequence, count: numberOfDrops)
        
        // Run action
        run(repeatAction, withKey: "gloop")
    }
    func spawnGloop() {
        let collectible = Collectible(collectibleType: CollectibleType.gloop)
        
        // set random position
        let margin = collectible.size.width * 2
        let dropRange = SKRange(lowerLimit: frame.minX + margin, upperLimit: frame.maxX - margin)
        let randomX = CGFloat.random(in: dropRange.lowerLimit...dropRange.upperLimit)
        collectible.position = CGPoint(x: randomX,
                                       y: player.position.y * 2.5)
        
        addChild(collectible)
        
        collectible.drop(dropSpeed: TimeInterval(1.0), floorLevel: player.frame.minY)
    }
    
    // MARK: - TOUCH HANDLING
    /* ####################################################################### */
    /*                        TOUCH HANDLERS STARTS HERE                       */
    /* ####################################################################### */
    func touchDown(atPoint pos : CGPoint) {
        
        // Calculate the speed based on current position and tap location
        // hypot() uses a bit of trigonometry to calculate the distance between the two points.
//        let distance = hypot(pos.x - player.position.x, pos.y - player.position.y)
//        let calculatedSpeed = TimeInterval(distance / playerSPeed) / 255
////        print(" distance: \(distance) \n claculatedSpeed: \(calculatedSpeed)")
//        if pos.x < player.position.x {
//            player.moveToPosition(pos: pos, direction: "L", speed: calculatedSpeed)
//        } else {
//            player.moveToPosition(pos: pos, direction: "R", speed: calculatedSpeed)
//        }
        let touchedNode = atPoint(pos)
        if touchedNode.name == "player" {
            movingPlayer = true
        }
    }
    
    func touchMoved(toPoint pos: CGPoint) {
        if movingPlayer == true {
            // Clamp position
            let newPos = CGPoint(x: pos.x, y: player.position.y)
            player.position = newPos
            
            // Check last position; if empty set it
            // ？？ 空合运算符
            let recordedPosition = lastPosition ?? player.position
            if recordedPosition.x > newPos.x {
                player.xScale = -abs(xScale)
            } else {
                player.xScale = abs(xScale)
            }
            
            // Save last known position
            lastPosition = newPos
        }
    }
    
    func touchUp(atPoint pos: CGPoint) {
        movingPlayer = false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self))}
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self))}
    }
}

// MARK: - COLLISION DETECTION
/* ####################################################################### */
/*                 COLLISION DETECTION METHODS START HERE                  */
/* ####################################################################### */
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Check collision bodies
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Did the [PLAYER] collide with the [COLLECTIBLE]?
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
            
            print("player hit collectible")
            
            // Find out which body is attached to collectible node
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ? contact.bodyA.node : contact.bodyB.node
            
            // Verify the object is collectible
            if let sprite = body as? Collectible {
                sprite.collected()
            }
        }
        // or did the [COLLECTIBLE] collide with the [FOREGROUND]?
        if collision == PhysicsCategory.foreground | PhysicsCategory.collectible {
            print("collectible hit foreground")
            
            // Find out which body is attached to the collectible node
            let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ? contact.bodyA.node : contact.bodyB.node
            
            // Verify the object is a collectible
            if let sprite = body as? Collectible {
                sprite.missed()
            }
            
        }
    }
}
