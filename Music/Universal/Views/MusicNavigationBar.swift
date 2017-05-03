//
//  MusicNavigationBar.swift
//  Music
//
//  Created by Jack on 4/30/17.
//  Copyright © 2017 Jack. All rights reserved.
//

import UIKit

protocol MusicNavigationBarDelegate: class {
    func backButtonClicked(_ sender: UIButton)
}

/// Custom music navigation bar
class MusicNavigationBar: UIView {
    
    var delegate: MusicNavigationBarDelegate?
    
    var backButton: UIButton {
        didSet {
            resetBack(oldValue)
        }
    }
    let titleLabel: UILabel
    var actionButton: UIButton {
        didSet {
            resetAction(oldValue)
        }
    }
    var separator: UIView
    
    override init(frame: CGRect) {
        
        backButton = UIButton(type: .custom)
        titleLabel = UILabel()
        actionButton = UIButton(type: .custom)
        separator = UIView()
        
        super.init(frame: frame)
        
        backButton.setImage(#imageLiteral(resourceName: "topBar_back"), for: .normal)
        backButton.setImage(#imageLiteral(resourceName: "topBar_back_press"), for: .highlighted)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        
        titleLabel.textColor = .white
        titleLabel.font = .font20
        separator.backgroundColor = .lightGray
        
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        resetBack()
        resetAction()
        resetSeparator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resetBack(_ oldValue: UIButton? = nil)  {
        oldValue?.removeFromSuperview()
        addSubview(backButton)
        
        backButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
    }
    
    private func resetAction(_ oldValue: UIButton? = nil) {
        
        oldValue?.removeFromSuperview()
        addSubview(actionButton)
        
        actionButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalToSuperview()
        }
    }
    
    private func resetSeparator(_ oldValue: UIButton? = nil) {
        
        oldValue?.removeFromSuperview()
        addSubview(separator)
        
        separator.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    @objc private func backButtonClicked() {
        delegate?.backButtonClicked(backButton)
    }
}
