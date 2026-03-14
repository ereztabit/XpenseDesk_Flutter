import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'screen_imports.dart';
import '../providers/expense_provider.dart';

class ReceiptAnalyzerScreen extends ConsumerStatefulWidget {
  const ReceiptAnalyzerScreen({super.key});

  @override
  ConsumerState<ReceiptAnalyzerScreen> createState() =>
      _ReceiptAnalyzerScreenState();
}

class _ReceiptAnalyzerScreenState extends ConsumerState<ReceiptAnalyzerScreen>
    with FormBehaviorMixin {
  Uint8List? _selectedBytes;
  String? _selectedFilename;
  bool _isLoading = false;
  String? _result;
  bool _isError = false;

  @override
  bool get hasUnsavedChanges => false;

  Future<void> _pickFile() async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.jpg,.jpeg,.png';
    input.click();

    await input.onChange.first;

    final files = input.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0)!;
    final arrayBuffer = await file.arrayBuffer().toDart;
    final bytes = arrayBuffer.toDart.asUint8List();

    setState(() {
      _selectedBytes = bytes;
      _selectedFilename = file.name;
      _result = null;
      _isError = false;
    });
  }

  Future<void> _analyze() async {
    final bytes = _selectedBytes;
    final filename = _selectedFilename;
    if (bytes == null || filename == null) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _isError = false;
    });

    try {
      final expenseService = ref.read(expenseServiceProvider);
      final json = await expenseService.analyzeReceipt(bytes, filename);
      if (!mounted) return;
      setState(() {
        _result = json;
        _isError = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = e.toString();
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.receiptAnalyzerTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: Text(l10n.receiptAnalyzerPickImage),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _selectedFilename ?? l10n.receiptAnalyzerNoFileSelected,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: (_selectedBytes != null && !_isLoading)
                            ? _analyze
                            : null,
                        child: Text(
                          _isLoading
                              ? l10n.receiptAnalyzerAnalyzing
                              : l10n.receiptAnalyzerAnalyze,
                        ),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          _isError
                              ? l10n.receiptAnalyzerError
                              : l10n.receiptAnalyzerResult,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: _isError
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            border: Border.all(
                              color: _isError
                                  ? Theme.of(context).colorScheme.error
                                  : AppTheme.border,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _result!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
