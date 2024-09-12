import SwiftUI
import UIKit

struct MapView: UIViewControllerRepresentable {
    let distance: Double

    func makeUIViewController(context: Context) -> ViewController {
        let viewController = ViewController()
        viewController.distance = distance
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Здесь можно обновлять UIViewController при необходимости
    }
}
