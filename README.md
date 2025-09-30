# Voice Assistant iOS

Ứng dụng trợ lý giọng nói trên iOS, hỗ trợ giao tiếp tự nhiên bằng giọng nói.  
Ứng dụng đặc biệt hữu ích cho người khiếm thị, người cao tuổi, hoặc những ai muốn giảm bớt thao tác tay và tìm kiếm một công cụ trò chuyện, hỏi đáp bằng giọng nói nhanh chóng.

## Tính năng chính
- **Trò chuyện với AI**  
  Đặt câu hỏi và trò chuyện với AI (kết nối OpenAI API).  
  Dữ liệu hội thoại chỉ được xử lý để tạo phản hồi, không lưu trữ trong ứng dụng.

- **Mô tả vật thể bằng camera**  
  Sử dụng camera kết hợp mô hình YOLOv8 để nhận diện và mô tả các vật thể xung quanh.

- **Câu lệnh cố định**  
  Hỗ trợ các câu hỏi nhanh như: hỏi ngày giờ, thời tiết...

- **Tùy chỉnh giọng đọc**  
  Điều chỉnh tốc độ, giọng nam/nữ, phong cách đọc.

## Build
1. Mở project bằng Xcode (iOS 15 trở lên).  
2. Thêm file `yolov8m.mlpackage` vào project (nếu chưa có, có thể export từ YOLOv8 theo hướng dẫn trong thư mục `Scripts`).  
3. Cấu hình API key OpenAI của riêng bạn trong code (không có sẵn trong repo này).  
4. Build và chạy app trên thiết bị thật.

## License
Ứng dụng và mã nguồn được phát hành theo giấy phép [AGPL-3.0](LICENSE).  
Ứng dụng sử dụng YOLOv8 từ [Ultralytics](https://github.com/ultralytics/ultralytics) (AGPL-3.0).

---
