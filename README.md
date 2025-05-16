# CustomCamera

커스텀 카메라 애플리케이션

## Features
- 사진촬영, 보관함 탐색
- 카메라 렌즈 전환(배율변경 및 전면카메라)
- 줌인 기능
- 카메라 셔터 소리 on, off
- Live photo on, off
- 워터마크 및 문구 넣기
- 촬영시 라이트 on, off

## Requirements
- iOS 17.0 or later

## Technologies Used 
- SwiftUI
- AVFoundation


## Screenshot

<style>
    .section1 {
        display: flex;
        gap: 150px;               /* 이미지 사이 간격 */
        align-items: flex-start;  /* 세로 정렬 */
        margin-bottom: 40px
}
    .section2 {
        display: flex;
        gap: 10px;
        align-items: flex-start;
        margin-bottom: 40px 
    }
    .rotate-90 {
        transform: rotate(90deg);
    }
</style>

1. App UI
<div class="section1">
  <img src="CustomCamera/Screenshots/cc01.jpeg" width="30%" alt="Camera ViewFinder Portrait" />
  <img src="CustomCamera/Screenshots/cc02.jpeg" class="rotate-90" width="30%" alt="Camera ViewFinder Landscape Right" />
</div>

2. Change Lens (Ultrawide, Wide, Telescope)
<div class="section2">
  <img src="CustomCamera/Screenshots/cc03.jpeg" width="30%" />
  <img src="CustomCamera/Screenshots/cc04.jpeg" width="30%" />
  <img src="CustomCamera/Screenshots/cc05.jpeg" width="30%"  />
</div>

3. WaterMark & Flashback 
<div class="section2">
  <img src="CustomCamera/Screenshots/cc06.jpeg" width="30%" />
  <img src="CustomCamera/Screenshots/cc07.jpg" width="30%" />
</div>



## REFERENCE

1. SwiftUI 카메라 기능 구성
- https://betterprogramming.pub/effortless-swiftui-camera-d7a74abde37e
- https://enebin.medium.com/swiftui%EB%A7%8C-%EC%8D%A8%EC%84%9C-%ED%98%B8%EB%8B%A4%EB%8B%A5-%EC%B9%B4%EB%A9%94%EB%9D%BC%EC%95%B1-%EB%A7%8C%EB%93%A4%EA%B8%B0-feat-mvvm-1-2782b457f796

2. UIKit 카메라 기능 및 구성,Flash light, LivePhoto, Video Photo 촬영 전환 
AVCam: Building a Camera App - Sample Code
- https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app

3. 화면 회전 고정 및 아이콘 회전
- https://stackoverflow.com/questions/59140440/swiftui-disable-auto-rotation-of-views 

4. SwiftUI 화면 Image로 변환
- https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image
- https://developer.apple.com/documentation/swiftui/imagerenderer

5. 사진보관함 불러오기
Browsing and Modifying Photo Albums
- https://developer.apple.com/documentation/photokit/browsing_and_modifying_photo_albums
Browsing Your Photos
- https://developer.apple.com/tutorials/sample-apps/capturingphotos-browsephotos
