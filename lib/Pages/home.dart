import 'package:app1/Pages/entryList.dart';
import 'package:app1/Pages/studentInfo.dart';
import 'package:app1/utils/database_models.dart';
import 'package:app1/utils/database_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'studentList.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  late String _currentTime;
  Timer? _timer;
  int outsideCount = 0; // Firebase'den gelecek


  @override
  void initState() {
    super.initState();
    // DatabaseService().startAutoSync();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')}";
      
      outsideCount = Hive.box(studentBox)
        .values
        .where((s) => Map.from(s)[stateDB] == STATEOUT)
        .length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarM(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded( //Butonlar
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, right: 16),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Material( // Talebe Listesi Butonu
                          color: Colors.transparent,
                          child: Ink(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentListerPage())),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.list_alt_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Talebe Listesi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Material( // Giriş Çıkış Listesi Butonu
                          color: Colors.transparent,
                          child: Ink(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => entryListerPage())),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.list_alt_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Giriş-Çıkış Listesi",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Material(  // Giriş Çıkış Butonu
                          color: Colors.transparent,
                          child: Ink(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => (entryListerPage()))),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.list_alt_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Giriş Çıkış",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
              ),

            Expanded( //Bildirimler
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // ⏰ SAAT
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // 👥 DIŞARIDAKİ TALEBE SAYISI
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      outsideCount > 0
                          ? "Dışarıdaki Talebe Sayısı: $outsideCount"
                          : "Dışarıda öğrenci yok",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // 👨‍🏫 NÖBETÇİ HOCA
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person_outline),
                      SizedBox(width: 6),
                      Text(
                        "Nöbetçi Hoca: Ahmet Yılmaz",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  AppBar appBarM() {
    return AppBar(
      centerTitle: true,
      elevation: 10.0,
      title: Text(
        'Ahmediye K.I.O.S.K',
        style: TextStyle(
          color: Colors.white
        ),
        ),
      backgroundColor: const Color.fromARGB(255, 90, 90, 90),
    );
  }
}