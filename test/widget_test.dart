import 'package:flutter_test/flutter_test.dart';
import 'package:youtube2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YouTubeDownloaderApp());

    // Verify app title or core elements exist
    expect(find.text('Downloader'), findsOneWidget);
    expect(find.text('Video Link'), findsOneWidget);
  });
}
