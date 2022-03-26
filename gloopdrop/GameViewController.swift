//
//  GameViewController.swift
//  gloopdrop
//
//  Created by Aaron on 2022/3/19.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // create the view
        // 使用强制类型转换运算符（as！）的强制形式将视图向下转换为 SKView。
        if let view = self.view as! SKView? {
            
            // Create the scene
//            let scene = GameScene(size: view.bounds.size)
            let scene = GameScene(size: CGSize(width: 1336, height: 1024))
            
            // set the scale mode to scale to fill the view window
            scene.scaleMode = .aspectFill
            
            // set the background color
            scene.backgroundColor = UIColor(red: 105/255, green: 157/255, blue: 181/255, alpha: 1.0)
            
            // present the scene
            view.presentScene(scene)
            
            // set the view options
            view.ignoresSiblingOrder = false // control the rendering order of the nodes.
            view.showsPhysics = false //  show or hide the physics bodies attached to your nodes.
            view.showsFPS = false //  show or hide the frames per second (FPS) indicator.
            view.showsNodeCount = false //  used to show or hide the number of nodes.
        }
        
       
    }

    override var shouldAutorotate: Bool {
        return true
    }

//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            return .allButUpsideDown
//        } else {
//            return .all
//        }
//    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
