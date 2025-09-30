from ultralytics import YOLO

# Load mô hình YOLOv8m đã tải về
model = YOLO("yolov8m.pt")

# Export sang CoreML với NMS
model.export(
    format="coreml",          # export CoreML
    nms=True,                 # bật Non-Max Suppression để Vision có box
    dynamic=False,            # input size cố định (nhanh hơn)
    half=True,                # float16 (giảm size)
    imgsz=640,                # kích thước input (chuẩn YOLO)
    optimize=True,            # tối ưu CoreML graph
)
