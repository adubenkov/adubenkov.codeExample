//
//  PHVisualisationViewController.swift
//  
//
//  Created by Andrey Dubenkov on 09/05/2018.
//  Copyright © 2018 . All rights reserved.
//
import UIKit
import AudioKit
import AudioKitUI
import DeviceKit

protocol ProjectHubVisualisationViewInput: class {
    func blockScrolling(foo: Bool)
    func addMusicPlot(duration: Double, data: EZAudioFloatData)
    func playhead(contentOffset: Double)
    func clearMusicPlot()
}

protocol ProjectHubVisualisationViewOutput {
    var input: ProjectHubVisualisationViewInput? { get set }
    func scrollViewWillBeginDragging()
    func scrollViewWillEndDragging()
    func scrollViewDidScrollToOffset(position: Double)
    func scrollViewDidEndDraggingAt(position: Double)
    func scrollViewDidEndDecelerating(position: Double)
}

class ProjectHubVisualisationViewController: BaseViewController {
    @IBOutlet private var playhead: UIView!

    @IBOutlet private var musicScrollView: UIScrollView!
    @IBOutlet private var musicPlotView: UIView!
    @IBOutlet private var musicPlotWidthConstraint: NSLayoutConstraint!

    // MARK: - Properties

    var output: ProjectHubVisualisationViewOutput?

    var plotScale = 16.0
    let plotGain = Float(1.7)

    var musicPlot: EZAudioPlot?

    var center: Double {
        return Double(self.view.frame.width / 2.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - GUI funcs

    private func configView() {
        if #available(iOS 11.0, *) {
            musicScrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
        musicScrollView.bounces = false
        musicScrollView.delegate = self
        musicScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.0)
    }

    private func playheadFromUiPosition() -> Double {
        let visibleRect = CGRect(origin: musicScrollView.contentOffset, size: musicScrollView.frame.size)
        let startPoint = Double(visibleRect.origin.x) / plotScale
        return startPoint
    }
}

// MARK: - Scroll View Delegate

extension ProjectHubVisualisationViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        output?.scrollViewDidScrollToOffset(position: playheadFromUiPosition())
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        output?.scrollViewWillBeginDragging()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        output?.scrollViewWillEndDragging()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        output?.scrollViewDidEndDraggingAt(position: playheadFromUiPosition())
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        output?.scrollViewDidEndDecelerating(position: playheadFromUiPosition())
    }
}

// MARK: - ProjectHubVisualisationViewInput

extension ProjectHubVisualisationViewController: ProjectHubVisualisationViewInput {
    func blockScrolling(foo: Bool) {
        musicScrollView.isUserInteractionEnabled = !foo
    }

    func addMusicPlot(duration: Double, data: EZAudioFloatData) {
        clearMusicPlot()
        let width = duration * plotScale
        let height = musicPlotView.bounds.height
        musicPlotWidthConstraint.constant = CGFloat(width + center * 2)
        let rect = CGRect(x: center, y: 0, width: width, height: Double(height))
        let plot = EZAudioPlot(frame: rect)
        DispatchQueue.global().async {
            plot.updateBuffer(data.buffers[0], withBufferSize: data.bufferSize)
            plot.gain = self.plotGain
            plot.plotType = .rolling
            plot.shouldFill = true
            plot.shouldCenterYAxis = true
            plot.shouldMirror = true
            plot.color = UIColor(hexString: "#1e6c7f")
            plot.backgroundColor = .clear

            self.musicPlot = plot
            DispatchQueue.main.async {
                self.musicPlotView.addSubview(plot)
            }
        }
    }

    func clearMusicPlot() {
        if let view = musicPlot {
            view.removeFromSuperview()
            musicPlot = nil
            self.view.layoutIfNeeded()
        }
    }

    func playhead(contentOffset: Double) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
                let offset = CGFloat(contentOffset * self.plotScale)
                self.musicScrollView.contentOffset.x = offset
            }, completion: { (_: Bool) in
            })
        }
    }
}
