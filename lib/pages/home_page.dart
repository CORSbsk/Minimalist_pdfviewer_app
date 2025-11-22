import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui'; // For ImageFilter

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
  bool isDarkMode = false;
  String currentTitle = "Visor PDF";
  static const String _prefFileKey = 'last_pdf_path';
  static const String _prefPageKey = 'last_pdf_page';

  @override
  void initState() {
    super.initState();
    _loadLastPdf();
  }

  Future<void> _loadLastPdf() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPath = prefs.getString(_prefFileKey);
    final lastPage = prefs.getInt(_prefPageKey) ?? 1;

    if (lastPath != null && File(lastPath).existsSync()) {
      _openPdf(lastPath, initialPage: lastPage);
    }
  }

  // Cargar un archivo PDF desde el dispositivo
  Future<void> _pickAndLoadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _openPdf(path);
      }
    } catch (e) {
      _showError("Error al seleccionar archivo: $e");
    }
  }

  Future<void> _openPdf(String path, {int initialPage = 1}) async {
    try {
      // Mostramos una pantalla de carga temporal
      setState(() {
        pdfController = null;
        totalPages = 0;
        currentPage = initialPage;
        currentTitle = path.split(Platform.pathSeparator).last;
      });

      // Cerramos el documento anterior correctamente
      await Future.delayed(const Duration(milliseconds: 150));
      pdfController?.dispose();

      // Abrimos el nuevo documento de forma segura
      final document = PdfDocument.openFile(path);

      // Actualizamos el controlador y refrescamos la vista
      setState(() {
        pdfController = PdfControllerPinch(
          document: document,
          initialPage: initialPage,
        );
      });

      // Guardar en persistencia
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFileKey, path);
      await prefs.setInt(_prefPageKey, initialPage);
    } catch (e) {
      _showError("No se pudo abrir el PDF: $e");
    }
  }

  Future<void> _closePdf() async {
    setState(() {
      pdfController = null;
      totalPages = 0;
      currentPage = 1;
      currentTitle = "Visor PDF";
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefFileKey);
    await prefs.remove(_prefPageKey);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ==============================
  //         INTERFAZ UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
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
              Icon(
                Icons.picture_as_pdf,
                size: 60,
                color: isDarkMode ? Colors.white54 : Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                "Abre un PDF para comenzar",
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickAndLoadPdf,
                style: ElevatedButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 0,
                  side: BorderSide(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                  ),
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
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: showUI ? 0 : -kToolbarHeight - MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.7),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 10,
              left: 16,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón de cerrar
                _buildGlassButton(
                  icon: Icons.close,
                  onPressed: _closePdf,
                ),

                Expanded(
                  child: Text(
                    currentTitle,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Acciones
                Row(
                  children: [
                    _buildGlassButton(
                      icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      onPressed: () {
                        setState(() {
                          isDarkMode = !isDarkMode;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        popupMenuTheme: PopupMenuThemeData(
                          color: isDarkMode
                              ? Colors.grey[900]!.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        offset: const Offset(0, 40),
                        onSelected: (String value) {
                          if (value == 'open_file') _pickAndLoadPdf();
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'open_file',
                            child: Row(
                              children: [
                                Icon(Icons.folder_open, size: 20),
                                SizedBox(width: 10),
                                Text('Abrir archivo'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: showUI ? 24 : -80,
      left: 24,
      right: 24,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: (isDarkMode ? Colors.black : Colors.white).withOpacity(
                  0.7,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Página anterior
                  _buildNavButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: (pdfController != null && currentPage > 1)
                        ? () => pdfController!.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          )
                        : null,
                  ),

                  const SizedBox(width: 20),

                  // Indicador de página
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (totalPages > 0)
                          ? "$currentPage / $totalPages"
                          : "-- / --",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Página siguiente
                  _buildNavButton(
                    icon: Icons.arrow_forward_rounded,
                    onPressed:
                        (pdfController != null && currentPage < totalPages)
                        ? () => pdfController!.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDarkMode ? Colors.white : Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.white10 : Colors.black12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? (isDarkMode ? Colors.black : Colors.white)
                : (isDarkMode ? Colors.white38 : Colors.black38),
            size: 20,
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
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(_prefPageKey, page);
        });
      },
    );
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }
}
