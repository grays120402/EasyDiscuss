//
//  ContentTableViewCell.swift
//  EasyDiscuss
//
//  Created by 陳懿宏 on 2020/12/15.
//

import UIKit

class ContentTableViewCell: UITableViewCell {

    @IBOutlet weak var moreOutlet: UIButton!
    @IBOutlet weak var classificationLabelOutlet: UILabel!
    @IBOutlet weak var titleLabelOutlet: UILabel!
    @IBOutlet weak var dateLabelOutlet: UILabel!
    @IBOutlet weak var authorLabelOutlet: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
