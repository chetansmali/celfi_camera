import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRScannerScreen extends StatefulWidget {
  final CameraDescription camera;

  const QRScannerScreen({
    required this.camera
});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  CameraController? _cameraController;
  QRViewController? _qrViewController;
  final GlobalKey qrkey = GlobalKey(debugLabel: 'QR');
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requiredCameraPermission();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _qrViewController?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _requiredCameraPermission() async{
    final status = await  Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });
    if(status.isGranted){
      _initializedCamera();
    }
  }

  void _initializedCamera(){
    availableCameras().then((cameras) {
      print("Availabels cameras : ${cameras}");
      final rearCamera = cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first
      );

      print("selected camera : $cameras ");

      _cameraController = CameraController(rearCamera, ResolutionPreset.max);
      _cameraController!.initialize().then((value) {
        if(!mounted){
          return;
        }
        setState(() {
          _isCameraInitialized = true;
        });
      });
    });
  }

  void _onQRViewCreated(QRViewController controller){
    setState(() {
      _qrViewController = controller;
    });

    _qrViewController!.scannedDataStream.listen((scanData) async{
      if(await canLaunch(scanData.code!)){
        await launch(scanData.code!);
      }else{
        print("Could not have launched ${scanData.code}");
      }
    });

    _qrViewController!.toggleFlash();
    _setCameraFoucsMode(FocusMode.auto);
    _cameraController!.startImageStream((CameraImage cameraImage) {
      if(_qrViewController != null){
        final qrCode = _decodeRqCode(cameraImage);
        if(qrCode != null){
          _qrViewController!.pauseCamera();

          //Handel the qr code data hera
          print("QR code :- ${qrCode}");
        }
      }
    });
  }


  Future<void> _setCameraFoucsMode(FocusMode focusMode) async{
      final currentFoucsMode = _cameraController!.value.focusMode;
      if(currentFoucsMode == focusMode){
        return;
      }
      await _cameraController!.setFocusMode(focusMode);
  }

  String? _decodeRqCode(CameraImage cameraImage){
    //perform QR code decoding hers using cameraImage
    //Return the decode QR code or null if no QR code is found
    //Replace this with our own QRcode decoding implement 
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
          child: Scaffold(
            appBar:  AppBar(
              backgroundColor: Colors.black,
              centerTitle: true,
              title: Text('QR Scanner'),
              actions: [
                Text(''),
              ],
              leading: Text(''),
            ),
            body: Column(
              children: [
                Expanded(
                    child: _isCameraInitialized
                      ? QRView(
                        key: qrkey,
                        onQRViewCreated: _onQRViewCreated,
                        overlay: QrScannerOverlayShape(
                          borderRadius: 10,
                          borderColor: Colors.white,
                          borderLength: 30,
                          borderWidth: 10,
                          cutOutSize: 300,
                        )

                    )
                        : Container(),
                ),
              ],
            ),
        ),
    );
  }
}
