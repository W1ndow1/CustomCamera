import SwiftUI
import Foundation

struct WaterMarkView: View {
    @ObservedObject var model: CameraViewModel
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Text("\(currentTimeToString(fomat: "yy-MM-dd (EEE)"))")
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .italic()
                
            }
            ZStack {
                
                Capsule()
                    .frame(width: 200, height: 50, alignment: .center)
                    .foregroundStyle(.blue.opacity(0.8))
                Text("\(currentTimeToString)")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 25, weight: .bold, design: .serif))
            }
            
        }
    }
    
    var currentTimeToString: String {
        let now = Date()
        let fomatter = DateFormatter()
        fomatter.dateFormat = "a HH:mm"
        return fomatter.string(from: now)
    }
    
    func currentTimeToString(fomat: String) -> String {
        let now = Date()
        let fomatter = DateFormatter()
        fomatter.locale = Locale.current
        fomatter.dateFormat = fomat
        return fomatter.string(from: now)
    }
}

#Preview {
    WaterMarkView(model: .init())
}
