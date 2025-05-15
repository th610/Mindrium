import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// 카메라 팝업
class CameraPopup extends StatefulWidget {
  const CameraPopup({super.key});

  @override
  State<CameraPopup> createState() => _CameraPopupState();
}

class _CameraPopupState extends State<CameraPopup> {
  CameraController? _controller;  // 카메라 컨트롤러
  List<CameraDescription>? _cameras;  // 사용 가능한 카메라 목록
  bool _isCameraReady = false;  // 카메라 초기화 완료 여부

  @override
  void initState() {
    super.initState();
    _initCamera(); // 카메라 초기화
  }

  // 카메라 초기화: 후면 카메라 사용, 중간 해상도, 오디오 X
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras(); // 모든 카메라 가져오기
      final backCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize(); // 컨트롤러 초기화
      if (!mounted) return;
      setState(() => _isCameraReady = true); // 초기화 완료 표시
    } catch (e) {
      debugPrint('카메라 초기화 오류: $e');
    }
  }

  // 사진 촬영 후 임시 경로에 저장
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    final directory = await getTemporaryDirectory(); // 임시 디렉토리
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(directory.path, fileName);

    final XFile photo = await _controller!.takePicture(); // 사진 촬영
    await photo.saveTo(filePath); // 저장

    if (!mounted) return;
    Navigator.pop(context, filePath); // 경로 반환하며 팝업 닫기
  }

  @override
  void dispose() {
    _controller?.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.padding),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.infinity,
          color: Colors.black,
          child: _isCameraReady
              ? Stack(
            children: [
              // 카메라 프리뷰
              Center(
                child: FittedBox(
                  fit: BoxFit.cover, // 비율 유지하며 화면 채우기
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              // 촬영 버튼 (하단 중앙)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: FloatingActionButton(
                    onPressed: _takePicture,
                    backgroundColor: AppColors.white,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          )
              : const Center(child: CircularProgressIndicator()), // 로딩 중
        ),
      ),
    );
  }
}

// 카메라 팝업을 호출하고 결과(사진 경로)를 반환하는 함수
Future<String?> showCameraPopup(BuildContext context) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => const CameraPopup(),
  );
  return result;
}




