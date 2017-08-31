//
//  RunTableCell.swift
//  InfinityTracker
//
//  Created by Alex on 31/08/2017.
//  Copyright © 2017 AleksZilla. All rights reserved.
//

import UIKit

class RunTableCell: UITableViewCell {

    // MARK: IBOutlets
    
    @IBOutlet weak var timestampLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!

    // MARK: LifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
