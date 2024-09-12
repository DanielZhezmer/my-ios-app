import SwiftUI

struct DistanceInputView: View {
    @State private var distanceText: String = ""
    @State private var navigateToMap: Bool = false
    @State private var distance: Double = 0.0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Фоновое изображение
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                // Затемняющий слой
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    TextField("Введите расстояние в км", text: $distanceText)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        if let distanceValue = Double(distanceText), distanceValue > 0 {
                            self.distance = distanceValue
                            self.navigateToMap = true
                        } else {
                            self.alertMessage = "Пожалуйста, введите положительное число."
                            self.showAlert = true
                        }
                    }) {
                        Text("Построить маршрут")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToMap) {
                MapView(distance: distance)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}
