

import SwiftUI

struct LensChangeView: View {
    @ObservedObject var model: CameraViewModel
    var body: some View {
        ZStack {
            Capsule()
                .frame(width: 210, height: 60)
                .foregroundStyle(.gray.opacity(0.2))
        }
    }
}

#Preview {
    LensChangeView(model: .init())
}

extension LensChangeView {
    var ultraWideAngleLens: some View {
        Button(action:{
            model.switchToLens(position: .builtInUltraWideCamera)
        }, label: {
            Circle()
                .frame(width: 50)
                .foregroundStyle(.black.opacity(0.5))
                .overlay {
                    Text("0.5x")
                        .foregroundStyle(.white)
                }
        })
    }
    
    var wideLens: some View {
        Button(action: {
            model.switchToLens(position: .builtInWideAngleCamera)
        }, label: {
            Circle()
                .frame(width: 50)
                .foregroundStyle(.black.opacity(0.5))
                .overlay {
                    Text("1.0x")
                        .foregroundStyle(.white)
                }
        })
    }
    
    var telescopeLens: some View {
        Button(action: {
            model.switchToLens(position: .builtInTelephotoCamera)
        }, label: {
            Circle()
                .frame(width: 50)
                .foregroundStyle(.black.opacity(0.5))
                .overlay {
                    Text("2.0x")
                        .foregroundStyle(.white)
                }
        })
    }
}



