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
    
    var level: Int = 1 {
        didSet {
            levelLabel.text = "Level: \(level)"
        }
    }
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var numberOfDrops: Int = 10
    var dropsExpected = 10
    var dropsCollected = 0
    var dropSpeed: CGFloat = 1.0
    var minDropSpeed: CGFloat = 0.12 // (slowest drop)
    var maxDropSpeed: CGFloat = 1.0 // (fastest drop)
    
    // Labels
    var scoreLabel: SKLabelNode = SKLabelNode()
    var levelLabel: SKLabelNode = SKLabelNode()
    
    // Game states
    var gameInProgress = false
//    var playingLevel = false
    
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
        
        // Set up User Interface
        setupLabels()
        
        // Set up player
        player.position = CGPoint(x: size.width/2, y: foreground.frame.maxY)
        addChild(player)
        player.setupConstraints(floor: foreground.frame.maxY)
//        player.walk()
        
//        spawnMultipleGloops()
        
       // Show message
        showMessage("Tap to start game")
        
    }
    
    func setupLabels() {
        /* SCORE LABEL */
        scoreLabel.name = "score"
        scoreLabel.fontName = "Nosifer"
        scoreLabel.fontColor = .yellow
        scoreLabel.fontSize = 35.0
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = Layer.ui.rawValue
        scoreLabel.position = CGPoint(x: frame.maxX - 50, y: viewTop() - 100)
        
        // Set the text and add the label node to scene
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        /* LEVEL LABEL */
        levelLabel.name = "level"
        levelLabel.fontName = "Nosifer"
        levelLabel.fontSize = 35.0
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .center
        levelLabel.zPosition = Layer.ui.rawValue
        levelLabel.position = CGPoint(x: frame.minX + 50, y: viewTop() - 100)
        
        // Set the text and add the label node to scene
        levelLabel.text = "Level: \(level)"
        addChild(levelLabel)
    }
    
    func showMessage(_ message: String) {
        // Set up message label
        let messageLabel = SKLabelNode()
        messageLabel.name = "message"
        messageLabel.position = CGPoint(x: frame.midX, y: player.frame.maxY + 100)
        messageLabel.zPosition = Layer.ui.rawValue
        
        messageLabel.numberOfLines = 2
        
        // Set up attributed text
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: SKColor(red: 251.0/255.0, green: 155.0/255.0, blue: 24.0/255.0, alpha: 1.0),
            .backgroundColor: UIColor.clear,
            .font: UIFont(name: "Nosifer", size: 45.0)!,
            .paragraphStyle: paragraph
        ]
        
        messageLabel.attributedText = NSAttributedString(string: message, attributes: attributes)
        
        // Run a fade action and add the lable to the scene
        messageLabel.run(SKAction.fadeIn(withDuration: 0.25))
        addChild(messageLabel)
    }
    
    func hideMessage() {
        // Remove message label if it exits
        if let messageLabel = childNode(withName: "//message") as? SKLabelNode {
            messageLabel.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.25),
                                                SKAction.removeFromParent()]))
        }
    }
    
    
    // MARK: - GAME FUNCTIONS
    /* ####################################################################### */
    /*                      GAME FUNCTIONS START HERE                          */
    /* ####################################################################### */
    
    func spawnMultipleGloops() {
        
        // Start player walk animation
        player.walk()
        
        // Reset the level and score
        if gameInProgress == false {
            score = 0
            level = 1
        }
        
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
        // Reset and update the collected and expected drop count
        dropsCollected = 0
        dropsExpected = numberOfDrops
        
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
        
        // Update game states
        gameInProgress = true
//        playingLevel = true
        
        // Hide message
        hideMessage()
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
    // verify the dropCollected equals the dropsExpected
    func checkForRemainingDrops() {
//        if playingLevel == true {
            if dropsCollected == dropsExpected {
//                playingLevel = false
                nextLevel()
            }
//        }
    }
    
    // Player PASSED level
    func nextLevel() {
        // Show message
        showMessage("Get Ready!")
        let wait = SKAction.wait(forDuration: 2.25)
        run(wait, completion: {[unowned self] in self.level += 1
            self.spawnMultipleGloops()
        })
    }
    
    
    // Player FAILED level
    func gameOver() {
        
        // Show message
        showMessage("Game Over\nTap to try again")
        
        // Update game states
        gameInProgress = false
        
        // Start player die animation
        player.die()
        
        // Remove repeatable action on main scene
        removeAction(forKey: "gloop")
        
        // Loop through child nodes and stop actions on collectibles
        enumerateChildNodes(withName: "//co_*") {
            ( node, stop) in
            
            // Stop and remove drops
            node.removeAction(forKey: "drop") // remove action
            node.physicsBody = nil // remove body so no collisions occur
        }
        
        // Reset game
        resetPlayerPosition()
        popRemainingDrops()
    }
    
    func resetPlayerPosition() {
        let resetPoint = CGPoint(x: frame.midX, y: player.position.y)
        let distance = hypot(resetPoint.x - player.position.x, 0)
        let calculatedSpeed = TimeInterval(distance / (playerSPeed * 2)) / 255
        if player.position.x > frame.midX {
            player.moveToPosition(pos: resetPoint, direction: "L", speed: calculatedSpeed)
        } else {
            player.moveToPosition(pos: resetPoint, direction: "R", speed: calculatedSpeed)
        }
    }
    func popRemainingDrops() {
        var i = 0;
        enumerateChildNodes(withName: "//co_*") {
            (node, stop) in
            
            // Pop remaining drops in sequence
            let initialWait = SKAction.wait(forDuration: 1.0)
            let wait = SKAction.wait(forDuration: TimeInterval(0.15 * CGFloat(i)))
            
            let removeFromParent = SKAction.removeFromParent()
            let actionSequence = SKAction.sequence([initialWait, wait, removeFromParent])
            
            node.run(actionSequence)
            i += 1
        }
    }
    // MARK: - TOUCH HANDLING
    /* ####################################################################### */
    /*                        TOUCH HANDLERS STARTS HERE                       */
    /* ####################################################################### */
    func touchDown(atPoint pos : CGPoint) {
        
        if gameInProgress == false {
            spawnMultipleGloops()
            return
        }
        
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
    
//    override func update(_ currentTime: TimeInterval) {
//        checkForRemainingDrops()
//    }
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
                dropsCollected += 1
                score += level
                // Verify the object is collectible
                checkForRemainingDrops()
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
                gameOver()
            }
            
        }
    }
}
