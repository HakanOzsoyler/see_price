import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BarcodeScannerScreen(),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? barcodeee;
  String? urunIsim;
  double? urunFiyat;
  String? urunDoviz;
  static const MethodChannel _methodChannel = MethodChannel('com.example.barcode_scanner');
  bool _isScanned = false;
  Timer? _timer;
  String _outputMode = 'android';

  // Gizli ayarlar erişimi için
  bool _longPressCompleted = false;
  int _tapCountAfterLongPress = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _loadOutputMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _openConfigPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigPage(onSaved: () => setState(() {})),
      ),
    );
  }

  void _handleLogoLongPress() {
    _longPressCompleted = true;
    _tapCountAfterLongPress = 0;

    // 3 saniye içinde 2 tıklama gelmezse sıfırla
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 3), () {
      _longPressCompleted = false;
      _tapCountAfterLongPress = 0;
    });
  }

  void _handleLogoTap() {
    if (_longPressCompleted) {
      _tapCountAfterLongPress++;

      if (_tapCountAfterLongPress >= 2) {
        // Uzun basma + 2 tıklama tamamlandı, ayarları aç
        _longPressCompleted = false;
        _tapCountAfterLongPress = 0;
        _tapTimer?.cancel();
        _openConfigPage();
      }
    }
  }

  Future<void> _loadOutputMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _outputMode = prefs.getString('outputMode') ?? 'windows';
    });
    if (_outputMode == 'android') {
      _methodChannel.setMethodCallHandler(_handleMethodCall);
    }
  }

  // Android'den gelen metot çağrısını işleyen fonksiyon.
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBarcodeScanned') {
      final String barcode = call.arguments;
      if (barcode == 'dinamikotomasyonhakan') {
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConfigPage(onSaved: () => setState(() {})),
            ),
          );
        }
      } else {
        _handleBarcode(barcode);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _timer?.cancel();
    _tapTimer?.cancel();
    super.dispose();
  }

  // Barkod verisini işleyen ana fonksiyon.
  void _handleBarcode(String barcode) async {
    _timer?.cancel();
    setState(() {
      barcodeee = barcode;
      _isScanned = true;
    });
    // SharedPreferences'den config değerlerini oku0
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('clientId') ?? 'dinamikbarkod';
    final clientPass = prefs.getString('clientPass') ?? 'dampex56';
    final user = prefs.getString('user') ?? 'hakan';
    final password = prefs.getString('password') ?? '1475';
    final database = prefs.getString('database') ?? 'MikroDB_V16_100';
    final port = int.tryParse(prefs.getString('port') ?? '') ?? 1440;

    String dynamicQuery = """
SELECT
bar_kodu AS barkod,
sto_isim AS isim,
CAST(STOK_SATIS_FIYAT_LISTELERI.sfiyat_fiyati AS DECIMAL(8,2)) * (1-ISNULL(isk_isk1_yuzde,0)/100) AS fiyat,
dbo.fn_DovizSembolu(sfiyat_doviz) AS doviz
FROM
STOKLAR,
BARKOD_TANIMLARI,
STOK_SATIS_FIYAT_LISTELERI
LEFT OUTER JOIN
STOK_CARI_ISKONTO_TANIMLARI ON isk_stok_kod = sfiyat_iskontokod
WHERE
STOKLAR.sto_kod = BARKOD_TANIMLARI.bar_stokkodu
AND STOKLAR.sto_kod = STOK_SATIS_FIYAT_LISTELERI.sfiyat_stokkod
AND STOK_SATIS_FIYAT_LISTELERI.sfiyat_listesirano = 1
AND BARKOD_TANIMLARI.bar_kodu = '$barcode';
""";
    try {
      var a = await Dio().post(
        'https://kernel.connectorabi.com/api/v1/mssql',
        options: Options(headers: {'clientId': clientId, 'clientPass': clientPass}),
        data: {
          "config": {
            "user": user,
            "password": password,
            "database": database,
            "server": "localhost",
            "port": port,
            "dialect": "mssql",
            "dialectOptions": {"instanceName": ""},
            "options": {"encrypt": false, "trustServerCertificate": true},
          },
          "query": dynamicQuery,
        },
      );
      log(a.toString());
      final data = a.data;
      if (data != null && data['success'] == true) {
        final records = data['data']?['recordsets']?[0];
        if (records != null && records.isNotEmpty) {
          final urun = records[0];
          setState(() {
            urunIsim = urun['isim']?.toString();
            urunFiyat = urun['fiyat'] is num ? urun['fiyat'].toDouble() : double.tryParse(urun['fiyat'].toString());
            urunDoviz = urun['doviz']?.toString();
          });
        } else {
          setState(() {
            urunIsim = 'Ürün bulunamadı';
            urunFiyat = null;
            urunDoviz = null;
          });
        }
      } else {
        setState(() {
          urunIsim = 'Sunucu hatası';
          urunFiyat = null;
          urunDoviz = null;
        });
      }
    } catch (e) {
      log(e.toString());
      setState(() {
        urunIsim = 'Bağlantı hatası';
        urunFiyat = null;
        urunDoviz = null;
      });
    }
    _controller.clear();
    _focusNode.requestFocus();
    _timer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _isScanned = false;
        barcodeee = null;
        urunIsim = null;
        urunFiyat = null;
        urunDoviz = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            // Ctrl+S ile ayarları aç
            if (event.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
              _openConfigPage();
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1c1c1c),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.05),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _outputMode == 'android' ? _buildAndroidView(context) : _buildWindowsView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAndroidView(BuildContext context) {
    return Row(
      children: [
        _isScanned
            ? const SizedBox()
            : Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleLogoTap,
                        onLongPress: _handleLogoLongPress,
                        child: Image.asset('assets/ic_big_logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.0,
                      height: MediaQuery.of(context).size.width * 0.0,
                      child: TextField(
                        controller: _controller,
                        readOnly: true,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.none,
                        decoration: const InputDecoration(
                          hintText: 'Barkod Okutunuz...',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      'Fiyat Gör',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 75,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
        !_isScanned
            ? const SizedBox()
            : Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        urunIsim ?? '',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        barcodeee ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Fiyat',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        urunFiyat != null && urunDoviz != null ? '${urunFiyat!.toStringAsFixed(2)} ${urunDoviz!}' : '',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildWindowsView(BuildContext context) {
    return Row(
      children: [
        // Sol: Okuma alanı - ürün geldiğinde küçülür
        _isScanned
            ? Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo küçük halde
                    SizedBox(
                      height: 80,
                      child: GestureDetector(
                        onTap: _handleLogoTap,
                        onLongPress: _handleLogoLongPress,
                        child: Image.asset('assets/ic_big_logo.png', fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fiyat Gör',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleLogoTap,
                        onLongPress: _handleLogoLongPress,
                        child: Image.asset('assets/ic_big_logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    // TextField
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        readOnly: false,
                        keyboardType: TextInputType.text,
                        onSubmitted: (value) {
                          if (value.toLowerCase() == 'config' || value == 'dinamikotomasyonhakan') {
                            _controller.clear();
                            _openConfigPage();
                          } else if (value.isNotEmpty) {
                            _handleBarcode(value);
                            _controller.clear();
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Barkod Okutunuz ve Enter\'a basınız...',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fiyat Gör',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 75,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
        // Sağ: Ürün bilgisi alanı - sadece ürün geldiğinde göster
        _isScanned
            ? Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ürün adı - responsive
                      Flexible(
                        child: Text(
                          urunIsim ?? '',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      // Barkod
                      Text(
                        barcodeee ?? '',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: MediaQuery.of(context).size.width * 0.02,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      // Fiyat başlığı
                      Text(
                        'Fiyat',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: MediaQuery.of(context).size.width * 0.025,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      // Fiyat - büyük ve responsive
                      Flexible(
                        child: Text(
                          urunFiyat != null && urunDoviz != null
                              ? '${urunFiyat!.toStringAsFixed(2)} ${urunDoviz!}'
                              : '',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.amber,
                            fontSize: MediaQuery.of(context).size.width * 0.08,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}
