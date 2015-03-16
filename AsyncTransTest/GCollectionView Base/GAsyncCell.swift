//
//  GAsyncCell.swift
//  GPaperTrans
//
//  Created by 大坪五郎 on 2014/12/24.
//  Copyright (c) 2014年 demodev. All rights reserved.
//

import UIKit

class GAsyncCell: ASCellNode {
    
    let imageNode:ASNetworkImageNode
    
    required override init(){
        self.imageNode = ASNetworkImageNode(cache: nil, downloader: ASBasicImageDownloader())
        super.init()
        self.addSubnode(imageNode)
        let nc = NSNotificationCenter.defaultCenter()
        // 登録
        nc.addObserver(self, selector: "handleSizeNotification:", name: "SizeNotification", object: nil)
        self.backgroundColor = UIColor.purpleColor()
        
    }
    
    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {
        
        let itemSize = GAsyncColViewController.instance.getItemSize()
        
        let width:CGFloat = itemSize.width
        let height:CGFloat = itemSize.height
        
        self.imageNode.frame = CGRectMake(0,0,width,height)
        return CGSizeMake(width,height)
    }
    
    override func layout() {
        var cframe = self.frame
        self.frame = CGRectMake(cframe.origin.x, cframe.origin.y, calculatedSize.width,calculatedSize.height)
    }
    
    func setIndex(indexData:Int){
        let url = NSURL(string:"http://placekitten.com/g/\(indexData+200)/\(indexData+200)")
        self.imageNode.URL = url
    }
    
    func handleSizeNotification(notification:NSNotification){
        let constSize = GAsyncColViewController.instance.getItemSize()
        self.measure(constSize)
    }
}
