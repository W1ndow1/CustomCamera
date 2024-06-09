

import SwiftUI

struct WaterMarkView: View {
    @ObservedObject var model: CameraViewModel
    var body: some View {
        ZStack {
            Capsule()
                .overlay {
                    TextField("Name",text: $model.waterMarkText)
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                .frame(width: 100, height: 50, alignment: .center)
                .foregroundStyle(.black.opacity(0.6))
        }
        
    }
}

#Preview {
    WaterMarkView(model: .init())
}
