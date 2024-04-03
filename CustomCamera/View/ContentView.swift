//
//  ContentView.swift
//  CustomCamera
//
//  Created by window1 on 3/29/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var cameraModel = CameraModel()
    @StateObject var cameraService = CameraService()
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black)
                            .clipShape(Circle())
                    })
                }
                Spacer()
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                        Circle()
                            .stroke(Color.white, lineWidth:5)
                            .frame(width: 75, height: 75)
                        
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
