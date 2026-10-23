import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  static final CameraService instance = CameraService._internal();
  factory CameraService() => instance;
  CameraService._internal();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.auto;
  bool _isInitialized = false;
  bool _isAvailable = false;
  String? _errorMessage;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isAvailable => _isAvailable;
  String? get errorMessage => _errorMessage;
  int get selectedCameraIndex => _selectedCameraIndex;
  FlashMode get flashMode => _flashMode;
  bool get hasMultipleCameras => _cameras.length > 1;

  /// Initializes hardware cameras and starts controller preview
  Future<bool> initialize({ResolutionPreset preset = ResolutionPreset.high}) async {
    try {
      _errorMessage = null;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _isAvailable = false;
        _isInitialized = false;
        _errorMessage = 'কোনো ক্যামেরা পাওয়া যায়নি';
        return false;
      }

      _isAvailable = true;
      if (_selectedCameraIndex >= _cameras.length) {
        _selectedCameraIndex = 0;
      }

      await _initController(_cameras[_selectedCameraIndex], preset);
      return _isInitialized;
    } catch (e) {
      debugPrint('CameraService init error: $e');
      _isAvailable = false;
      _isInitialized = false;
      _errorMessage = 'ক্যামেরা চালু করা সম্ভব হয়নি: $e';
      return false;
    }
  }

  Future<void> _initController(CameraDescription camera, ResolutionPreset preset) async {
    final oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    final newController = CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await newController.initialize();
      await newController.setFlashMode(_flashMode);
      _controller = newController;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize CameraController: $e');
      _isInitialized = false;
      _errorMessage = e.toString();
      await newController.dispose();
      _controller = null;
    }
  }

  /// Captures a real picture from the camera sensor
  Future<XFile?> takePicture() async {
    if (!isInitialized || _controller == null) {
      debugPrint('Camera is not initialized when taking picture');
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      debugPrint('A picture is already being taken');
      return null;
    }

    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      _errorMessage = 'ছবি তুলতে সমস্যা হয়েছে: $e';
      return null;
    }
  }

  /// Toggles between front and rear cameras
  Future<bool> switchCamera({ResolutionPreset preset = ResolutionPreset.high}) async {
    if (_cameras.length < 2) return false;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_selectedCameraIndex], preset);
    return isInitialized;
  }

  /// Cycles flash mode (auto -> always -> off -> auto)
  Future<FlashMode> cycleFlashMode() async {
    if (!isInitialized || _controller == null) return _flashMode;

    switch (_flashMode) {
      case FlashMode.auto:
        _flashMode = FlashMode.always;
        break;
      case FlashMode.always:
        _flashMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        _flashMode = FlashMode.auto;
        break;
    }

    try {
      await _controller!.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
    return _flashMode;
  }

  /// Release camera hardware
  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    _isInitialized = false;
    if (c != null) {
      await c.dispose();
    }
  }
}
