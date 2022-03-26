//
//  GameScene.swift
//  gloopdrop
//
//  Created by Aaron on 2022/3/19.
//

import SpriteKit
import GameplayKit
import AVFoundation

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
    var prevDropLocation: CGFloat = 0.0
    
    // Labels
    var scoreLabel: SKLabelNode = SKLabelNode()
    var levelLabel: SKLabelNode = SKLabelNode()
    
    // Audio nodes
    let musicAudioNode = SKAudioNode(fileNamed: "music.mp3")
    let bubbleAudioNode = SKAudioNode(fileNamed: "bubbles.mp3")
    
    // Game states
    var gameInProgress = false
//    var playingLevel = false
    
    override func didMove(to view: SKView) {
        
        // Decrease the audio engine's volume
        audioEngine.mainMixerNode.outputVolume = 0.0
        // Set up the background music audio node
        musicAudioNode.autoplayLooped = true
        musicAudioNode.isPositional = false // is used to alter the audio based on the listener node.
        
        // Add the audio node to the scene
        addChild(musicAudioNode)
        
        // Use an action to adjust the audio node's volume to 0
        musicAudioNode.run(SKAction.changeVolume(to: 0.0, duration: 0.0))
        
        // Run a delayed action on the scene that fades in the music
        run(SKAction.wait(forDuration: 1.0)) { [unowned self] in
            self.audioEngine.mainMixerNode.outputVolume = 1.0
            self.musicAudioNode.run(SKAction.changeVolume(to: 0.75, duration: 2.0))
        }
        
        // Run a delayed action to add bubble audio to the scene
        run(SKAction.wait(forDuration: 1.5),completion: { [unowned self] in
            self.bubbleAudioNode.autoplayLooped = true
            self.addChild(self.bubbleAudioNode)
        })
        
        // Set up the physics world contact delegate
        physicsWorld.contactDelegate = self
        
        // Set up background
        let background = SKSpriteNode(imageNamed: "background_1")
        background.name = "background"
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = Layer.background.rawValue
        addChild(background)
        
        // Set up foreground
        let foreground = SKSpriteNode(imageNamed: "foreground_1")
        foreground.name = "foreground"
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
        
        // Set up the banner
        let banner = SKSpriteNode(imageNamed: "banner")
        banner.zPosition = Layer.background.rawValue + 1
        banner.position = CGPoint(x: frame.midX, y: viewTop() - 20)
        banner.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        addChild(banner)
        
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
        setupGloopFlow()
        
        // Challenge: Set up star particles
        if let stars = SKEmitterNode(fileNamed: "Stars.sks") {
            stars.name = "stars"
            stars.position = CGPoint(x: frame.midX, y: frame.midY)
            addChild(stars)
        }
        
        // Challenge: Create an action to run after a short random delay
        let wait = SKAction.wait(forDuration: 30, withRange: 60)
        let codeBlock = SKAction.run({self.sendRobot()})
        run(SKAction.sequence([wait, codeBlock]))
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
    // MARK: - Challenge
    func sendRobot() {
        
        // Set up robot sprite node
        let robot = SKSpriteNode(imageNamed: "robot")
        robot.zPosition = Layer.foreground.rawValue
        robot.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        robot.position = CGPoint(x: frame.maxX + robot.size.width, y: frame.midY + robot.size.height)
        addChild(robot)
        
        // Set up audio node and make it a child of the robot sprite node
        let audioNode = SKAudioNode(fileNamed: "robot.wav")
        audioNode.autoplayLooped = true
        audioNode.run(SKAction.changeVolume(to: 1.0, duration: 0.0))
        robot.addChild(audioNode)
        
        // Create and run a sequence of action that moves the robot up and down
        let moveUp = SKAction.moveBy(x: 0, y: 15, duration: 0.25)
        let moveDown = SKAction.moveBy(x: 0, y: -15, duration: 0.25)
        let wobbleGroup = SKAction.sequence([moveDown, moveUp])
        let wobbleAction = SKAction.repeatForever(wobbleGroup)
        robot.run(wobbleAction)  // you can not run a completion handler on
        // on an action that runs forever, so you need
        // to run this action on its own.
        // Create an action that moves the robot left
        
        let moveLeft = SKAction.moveTo(x: frame.minX - robot.size.width,
                                       duration: 6.50)
        
        // Create an action to remove the robot sprite node
        let removeFromParent = SKAction.removeFromParent()
        
        // Combine the actions into a sequence
        let moveSequence = SKAction.sequence([moveLeft, removeFromParent])
        
        // Periodically run this method using a timed range
        robot.run(moveSequence, completion: {
            let wait = SKAction.wait(forDuration: 30, withRange: 60)
            let codeBlock = SKAction.run({self.sendRobot()})
            self.run(SKAction.sequence([wait, codeBlock]))
        })
    }
    // MARK: - Gloop Flow & Particle Effects
    func setupGloopFlow() {
        
        // Set up flowing gloop
        let gloopFlow = SKNode()
        gloopFlow.name = "gloopFlow"
        gloopFlow.zPosition = Layer.foreground.rawValue
        gloopFlow.position = CGPoint(x: 0.0, y: -60)
        
        // Use extension for endless scrolling
        gloopFlow.setupScrollingView(imageNamed: "flow_1", layer: Layer.foreground, emitterNamed: "GloopFlow.sks", blocks: 3, speed: 30.0)
        
        // Add flow to scene
        addChild(gloopFlow)
    }
    
    // MARK: - GAME FUNCTIONS
    /* ####################################################################### */
    /*                      GAME FUNCTIONS START HERE                          */
    /* ####################################################################### */
    
    func spawnMultipleGloops() {
        
        player.mumble()
        
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
        var randomX = CGFloat.random(in: dropRange.lowerLimit...dropRange.upperLimit)
        
        /* START ENHANCED DROP MOVEMENT
         this helps to create a " snake-like" patthern */
        
        // Set a range
        let randomModifier = SKRange(lowerLimit: 50 + CGFloat(level), upperLimit: 60 * CGFloat(level))
        var modifier = CGFloat.random(in: randomModifier.lowerLimit...randomModifier.upperLimit)
        if modifier > 400 { modifier = 400 }
        
        // Set the previous drop location
        if prevDropLocation == 0.0 {
            prevDropLocation = randomX
        }
        
        // Clamp its x-position
        if prevDropLocation < randomX {
            randomX = prevDropLocation + modifier
        } else {
            randomX = prevDropLocation - modifier
        }
        
        // Make sure the collectible stays within the frame
        if randomX <= (frame.minX + margin) {
            randomX = frame.minX + margin
        } else if randomX >= (frame.maxX - margin) {
            randomX = frame.maxX - margin
        }
        
        // Store the location
        prevDropLocation = randomX
        
        /* END ENHANCED DROP MOVEMENT */
        
        // Add the number tag to the tag to the collectible drop
        let xLabel = SKLabelNode()
        xLabel.name = "dropNumber"
        xLabel.fontName = "AvenirNext-DemiBold"
        xLabel.fontColor = UIColor.yellow
        xLabel.fontSize = 22.0
        xLabel.text = "\(numberOfDrops)"
        xLabel.position = CGPoint(x: 0, y: 2)
        collectible.addChild(xLabel)
        numberOfDrops -= 1 // decrease drop count by 1
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
        let touchedNodes = nodes(at: pos)
        for touchedNode in touchedNodes {
            print("touchedNode: \(String(describing: touchedNode.name))")
            if touchedNode.name == "player" || touchedNode.name == "controller" {
                movingPlayer = true
            }
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
                
                // Add the 'chomp' text at the player's position
                let chomp = SKLabelNode(fontNamed: "Nosifer")
                chomp.name = "chomp"
                chomp.alpha = 0.0
                chomp.fontSize = 22.0
                chomp.text = "gloop"
                chomp.horizontalAlignmentMode = .center
                chomp.verticalAlignmentMode = .bottom
                chomp.position = CGPoint(x: player.position.x, y: player.frame.maxY + 25)
                chomp.zRotation = CGFloat.random(in: -0.15...0.15)
                addChild(chomp)
                
                // Add actions to fade in, rise up, and fade out
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
                let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.45)
                let moveUp = SKAction.moveBy(x: 0.0, y: 45, duration: 0.45)
                let groupAction = SKAction.group([fadeOut, moveUp])
                let removeFromParent = SKAction.removeFromParent()
                let chompAction = SKAction.sequence([fadeIn, groupAction, removeFromParent])
                chomp.run(chompAction)
                
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
