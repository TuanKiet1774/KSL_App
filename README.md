# KSL — Học & Nhận diện Ngôn ngữ Ký hiệu Việt Nam (VSL)

Ứng dụng Flutter hỗ trợ học từ vựng và nhận diện Ngôn ngữ ký hiệu Việt Nam (VSL)

## Tính năng chính

- **Học từ vựng theo chủ đề**: danh sách chủ đề, từ vựng, lưu từ đã học/yêu thích, theo dõi tiến độ học.
- **Bài thi/kiểm tra**: làm bài thi trắc nghiệm theo chủ đề, xem kết quả.
- **Nhận diện ký hiệu thời gian thực**: dùng camera + MediaPipe hand landmark + model TFLite để nhận diện ký hiệu tay (25 lớp: A-Y, Đ, dấu mũ và dấu râu).
- **Hướng dẫn sử dụng**, video minh hoạ (YouTube player), biểu đồ tiến độ học (fl_chart).

## Kiến trúc

State management dùng **Provider** (`ChangeNotifier`) — mỗi feature có 1 provider ôm cả state (danh sách, loading, lỗi, phân trang) và việc gọi API, đăng ký tập trung qua `MultiProvider` trong `main.dart`. Controller (service layer) chỉ đảm nhận việc gọi REST API thuần (HTTP, parse JSON) và được provider tương ứng bọc lại; view chỉ tương tác với provider qua `context.watch`/`context.read`, không gọi controller trực tiếp.

```
lib/
├── model/         # Data models: exam, question, word, user, progress, feedback, learnedWord, favoriteWord
├── controller/     # Service layer gọi REST API (auth, exam, favorite, feedback, learnedWord, progress, topic, word)
├── provider/       # ChangeNotifier theo feature, bọc controller + quản lý state (AuthProvider, TopicProvider,
│                   #   WordProvider, ExamProvider, FavoriteWordProvider, LearnedWordProvider, ProgressProvider, FeedbackProvider)
├── view/           # Màn hình UI (home, login/register, topic, word, exam, learned, favorite, settings, feedback...)
├── component/       # Widget tái sử dụng (appColors, avatar, navigation, dialog, loading effect...)
├── connectDB/        # Tích hợp API: api.dart (backend), imgBB.dart (upload ảnh)
└── signlanguage/      # Pipeline nhận diện ký hiệu
    ├── recognition_screen.dart  # Giao diện camera, xử lý frame, hiển thị kết quả
    ├── vsl_classifier.dart       # TFLite inference
    └── skeleton_renderer.dart    # Vẽ pose skeleton
```

### Pipeline nhận diện ký hiệu

```
Camera frame
  → MethodChannel native Android (com.ksl.ksl/hand_landmark) trích 21 hand landmarks
  → SkeletonRenderer vẽ skeleton 224x224
  → VSLClassifier chạy model TFLite mobilenetv2_vsl.tflite
  → Top-k predictions hiển thị real-time trong RecognitionScreen
```

## Backend & dịch vụ bên ngoài

- **REST API**: auth Bearer token lưu trong `SharedPreferences`. Heartbeat mỗi 30s cập nhật thời gian học (`/api/progress/update-learning-time`).
- **ImgBB**: dùng để upload ảnh kèm phản hồi.

## Models AI sử dụng

| File                     | Vị trí    | Mô tả                                                 |
| ------------------------ | --------- | ----------------------------------------------------- |
| `mobilenetv2_vsl.tflite` | `assets/` | Model phân loại ký hiệu tay VSL, dựa trên MobileNetV2 |
| `hand_landmarker.task`   | `assets/` | MediaPipe hand landmark detection                     |
| `label_map.json`         | `assets/` | Bảng nhãn 25 ký hiệu                                  |

## Công nghệ sử dụng

- **Flutter** (SDK ^3.10.0)
- State management: `provider`
- Nhận diện ký hiệu: `tflite_flutter`, `camera`, `google_mlkit_pose_detection`, `mediapipe_task_vision`
- UI/UX: `fl_chart`, `flutter_animate`, `percent_indicator`
- Media: `image_picker`, `video_player`, `youtube_player_flutter`, `cached_network_image`
- Khác: `http`, `shared_preferences`, `url_launcher`, `intl`, `path_provider`, `wakelock_plus`

## Giao diện
