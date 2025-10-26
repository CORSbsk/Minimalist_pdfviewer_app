import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PdfControllerPinch pdfControllerPinch;

  int totalPageCount = 0, currentPage = 1;

  bool isUIVisible = true;

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
      backgroundColor: Colors.white,
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Verificar toque en cualquier parte
      onTap: () {
        setState(() {
          isUIVisible = !isUIVisible; // Alternar la visibilidad
        });
      },
      child: Stack(
        children: [
          // Visor PDF
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: _pdfView(),
          ),

          // AppBar flotante
          if (isUIVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  color: Colors.white,
                  height: kToolbarHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        "PDF Viewer",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Barra de controles inferior
          if (isUIVisible)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón página anterior
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    pdfControllerPinch.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),

                // Indicador de página
                Text(
                  "Página $currentPage de $totalPageCount",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),

                // Botón página siguiente
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    pdfControllerPinch.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfView() {
    return PdfViewPinch(
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
    );
  }
}
