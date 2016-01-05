//
//  tableViewCell.swift
//  MobileBackendIOS
//
//  Created by Huang, Greg on 11/11/15.
//  Copyright © 2015 Amazon Web Services. All rights reserved.
//

import UIKit

class tableViewCell: UITableViewCell {

    
    @IBOutlet weak var imageViewSmall: UIImageView!
   
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
}
