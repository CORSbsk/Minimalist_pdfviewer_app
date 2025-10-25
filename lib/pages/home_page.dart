import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controlador que permite el zoom dentro de la aplicacion
  late PdfControllerPinch pdfControllerPinch;

  int totalPageCount = 0, currentPage = 1;

  @override
  void initState() {
    pdfControllerPinch = PdfControllerPinch(
      document: PdfDocument.openAsset("assets/test_pdfs/Hola_mundo1.pdf"),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Total pages: $totalPageCount"),
            IconButton(
              onPressed: () {
                pdfControllerPinch.previousPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.linear,
                );
              },
              icon: Icon(Icons.arrow_back),
            ),
            Text("Total pages: $currentPage"),
            IconButton(
              onPressed: () {
                pdfControllerPinch.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.linear,
                );
              },
              icon: Icon(Icons.arrow_forward),
            ),
          ],
        ),
        _pdfView(),
      ],
    );
  }

  Widget _pdfView() {
    return Expanded(
      child: PdfViewPinch(
        // cambiar la direccion de scroll
        scrollDirection: Axis.vertical,
        controller: pdfControllerPinch,
        onDocumentLoaded: (doc) {
          setState(() {
            totalPageCount = doc.pagesCount;
          });
        },
        onPageChanged: (page) {
          setState(() {
            currentPage = page;
          });
        },
      ),
    );
  }
}
