

import SwiftUI

struct LensChangeView: View {
    
    var body: some View {
        ZStack {
            Capsule()
                .frame(width: 210, height: 60)
                .foregroundStyle(.gray.opacity(0.2))
        }
    }
}

#Preview {
    LensChangeView()
}

extension LensChangeView {
    
    var ultraWideAngleLens: some View {
        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
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
        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
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
        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
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



