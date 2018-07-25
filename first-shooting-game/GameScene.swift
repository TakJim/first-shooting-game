//
//  GameScene.swift
//  first-shooting-game
//
//  Created by T. Jimbo on 2018/07/22.
//  Copyright © 2018年 TakJim. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameVC: GameViewController!
    
    let motionManager = CMMotionManager()
    var accelaration: CGFloat = 0.0
    
    var timer: Timer?
    var timerForAsteroid: Timer?
    var asteroidDuration: TimeInterval = 6.0 {
        didSet {
            if asteroidDuration < 2.0 {
                timerForAsteroid?.invalidate()
            }
        }
    }
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    let spaceshipCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let asteroidCategory: UInt32 = 0b0011
    let earthCategory: UInt32 = 0b1000
    
    var earth: SKSpriteNode!
    var spaceship: SKSpriteNode!
    var hearts: [SKSpriteNode] = []
    var scoreLabel: SKLabelNode!
 
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        self.earth = SKSpriteNode(imageNamed: "earth")
        self.earth.xScale = 1.5
        self.earth.yScale = 0.3
        self.earth.position = CGPoint(x: 0, y: -frame.height / 2)
        self.earth.zPosition = -1.0
        self.earth.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height:100))
        self.earth.physicsBody?.categoryBitMask = earthCategory
        self.earth.physicsBody?.contactTestBitMask = asteroidCategory
        self.earth.physicsBody?.collisionBitMask = 0
        addChild(self.earth)
        
        self.spaceship = SKSpriteNode(imageNamed: "spaceship")
        self.spaceship.scale(to: CGSize(width: frame.width / 5, height: frame.width / 5))
        self.spaceship.position = CGPoint(x: 0, y: self.earth.frame.maxY + 50)
        self.spaceship.physicsBody = SKPhysicsBody(circleOfRadius: self.spaceship.frame.width * 0.1)
        self.spaceship.physicsBody?.categoryBitMask = spaceshipCategory
        self.spaceship.physicsBody?.contactTestBitMask = asteroidCategory
        self.spaceship.physicsBody?.collisionBitMask = 0
        addChild(self.spaceship)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, _) in
            guard let data = data else { return } //guard は条件に一致しなかった場合、処理を中断させる
            let a = data.acceleration
            self.accelaration = CGFloat(a.x) * 0.75 + self.accelaration * 0.25
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in self.addAsteroid()} )
        
        for i in 1...5 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: -frame.width / 2 + heart.frame.height * CGFloat(i), y: frame.height / 2 - heart.frame.height)
            addChild(heart)
            hearts.append(heart)
        }
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "Papyrus"
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: -frame.width / 2 + scoreLabel.frame.width / 2 + 50, y: frame.height / 2 - scoreLabel.frame.height * 5)
        addChild(scoreLabel)
        
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        let bestScoreLabel = SKLabelNode(text: "Best Score: \(bestScore)")
        bestScoreLabel.fontName = "Papyrus"
        bestScoreLabel.fontSize = 30
        bestScoreLabel.position = scoreLabel.position.applying(CGAffineTransform(translationX: 0, y: -bestScoreLabel.frame.height * 1.5))
        addChild(bestScoreLabel)
        
        timerForAsteroid = Timer.scheduledTimer(withTimeInterval: 5.0 , repeats: true , block: {_ in self.asteroidDuration -= 0.5})
    }
    
    override func didSimulatePhysics() {
        let nextPosition = self.spaceship.position.x + self.accelaration * 50
        if nextPosition > frame.width / 2 - 30 { return }
        if nextPosition < -frame.width / 2 + 30 { return }
        self.spaceship.position.x = nextPosition
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { //タップが終わった時に行う処理
        if isPaused { return }
        let missile = SKSpriteNode(imageNamed: "missile") //宇宙船や地球と違って、スコープはこの関数内
        missile.position = CGPoint(x: self.spaceship.position.x, y: self.spaceship.position.y + 50)
        addChild(missile)
        missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.frame.height / 2)
        missile.physicsBody?.categoryBitMask = missileCategory
        missile.physicsBody?.contactTestBitMask = asteroidCategory
        missile.physicsBody?.collisionBitMask = 0
        
        let moveToTap = SKAction.moveTo(y: frame.height + 10, duration: 1) //durationは弾の速さ
        let remove = SKAction.removeFromParent()
        missile.run(SKAction.sequence([moveToTap, remove])) //runはSKSpriteNodeクラスのメソッドで、指定したSKActionを実行する。sequenceで順番にmoveしてremoveせよと命令。
    }
    
    func addAsteroid(){
        let names = ["asteroid1", "asteroid2", "asteroid3"]
        let index = Int(arc4random_uniform(UInt32(names.count)))
        let name = names[index]
        let asteroid = SKSpriteNode(imageNamed: name)
        let random = CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)
        let positionX = frame.width * (random - 0.5)
        asteroid.position = CGPoint(x: positionX, y: frame.height / 2 + asteroid.frame.height)
        asteroid.scale(to: CGSize(width: 70, height: 70))
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width)
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = missileCategory + spaceshipCategory + earthCategory
        asteroid.physicsBody?.collisionBitMask = 0
        addChild(asteroid)
        
        let move = SKAction.moveTo(y: -frame.height / 2 - asteroid.frame.height, duration: asteroidDuration)
        let remove = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([move, remove]))
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var asteroid: SKPhysicsBody
        var target: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask == asteroidCategory {
            asteroid = contact.bodyA
            target = contact.bodyB
        }else{
            asteroid = contact.bodyB
            target = contact.bodyA
        }
        guard let asteroidNode = asteroid.node else { return }
        guard let targetNode = target.node else { return }
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        explosion.position = asteroidNode.position
        addChild(explosion)
        
        asteroidNode.removeFromParent()
        if target.categoryBitMask == missileCategory {
            targetNode.removeFromParent()
            score += 5
        }
        
        self.run(SKAction.wait(forDuration: 1.0)) {
            explosion.removeFromParent()
        }
        
        if target.categoryBitMask == spaceshipCategory || target.categoryBitMask == earthCategory {
            guard let heart = hearts.last else { return }
            heart.removeFromParent()
            hearts.removeLast()
            if hearts.isEmpty {
                gameOver()
            }
        }
        
    }
    
    func gameOver() {
        isPaused = true
        timer?.invalidate()
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        if score > bestScore {
            UserDefaults.standard.set(score, forKey: "bestScore")
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.gameVC.dismiss(animated: true, completion: nil)
        }
    }
}
