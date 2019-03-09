//
//  MultiProgressView.swift
//  MultiProgressView
//
//  Created by Mac Gallagher on 6/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

public protocol MultiProgressViewDataSource {
    func numberOfSections(in progressView: MultiProgressView) -> Int
    func progressView(_ progressView: MultiProgressView, viewForSection section: Int) -> ProgressViewSection
}

open class MultiProgressView: UIView {
    public var dataSource: MultiProgressViewDataSource? {
        didSet {
            reloadData()
        }
    }
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    public var borderColor: UIColor? = .black {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    public var trackInset: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackBackgroundColor: UIColor? = .white {
        didSet {
            track.backgroundColor = trackBackgroundColor
        }
    }
    
    public var trackBorderColor: UIColor? = .black {
        didSet {
            track.layer.borderColor = trackBorderColor?.cgColor
        }
    }
    
    public var trackBorderWidth: CGFloat = 0 {
        didSet {
            track.layer.borderWidth = trackBorderWidth
        }
    }
    
    public var trackTitleLabel: UILabel {
        return label
    }
    
    private var label: UILabel = UILabel()
    
    public var trackTitleEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackTitleAlignment: AlignmentType = .center {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackImageView: UIImageView {
        return imageView
    }
    
    private var imageView: UIImageView = UIImageView()
    
    public var lineCap: LineCapType = .square {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var totalProgress: Float {
        return currentProgress.reduce(0) { $0 + $1 }
    }
    
    lazy var track: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.addSubview(trackTitleLabel)
        view.addSubview(trackImageView)
        return view
    }()
    
    var progressViewSections: [ProgressViewSection] = []
    
    private var numberOfSections: Int = 0
    private var currentProgress: [Float] = []
    
    private var layoutCalculator: LayoutCalculatable = LayoutCalculator.shared
    
    //MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    convenience init(layoutCalculator: LayoutCalculatable) {
        self.init(frame: .zero)
        self.layoutCalculator = layoutCalculator
    }
    
    private func initialize() {
        backgroundColor = .white
        layer.masksToBounds = true
        addSubview(track)
    }
    
    //MARK: - Layout
    
    private var labelConstraints = [NSLayoutConstraint]() {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(labelConstraints)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        track.frame = layoutCalculator.trackFrame(forProgressView: self)
        labelConstraints = trackTitleLabel.layout(withAlignment: trackTitleAlignment,
                                                   insets: trackTitleEdgeInsets)
        imageView.frame = layoutCalculator.trackImageViewFrame(forProgressView: self)
        track.sendSubviewToBack(imageView)
        layoutSections()
        applyCornerRadius()
    }
    
    private func layoutSections() {
        for (index, section) in progressViewSections.enumerated() {
            section.frame = layoutCalculator.sectionFrame(forProgressView: self,
                                                          section: index)
            track.bringSubviewToFront(section)
        }
    }
    
    private func applyCornerRadius() {
        layer.cornerRadius = layoutCalculator.cornerRadius(forProgressView: self)
        track.layer.cornerRadius = layoutCalculator.trackCornerRadius(forProgressView: self)
    }
    
    //MARK: - Data Source
    
    public func reloadData() {
        guard let dataSource = dataSource else { return }
        numberOfSections = dataSource.numberOfSections(in: self)
        
        progressViewSections.forEach { $0.removeFromSuperview() }
        progressViewSections.removeAll()
        currentProgress.removeAll()
        
        for index in 0..<numberOfSections {
            configureSection(index)
        }
    }
    
    private func configureSection(_ section: Int) {
        guard let dataSource = dataSource else { return }
        let bar = dataSource.progressView(self, viewForSection: section)
        progressViewSections.insert(bar, at: section)
        track.addSubview(bar)
        currentProgress.insert(0, at: section)
    }
    
    //MARK: - Main Methods
    
    public func setTitle(_ title: String?) {
        label.text = title
    }
    
    public func setAttributedTitle(_ title: NSAttributedString?) {
        label.attributedText = title
    }
    
    public func setTrackImage(_ image: UIImage?) {
        imageView.image = image
    }
    
    public func progress(forSection section: Int) -> Float {
        return currentProgress[section]
    }
    
    public func setProgress(section: Int, to progress: Float) {
        currentProgress[section] = max(0, min(progress, 1 - totalProgress + currentProgress[section]))
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func resetProgress() {
        for section in 0..<progressViewSections.count {
            setProgress(section: section, to: 0)
        }
    }
}
