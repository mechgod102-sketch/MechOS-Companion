import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../models/optimization_report.dart';

class ReportShareService {
  Future<void> saveToGallery(String path) async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) throw Exception('Photo access was not granted');
    }
    await Gal.putImage(path, album: 'MechOS Reports');
  }

  Future<void> share(String path, OptimizationReport report) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'image/png')],
        subject: 'MechOS Optimization Report ${report.reportId}',
        text: 'MechOS optimization report ${report.reportId} • Score ${report.score}/100',
      ),
    );
  }
}
