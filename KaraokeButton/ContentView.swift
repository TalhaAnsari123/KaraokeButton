import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()
                Text("PRESS DESU").foregroundColor(.white).font(.system(size: 50, weight: .bold, design: .default)).padding(.bottom, 100)
                Button(action: {
                    if audioEngine.isRunning {
                        audioEngine.stop()
                    } else {
                        audioEngine.start()
                    }
                }) {
                    Image(audioEngine.isRunning ? "Sing" : "Mute")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                }
                .padding(.bottom, 40)

                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
