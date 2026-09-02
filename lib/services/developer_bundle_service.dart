import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/companion_features.dart';
import 'report_image_service.dart';

class DeveloperBundleFiles {
  const DeveloperBundleFiles({required this.imagePath, required this.jsonPath, required this.issuePath});
  final String imagePath;
  final String jsonPath;
  final String issuePath;
}

class DeveloperBundleService {
  Future<DeveloperBundleFiles> generate(DeveloperBundle bundle) async {
    final dir = await getTemporaryDirectory();
    final safeId = bundle.reportId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final jsonPath = '${dir.path}/MechOS_${safeId}_developer-report.json';
    final issuePath = '${dir.path}/MechOS_${safeId}_github-issue.md';

    await File(jsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(bundle.raw), flush: true);

    final logs = (bundle.raw['logs'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final issue = StringBuffer()
      ..writeln('# MechOS Developer Report ${bundle.reportId}')
      ..writeln()
      ..writeln('- Device: ${bundle.optimizationReport.hostname}')
      ..writeln('- Version: ${bundle.optimizationReport.osVersion}')
      ..writeln('- Build channel: ${bundle.optimizationReport.buildChannel}')
      ..writeln('- Optimization score: ${bundle.optimizationReport.score}/100')
      ..writeln('- Generated: ${bundle.optimizationReport.generatedAt.toIso8601String()}')
      ..writeln()
      ..writeln('## Findings');
    for (final finding in bundle.optimizationReport.findings) {
      issue.writeln('- **${finding.severity.toUpperCase()} — ${finding.title}:** ${finding.detail}');
    }
    issue
      ..writeln()
      ..writeln('## Recommended fixes');
    for (final fix in bundle.optimizationReport.recommendedFixes) {
      issue.writeln('- $fix');
    }
    issue
      ..writeln()
      ..writeln('## Collected logs');
    for (final entry in logs.entries) {
      issue
        ..writeln()
        ..writeln('### ${entry.key}')
        ..writeln('```text')
        ..writeln(entry.value)
        ..writeln('```');
    }
    await File(issuePath).writeAsString(issue.toString(), flush: true);

    final image = await ReportImageService().generate(bundle.optimizationReport, format: ReportImageFormat.summary);
    return DeveloperBundleFiles(imagePath: image.path, jsonPath: jsonPath, issuePath: issuePath);
  }

  Future<void> share(DeveloperBundle bundle, DeveloperBundleFiles files) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(files.imagePath, mimeType: 'image/png'),
          XFile(files.jsonPath, mimeType: 'application/json'),
          XFile(files.issuePath, mimeType: 'text/markdown'),
        ],
        subject: 'MechOS Developer Report ${bundle.reportId}',
        text: 'MechOS developer report ${bundle.reportId}. Includes optimization image, structured JSON, and a GitHub-ready issue report.',
      ),
    );
  }
}
