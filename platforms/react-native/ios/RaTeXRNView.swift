// RaTeXRNView.swift — ObjC-bridgeable wrapper around RaTeXView for React Native.

import UIKit

/// ObjC-compatible UIView wrapper around `RaTeXView` used as the React Native native view.
///
/// Exposes `@objc` properties so React Native can set them via KVC (old arch) or direct
/// property access from ObjC++ (new arch / Fabric).
@objc(RaTeXRNView)
@MainActor
public class RaTeXRNView: UIView {

    private let innerView = RaTeXView()

    // MARK: - ObjC-bridgeable properties

    @objc public var latex: String {
        get { innerView.latex }
        set { innerView.latex = newValue }
    }

    @objc public var fontSize: CGFloat {
        get { innerView.fontSize }
        set { innerView.fontSize = newValue }
    }

    /// Old-arch event block set by React Native via KVC.
    /// When called, passes `{ "error": "<message>" }` as the body.
    @objc public var onError: ((NSDictionary?) -> Void)? {
        didSet {
            if let block = onError {
                innerView.onError = { error in
                    block(["error": error.localizedDescription])
                }
            } else {
                innerView.onError = nil
            }
        }
    }

    /// New-arch (Fabric) helper: lets ObjC++ install an error handler without
    /// needing to bridge the Swift `Error` type.
    @objc public func setErrorCallback(_ handler: @escaping (String) -> Void) {
        innerView.onError = { error in handler(error.localizedDescription) }
    }

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        innerView.intrinsicContentSize
    }

    // MARK: - Private

    /// The bundle containing KaTeX fonts bundled via CocoaPods resource_bundles.
    private static let fontsBundle: Bundle = {
        let module = Bundle(for: RaTeXRNView.self)
        if let url = module.url(forResource: "RaTeXFonts", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return module
    }()

    private static var fontsLoaded = false

    private func setup() {
        backgroundColor = .clear
        addSubview(innerView)
        innerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            innerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            innerView.topAnchor.constraint(equalTo: topAnchor),
            innerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        // Load fonts from the CocoaPods resource bundle (not the main bundle or SPM bundle).
        // Guard ensures we only do this once across all RaTeXRNView instances.
        if !RaTeXRNView.fontsLoaded {
            RaTeXFontLoader.loadFromBundle(RaTeXRNView.fontsBundle)
            RaTeXRNView.fontsLoaded = true
        }
    }
}
