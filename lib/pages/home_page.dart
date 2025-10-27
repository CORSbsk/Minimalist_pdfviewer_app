import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PdfControllerPinch? pdfController; // Controlador PDF (puede ser nulo)
  int totalPages = 0;
  int currentPage = 1;
  bool showUI = true;

  // Cargar un archivo PDF desde el dispositivo
  Future<void> _pickAndLoadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;

      // Mostramos una pantalla de carga temporal
      setState(() {
        pdfController = null;
        totalPages = 0;
        currentPage = 1;
      });

      // Cerramos el documento anterior correctamente
      await Future.delayed(const Duration(milliseconds: 150));
      pdfController?.dispose();

      // Abrimos el nuevo documento de forma segura
      final document = PdfDocument.openFile(path);

      // Actualizamos el controlador y refrescamos la vista
      setState(() {
        pdfController = PdfControllerPinch(document: document);
      });
    }
  }

  // ==============================
  //         INTERFAZ UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pdfController == null ? _buildEmptyView() : _buildPdfView(),
    );
  }

  // Estado vacío (cuando no hay PDF cargado)
  Widget _buildEmptyView() {
    return Stack(
      children: [
        // Contenido principal
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 60, color: Colors.grey),
              const SizedBox(height: 10),
              const Text(
                "Abre un PDF para comenzar",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickAndLoadPdf,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.file_open),
                label: const Text("Abrir PDF"),
              ),
            ],
          ),
        ),

        // Barra superior flotante
        if (showUI) _buildTopBar(),
      ],
    );
  }

  // Vista cuando hay un PDF cargado
  Widget _buildPdfView() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => showUI = !showUI),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight),
            child: _pdfViewer(),
          ),
          if (showUI) _buildTopBar(),
          if (showUI) _buildBottomBar(),
        ],
      ),
    );
  }

  // ==============================
  //         COMPONENTES
  // ==============================

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de cerrar
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),

            const Text(
              "Visor PDF",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Menú de tres puntos
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: const PopupMenuThemeData(
                  color: Colors.white, // fondo blanco del menú
                  textStyle: TextStyle(color: Colors.black),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (String value) {
                  if (value == 'open_file') _pickAndLoadPdf();
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'open_file',
                    child: Text('Abrir archivo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Página anterior
              IconButton(
                onPressed: (pdfController != null && currentPage > 1)
                    ? () => pdfController!.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                    : null,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: (currentPage > 1) ? Colors.white : Colors.grey,
                ),
              ),

              // Indicador de página
              Text(
                (totalPages > 0)
                    ? "Página $currentPage de $totalPages"
                    : "Cargando...",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

              // Página siguiente
              IconButton(
                onPressed: (pdfController != null && currentPage < totalPages)
                    ? () => pdfController!.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      )
                    : null,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: (currentPage < totalPages)
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pdfViewer() {
    if (pdfController == null) {
      return const Center(
        child: Text(
          "Cargando o sin documento",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return PdfViewPinch(
      controller: pdfController!,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (doc) {
        setState(() => totalPages = doc.pagesCount);
      },
      onPageChanged: (page) {
        setState(() => currentPage = page);
      },
    );
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }
}
