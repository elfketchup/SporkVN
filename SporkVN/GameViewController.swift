//
//  GameViewController.swift
//  SporkVN
//
//  Created by James on 12/27/21.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        // Load the SKScene from 'GameScene.sks'
        let scene = VNTestScene(size: view.frame.size)
        //let scene = SKScene(fileNamed: "GameScene")
        
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = SKSceneScaleMode.aspectFill
        
        // Present the scene
        view.presentScene(scene)
    
        
        view.ignoresSiblingOrder = true
        
        view.showsFPS = true
        view.showsNodeCount = true
        
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        /*if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }*/
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
