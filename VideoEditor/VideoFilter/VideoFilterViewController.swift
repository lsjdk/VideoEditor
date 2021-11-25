//
//  VideoFilterViewController.swift
//  VideoEditor
//
//  Created by 李世举 on 2021/11/25.
//

import UIKit
import AVFoundation

class VideoFilterViewController: UIViewController {
    
//    private var playerLayer: AVPlayerLayer

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        self.view.layer.addSublayer(playerLayer)
        // Do any additional setup after loading the view.
    }

}
