import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileReaderService {
  /// Extract text content from a file based on its extension.
  /// Returns the extracted text, or null if the file type is unsupported.
  static Future<String?> extractText(String filePath, String extension) async {
    final ext = extension.toLowerCase();
    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      // Plain text files
      if (_isPlainText(ext)) {
        return await file.readAsString();
      }

      // PDF files
      if (ext == 'pdf') {
        return await _extractPdfText(file);
      }

      // Word documents (.docx)
      if (ext == 'docx') {
        return await _extractDocxText(file);
      }

      // Excel files (.xlsx) — extract cell text
      if (ext == 'xlsx') {
        return await _extractXlsxText(file);
      }

      // PowerPoint (.pptx) — extract slide text
      if (ext == 'pptx') {
        return await _extractPptxText(file);
      }

      // RTF — strip formatting, return raw text
      if (ext == 'rtf') {
        return _extractRtfText(await file.readAsString());
      }

      // Images — encode as base64 (truncated for prompt)
      if (_isImage(ext)) {
        final bytes = await file.readAsBytes();
        // Return a small note so the AI knows it's an image
        return '[Image file: ${bytes.length} bytes]\nThe user has attached an image. Please describe or analyze it if possible.';
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _isPlainText(String ext) {
    return const {
      'txt', 'md', 'json', 'csv', 'xml', 'yaml', 'yml', 'log',
      'dart', 'py', 'js', 'ts', 'jsx', 'tsx', 'java', 'kt', 'swift',
      'c', 'cpp', 'h', 'hpp', 'cs', 'go', 'rs', 'rb', 'php',
      'html', 'css', 'scss', 'sass', 'less',
      'sql', 'sh', 'bash', 'zsh', 'bat', 'ps1',
      'toml', 'ini', 'cfg', 'conf', 'env',
      'r', 'lua', 'perl', 'scala', 'groovy',
      'makefile', 'dockerfile', 'gitignore',
    }.contains(ext);
  }

  static bool _isImage(String ext) {
    return const {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'tiff', 'ico'}.contains(ext);
  }

  /// Extract text from PDF using Syncfusion
  static Future<String> _extractPdfText(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final text = PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
      if (text.trim().isNotEmpty) {
        buffer.writeln('--- Page ${i + 1} ---');
        buffer.writeln(text.trim());
        buffer.writeln();
      }
    }

    document.dispose();
    final result = buffer.toString().trim();
    if (result.isEmpty) throw Exception('No text found in PDF');
    return result;
  }

  /// Extract text from .docx (ZIP archive containing word/document.xml)
  static Future<String> _extractDocxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final docFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw Exception('Not a valid DOCX file'),
    );

    final xmlContent = utf8.decode(docFile.content as List<int>);
    // Strip XML tags to get plain text
    final text = _stripXmlTags(xmlContent);
    if (text.trim().isEmpty) throw Exception('No text found in DOCX');
    return text.trim();
  }

  /// Extract text from .xlsx (ZIP archive containing shared strings + sheets)
  static Future<String> _extractXlsxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final buffer = StringBuffer();

    // Try shared strings first (contains all cell text values)
    final sharedStrings = archive.files.where((f) => f.name == 'xl/sharedStrings.xml').firstOrNull;
    if (sharedStrings != null) {
      final xmlContent = utf8.decode(sharedStrings.content as List<int>);
      final text = _stripXmlTags(xmlContent);
      buffer.writeln(text.trim());
    }

    // Also try sheet1
    final sheet1 = archive.files.where((f) => f.name == 'xl/worksheets/sheet1.xml').firstOrNull;
    if (sheet1 != null && buffer.isEmpty) {
      final xmlContent = utf8.decode(sheet1.content as List<int>);
      final text = _stripXmlTags(xmlContent);
      buffer.writeln(text.trim());
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) throw Exception('No text found in XLSX');
    return result;
  }

  /// Extract text from .pptx (ZIP archive containing slide XML files)
  static Future<String> _extractPptxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final buffer = StringBuffer();
    final slideFiles = archive.files
        .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (int i = 0; i < slideFiles.length; i++) {
      final xmlContent = utf8.decode(slideFiles[i].content as List<int>);
      final text = _stripXmlTags(xmlContent);
      if (text.trim().isNotEmpty) {
        buffer.writeln('--- Slide ${i + 1} ---');
        buffer.writeln(text.trim());
        buffer.writeln();
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) throw Exception('No text found in PPTX');
    return result;
  }

  /// Strip RTF formatting to get plain text
  static String _extractRtfText(String rtf) {
    // Remove RTF control words and groups
    var text = rtf.replaceAll(RegExp(r'\\[a-z]+\d*\s?'), ' ');
    text = text.replaceAll(RegExp(r'[{}]'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  /// Strip XML tags, keep text content, add spaces between elements
  static String _stripXmlTags(String xml) {
    // Replace paragraph/break tags with newlines
    var text = xml.replaceAll(RegExp(r'<w:p[^>]*>'), '\n');
    text = text.replaceAll(RegExp(r'<a:p[^>]*>'), '\n');
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    // Remove all remaining XML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Decode XML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&apos;', "'");
    // Clean up whitespace
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n');
    return text.trim();
  }
}
