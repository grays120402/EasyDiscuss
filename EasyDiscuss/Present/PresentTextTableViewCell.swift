//
//  PresentTextTableViewCell.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/15.
//

import UIKit

class PresentTextTableViewCell: UITableViewCell {

    @IBOutlet weak var addDateLabel: UILabel!
    @IBOutlet weak var AuthorLabel: UILabel!
    @IBOutlet weak var presentTitleLabel: UILabel!
    @IBOutlet weak var presentTextLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
