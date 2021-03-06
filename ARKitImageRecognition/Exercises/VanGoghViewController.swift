//
//  VanGoghViewController.swift
//  ARKitImageRecognition
//
//  Created by Jonathan Scheiding on 4/22/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class VanGoghViewController : ViewController {
    var successNode: SCNNode? = nil
    var failureNodes: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:))))
    }
    
    override func getARReferenceImages() -> Set<ARReferenceImage>? {
        return ARReferenceImage.referenceImages(inGroupNamed: "Exercise - Van Gogh", bundle: nil)
    }
    
    override func respondToImage(node: SCNNode, imageAnchor: ARImageAnchor) {
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            let referenceSize = referenceImage.physicalSize
            let iconSize = referenceSize.width / 4
            let startPoint = CGPoint(
                x: (-referenceSize.width / 2) + (iconSize / 2),
                y: (referenceSize.height / 2) + (iconSize / 2))
            
            self.referenceNode = node
            self.referenceImage = referenceImage
            
            let tipSize = CGSize(width: referenceSize.width, height: referenceSize.width * 0.368)
            let tipPosition = SCNVector3Make(0, 0, -Float(referenceSize.height + tipSize.height) * 1.1 / 2.0)
            self.addImage(name: "bodypart", size: tipSize, position: tipPosition, node: node)
            
            ["hand", "nose", "ear", "foot"]
                .enumerated()
                .forEach { (index, name) in
                    let size = CGSize(width: iconSize * 0.8, height: iconSize * 0.8)
                    let position = SCNVector3(
                        x: Float(startPoint.x - (iconSize * CGFloat(0.1)) + (iconSize * CGFloat(index))),
                        y: 0,
                        z: Float(startPoint.y + (iconSize * CGFloat(0.1))))
                    
                    let planeNode = self.addImage(name: name, size: size, position: position, node: node)
                    planeNode.opacity = 0.6
                        
                    if(name == "ear") {
                        self.successNode = planeNode
                    } else {
                        self.failureNodes.append(planeNode)
                    }
            }
        }
    }
    
    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let results = self.sceneView.hitTest(gesture.location(in: gesture.view), types: ARHitTestResult.ResultType.featurePoint)
        guard let result: ARHitTestResult = results.first else {
            return
        }
        
        let hits = self.sceneView.hitTest(gesture.location(in: gesture.view), options: nil)
        if let tappedNode = hits.first?.node {
            if(tappedNode == self.successNode) {
                self.resetTracking()
                performSegue(withIdentifier: "showVanGogh", sender: self)
            } else {
                self.failureNodes.forEach { node in
                    if (node == tappedNode) {
                        self.highlightImage(color: UIColor.red)
                    }
                }
            }
        }
    }
    
    func highlightImage(color: UIColor) {
        guard let referenceImage = self.referenceImage else { return }
        guard let referenceNode = self.referenceNode else { return }
        
        let highlight = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
        let highlightNode = SCNNode(geometry: highlight)
        highlightNode.opacity = 0
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        highlight.materials = [material]
        
        highlightNode.eulerAngles.x = -.pi / 2
        referenceNode.addChildNode(highlightNode)
        highlightNode.runAction(self.imageHighlightAction)
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.45, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }

}
