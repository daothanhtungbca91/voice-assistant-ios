//
//  StringResources.swift
//  Demo GPT API
//
//  Created by Tung Dao Thanh on 22/8/25.
//

public class StringResources {

    public static let key_speak_time:String = "key_speak_time"
    public static let key_camera_preview:String = "key_camera_preview"
    public static let key_speechRate:String = "key_speechRate"
    public static let key_speechVoice:String = "key_speechVoice"
    public static let key_time_out:String = "key_time_out"
    public static let key_phone_number:String = "key_phone_number"

    public static let default_speak_rate:Float = 0.4
    public static let default_time_out_count:Int = 2
    public static var default_phone_number: String = "0987654321"
    
    public static let support_email: String = "daothanhtungbca91@gmail.com"

    public static let url_gpt: String = "https://us-central1-captions-and-status-1da5f.cloudfunctions.net/ask"
    public static let url_gpt_new: String = "https://ask-x7firm2vsq-uc.a.run.app"
    
    public static let huong_dan_su_dung: String = "Hướng dẫn sử dụng." +
    ". Trước tiên hãy đảm bảo điện thoại của bạn đã được người thân cài đặt tính năng mở nhanh ứng dụng trợ lý giọng nói, theo tài liệu hướng dẫn trong ứng dụng. Bạn nhớ mở khoá màn hình điện thoại, và mở lớn âm lượng loa trước khi sử dụng. Bước số 1, mở ứng dụng trợ lý giọng nói... bạn có thể mở ứng dụng trợ lý giọng nói bằng 2 cách sau. Cách 1, Bạn hãy dùng 1 ngón tay chạm 2 lần liên tiếp vào mặt sau, vùng chính giữa điện thoại để khởi động. Cách 2, bạn hãy nói, Hây Si ri, chờ khi có câu trả lời từ Si ri, bạn tiếp tục nói, trợ lý giọng nói. Bạn cũng có thể nhờ người thân bấm vào ảnh đại diện ứng dụng để mở ứng dụng... Khi ứng dụng khởi động thành công, bạn sẽ nghe thấy câu. Xin chào, tôi có thể giúp gì cho bạn. Nếu không nghe thấy gì, bạn hãy dừng 3 giây rồi tiếp tục thực hiện lại các cách trên. Khi ứng dụng đã mở thành công, bạn có thể bấm vào vùng giữa của màn hình điện thoại để dừng, hoặc chạy giao tiếp với trợ lý." +
    ". Bước số 2. Đưa ra yêu cầu hoặc đặt câu hỏi. Bạn hãy chờ ứng dụng nói xong câu, Xin chào, tôi có thể giúp gì cho bạn tầm khoảng 2 giây rồi mới đặt câu hỏi, không xen ngang lúc trợ lý đang nói. Sau khi nghe trả lời, để đặt câu hỏi mới, hãy chờ ứng dụng nói, Xin mời bạn nói. Bất kỳ yêu cầu hoặc câu hỏi nào của bạn chỉ được tiếp nhận sau khi trợ lý nói, Xin chào, tôi có thể giúp gì cho bạn, hoặc, Xin mời bạn nói. Ứnng dụng trợ lý giọng nói cung cấp các tính năng sau: tính năng 1. Để biết môi trường xung quanh bạn có những gì, bạn hãy nói: Mô tả xung quanh. tính năng 2. Để hỏi ngày giờ, hãy nói: Bây giờ là mấy giờ, hoặc, hôm nay là ngày nào, hoặc âm lịch là ngày nào. tính năng 3. Để nghe lại hướng dẫn, hãy nói: Hướng dẫn sử dụng. Tính năng 4. Đặt câu hỏi để trí tuệ nhân tạo trả lời. Bạn có thể trò truyện, đặt câu hỏi về kiến thức tổng quan, kiến thức khoa học, yêu cầu kể truyện, làm thơ, tính toán, vân vân, ứng dụng sẽ hỏi trí tuệ nhân tạo và trả lời bạn (phiên bản này chưa hỗ trợ hỏi các thông tin theo thời gian thực như giá vàng, tin thời sự). Bạn có 10 lượt hỏi trí tuệ nhân tạo mỗi ngày. Chú ý, nếu điện thoại không ghi nhận được chính xác câu bạn nói, hãy đưa điện thoại lại gần, và nói lại rõ ràng, tránh tiếng ồn." +
    ". Bước số 3. Đối với tính năng nhận diện môi trường xung quanh. Đây là tính năng giúp bạn nhận diện 1 số vật thể cơ bản như người, bàn, ghế, giường, tủ lạnh, ti vi, điện thoại, láp tốp, xe cộ, chó, mèo, xung quanh bạn. Kết quả bị ảnh hưởng bởi khung hình mà camera điện thoại thu được, độ chính xác của thuật toán nhận dạng, do vậy kết quả chỉ nên dùng để tham khảo. Khi sử dụng, bạn hãy hướng camera điện thoại về phía cần nhận dạng, và giữ yên trong khoảng 2 giây, để điện thoại có thể nhận dạng. Nếu muốn quay điện thoại ra hướng khác, hãy chờ điện thoại đọc hết các vật thể. Bấm vào màn hình khi đang ở tính năng này để thoát và trở về tính năng đặt câu hỏi" +
    ". Bước số 4. Để dừng trợ lý giọng nói, bạn hãy nói dừng trợ lý" +
    ". Bước số 5. Để tăng giảm đốc độ đọc, bạn hãy nói Tăng tốc độ đọc, hoặc, giảm tốc độ đọc. Các cài đặt khác như chọn giọng đọc, số điện thoại gọi điện, vân vân, bạn hãy nhờ người thân trợ giúp." +
    ". Bước số 6. Trong một số trường hợp, có thể có lỗi xảy ra khi sử dụng, hoặc bạn không nghe thấy gì trong khoảng thời gian dài, hãy thực hiện mở lại ứng dụng để sử dụng lại từ đầu. Nhờ người thân hỗ trợ nếu bạn không thể xử lý được."
        
}
