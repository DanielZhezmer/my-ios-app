import Foundation
import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: MKMapView!
    var distance: Double = 5.0  // Значение по умолчанию
    var hasCenteredMap = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Устанавливаем фон
        view.backgroundColor = .white

        // Настраиваем карту
        mapView = MKMapView(frame: self.view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)

        // Настраиваем менеджер местоположения
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Добавляем кнопку
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .blue
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 25
        locationButton.layer.shadowColor = UIColor.black.cgColor
        locationButton.layer.shadowOpacity = 0.3
        locationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        locationButton.layer.shadowRadius = 2
        locationButton.addTarget(self, action: #selector(centerMapOnUserLocation), for: .touchUpInside)
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)

        // Устанавливаем ограничения для кнопки
        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        } else {
            print("Данные о направлении недоступны на этом устройстве.")
        }
        
        // Запрашиваем маршрут с использованием переданного расстояния
        fetchRoute(distance: distance)
    }

    @objc func centerMapOnUserLocation() {
        guard let location = currentLocation else {
            // Местоположение еще не определено
            return
        }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Местоположение обновлено: \(location.coordinate)")
            currentLocation = location

            // Центрируем карту только один раз при первом обновлении местоположения
            if !hasCenteredMap {
                let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                mapView.setRegion(region, animated: true)
                hasCenteredMap = true  // Устанавливаем флаг, чтобы повторно не центрировать карту
            }
        }
    }

    func fetchRoute(distance: Double) {
        guard let url = URL(string: "http://192.168.1.182:8080/routes/heart?distance=\(distance)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("Данные не получены")
                return
            }

            do {
                let decoder = JSONDecoder()
                let geoRouteResponse = try decoder.decode(GeoRouteResponse.self, from: data)

                if geoRouteResponse.status == "success", let route = geoRouteResponse.route {
                    let coordinates = route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

                    DispatchQueue.main.async {
                        self.displayRouteOnMap(coordinates: coordinates)
                    }
                } else {
                    print("Не удалось построить маршрут")
                }
            } catch {
                print("Ошибка декодирования данных: \(error.localizedDescription)")
            }
        }.resume()
    }

    func displayRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)

        if let firstCoordinate = coordinates.first {
            let region = MKCoordinateRegion(center: firstCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
}

// Расширение для делегата карты
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let identifier = "UserLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.image = UIImage(named: "userArrow") // Ваше кастомное изображение стрелки
            annotationView?.bounds = CGRect(x: 0, y: 0, width: 40, height: 40) // Устанавливаем размер аннотации
            annotationView?.centerOffset = CGPoint(x: 0, y: 0) // Центрируем аннотацию

            return annotationView
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
