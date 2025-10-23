# Location Tracking với Background Notifications

Ứng dụng này implement location tracking cho iOS với khả năng gửi notifications ngay cả khi app bị killed.

## Tính năng

### 1. Background Location Tracking
- **startMonitoringSignificantLocationChanges()**: Theo dõi thay đổi vị trí đáng kể (tiết kiệm pin)
- **startMonitoringVisits()**: Phát hiện khi người dùng ở lại một địa điểm
- **startUpdatingLocation()**: Cập nhật vị trí liên tục khi app đang active

### 2. Geofencing
- **startMonitoring(for: region)**: Tạo vùng địa lý và nhận thông báo khi vào/ra khỏi vùng

### 3. Background Modes đã được cấu hình
- `location`: Cho phép app theo dõi vị trí ở background
- `processing`: Xử lý tác vụ ở background
- `fetch`: Cập nhật dữ liệu ở background

## Cách sử dụng

### 1. Chạy app
\`\`\`bash
fvm flutter run
\`\`\`

### 2. Cấp quyền
- App sẽ yêu cầu quyền "Always Allow Location"
- Nhấn "Start Tracking" để bắt đầu theo dõi

### 3. Thêm Geofence
- Nhập latitude, longitude, radius và tên
- Nhấn "Add Geofence"

### 4. Test Background
- Thoát app hoặc kill app
- Di chuyển vị trí để nhận notifications

## Cấu hình Background trong Xcode

### Info.plist đã được cấu hình:
\`\`\`xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>processing</string>
    <string>fetch</string>
</array>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track your location and send notifications even when the app is in background.</string>
\`\`\`

### AppDelegate.swift đã được cấu hình:
- Background fetch handling
- Application lifecycle methods
- Method channel cho Flutter communication

### LocationManager.swift features:
- `allowsBackgroundLocationUpdates = true`
- `pausesLocationUpdatesAutomatically = false`
- Significant location changes monitoring
- Visit monitoring
- Geofence monitoring
- Local notifications

## Lưu ý quan trọng

1. **Always Permission**: Phải có quyền "Always Allow Location" mới hoạt động ở background

2. **Battery Optimization**: Sử dụng significant location changes thay vì standard location updates để tiết kiệm pin

3. **Testing**: 
   - Test trên device thật, không phải simulator
   - Kill app và di chuyển để test background notifications

4. **iOS Limitations**:
   - iOS có thể tạm dừng background location updates nếu app không được sử dụng lâu
   - Notifications có thể bị delay khi device ở chế độ sleep

## Troubleshooting

1. **Không nhận được notifications**:
   - Kiểm tra quyền location (Always)
   - Kiểm tra quyền notifications
   - Chắc chắn background app refresh được bật

2. **Build errors**:
   - Chạy `fvm flutter clean && fvm flutter pub get`
   - Kiểm tra Xcode project settings

3. **Location không update**:
   - Kiểm tra location services được bật
   - Di chuyển đủ xa (> 500m cho significant changes)
