import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/services/ai_cost_service.dart';

class AiCostScreen extends StatefulWidget {
  const AiCostScreen({super.key});

  @override
  State<AiCostScreen> createState() => _AiCostScreenState();
}

class _AiCostScreenState extends State<AiCostScreen>
    with SingleTickerProviderStateMixin {
  final _service = AiCostService();

  late TabController _tabController;

  // 설정 탭
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _providers = [];
  bool _configLoading = true;
  String? _configError;
  String? _selectedProvider;
  String? _selectedModel;
  final _apiKeyCtrl = TextEditingController();
  final _apiKeyFocus = FocusNode();
  bool _saving = false;

  // 비용 탭
  Map<String, dynamic>? _summary;
  bool _costLoading = true;
  String? _costError;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfigs();
    _loadCost();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyCtrl.dispose();
    _apiKeyFocus.dispose();
    super.dispose();
  }

  Future<void> _pasteApiKeyFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text ?? '';
    if (raw.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('클립보드가 비어있습니다')),
        );
      }
      return;
    }
    final text = raw.trim();
    _apiKeyCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _apiKeyFocus.requestFocus();
  }

  /* ───── 설정 로드 ───── */

  Future<void> _loadConfigs() async {
    setState(() {
      _configLoading = true;
      _configError = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchConfigs(),
        _service.fetchProviders(),
      ]);
      final configs = results[0];
      final providers = results[1];
      final active = configs.firstWhere(
        (c) => c['isActive'] == true,
        orElse: () => configs.isNotEmpty ? configs.first : <String, dynamic>{},
      );
      setState(() {
        _configs = configs;
        _providers = providers;
        _selectedProvider = active['provider'] as String?;
        _selectedModel = active['model'] as String?;
        _configLoading = false;
      });
    } catch (e) {
      setState(() {
        _configError = e.toString();
        _configLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_selectedProvider == null) return;
    setState(() => _saving = true);
    try {
      await _service.updateConfig(
        provider: _selectedProvider!,
        model: _selectedModel,
        apiKey: _apiKeyCtrl.text.trim().isNotEmpty
            ? _apiKeyCtrl.text.trim()
            : null,
      );
      _apiKeyCtrl.clear();
      await _loadConfigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 설정이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ───── 비용 로드 ───── */

  Future<void> _loadCost() async {
    setState(() {
      _costLoading = true;
      _costError = null;
    });
    try {
      final data = await _service.fetchUsageSummary(days: _selectedDays);
      setState(() {
        _summary = data;
        _costLoading = false;
      });
    } catch (e) {
      setState(() {
        _costError = e.toString();
        _costLoading = false;
      });
    }
  }

  Future<void> _clearUsage() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사용량 초기화'),
        content: const Text('모든 사용량 기록을 삭제합니다. 계속할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.clearUsage();
      await _loadCost();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  /* ───── UI ───── */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 설정 & 비용',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: '설정'),
            Tab(icon: Icon(Icons.bar_chart), text: '비용'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigTab(),
          _buildCostTab(),
        ],
      ),
    );
  }

  /* ─── 설정 탭 ─── */

  Widget _buildConfigTab() {
    if (_configLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_configError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_configError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadConfigs, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final providerNames = {
      'claude': 'Anthropic Claude',
      'openai': 'OpenAI (ChatGPT)',
      'gemini': 'Google Gemini',
    };

    List<Map<String, dynamic>> currentModels = [];
    if (_selectedProvider != null) {
      final p = _providers.firstWhere(
        (p) => p['provider'] == _selectedProvider,
        orElse: () => <String, dynamic>{},
      );
      final rawModels = p['models'];
      if (rawModels is List) {
        currentModels = rawModels
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
      }
    }

    final activeConfig = _configs.firstWhere(
      (c) => c['provider'] == _selectedProvider,
      orElse: () => <String, dynamic>{},
    );
    final hasKey = activeConfig['hasApiKey'] == true;
    final keyHint = activeConfig['apiKeyHint'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('프로바이더 선택'),
          const SizedBox(height: 8),
          ...providerNames.entries.map((e) => RadioListTile<String>(
                title: Text(e.value),
                value: e.key,
                groupValue: _selectedProvider,
                onChanged: (v) {
                  setState(() {
                    _selectedProvider = v;
                    final p = _providers.firstWhere(
                      (p) => p['provider'] == v,
                      orElse: () => <String, dynamic>{},
                    );
                    final models = p['models'];
                    if (models is List && models.isNotEmpty) {
                      _selectedModel =
                          (models.first as Map)['id'] as String?;
                    }
                  });
                },
              )),
          const SizedBox(height: 16),

          _sectionTitle('모델 선택'),
          const SizedBox(height: 8),
          if (currentModels.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                underline: const SizedBox.shrink(),
                value: _selectedModel,
                items: currentModels
                    .map((m) => DropdownMenuItem<String>(
                          value: m['id'] as String,
                          child: Text(m['name'] as String? ?? m['id'] as String),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedModel = v),
              ),
            ),
          const SizedBox(height: 20),

          _sectionTitle('API 키'),
          const SizedBox(height: 8),
          if (hasKey)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text('등록됨: $keyHint',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyCtrl,
                  focusNode: _apiKeyFocus,
                  enableInteractiveSelection: true,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hasKey ? '새 키로 변경' : 'API 키를 입력하세요',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: _pasteApiKeyFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 18, color: Colors.white),
                  label: const Text('붙여넣기', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveConfig,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }

  /* ─── 비용 탭 ─── */

  Widget _buildCostTab() {
    if (_costLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_costError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_costError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadCost, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final s = _summary ?? {};
    final totalCost = (s['totalCostUsd'] as num?)?.toDouble() ?? 0.0;
    final totalReqs = (s['totalRequests'] as num?)?.toInt() ?? 0;
    final totalIn = (s['totalInputTokens'] as num?)?.toInt() ?? 0;
    final totalOut = (s['totalOutputTokens'] as num?)?.toInt() ?? 0;

    final byModel = s['byModel'] as Map<String, dynamic>? ?? {};
    final daily = (s['daily'] as List?)
            ?.map((d) => Map<String, dynamic>.from(d as Map))
            .toList() ??
        [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 선택
          Row(
            children: [
              _periodChip('7일', 7),
              const SizedBox(width: 8),
              _periodChip('30일', 30),
              const SizedBox(width: 8),
              _periodChip('전체', 0),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: '사용량 초기화',
                onPressed: _clearUsage,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 총 비용 카드
          _summaryCard(
            icon: Icons.attach_money,
            title: '총 비용',
            value: '\$${totalCost.toStringAsFixed(4)}',
            subtitle: '약 ${(totalCost * 1400).toStringAsFixed(0)}원',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),

          // 요청 & 토큰 카드
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.send,
                  title: '요청 수',
                  value: '$totalReqs회',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  icon: Icons.token,
                  title: '토큰',
                  value: _formatTokens(totalIn + totalOut),
                  subtitle: 'In: ${_formatTokens(totalIn)} / Out: ${_formatTokens(totalOut)}',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 모델별 사용량
          if (byModel.isNotEmpty) ...[
            _sectionTitle('모델별 사용량'),
            const SizedBox(height: 8),
            ...byModel.entries.map((e) {
              final v = e.value as Map<String, dynamic>;
              final cost = (v['costUsd'] as num?)?.toDouble() ?? 0.0;
              final reqs = (v['requests'] as num?)?.toInt() ?? 0;
              return _modelRow(e.key, cost, reqs);
            }),
            const SizedBox(height: 24),
          ],

          // 일별 사용량 바 차트
          if (daily.isNotEmpty) ...[
            _sectionTitle('일별 사용량'),
            const SizedBox(height: 12),
            _buildDailyChart(daily),
          ],
        ],
      ),
    );
  }

  /* ─── 위젯 헬퍼 ─── */

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget _periodChip(String label, int days) {
    final isSelected =
        (days == 0 && _selectedDays == 0) || _selectedDays == days;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedDays = days);
        _loadCost();
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ],
      ),
    );
  }

  Widget _modelRow(String model, double costUsd, int requests) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(model,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const Spacer(),
          Text('\$${costUsd.toStringAsFixed(4)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Text('$requests회',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDailyChart(List<Map<String, dynamic>> daily) {
    final maxCost = daily.fold<double>(
        0, (m, d) => ((d['costUsd'] as num?)?.toDouble() ?? 0) > m
            ? (d['costUsd'] as num).toDouble()
            : m);
    final barMax = maxCost > 0 ? maxCost : 1.0;

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daily.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final d = daily[i];
          final cost = (d['costUsd'] as num?)?.toDouble() ?? 0;
          final date = (d['date'] as String?) ?? '';
          final label = date.length >= 10
              ? '${date.substring(5, 7)}/${date.substring(8, 10)}'
              : date;
          final ratio = cost / barMax;

          return SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('\$${cost.toStringAsFixed(3)}',
                    style:
                        const TextStyle(fontSize: 8, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  height: 100 * ratio,
                  width: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return '$tokens';
  }
}
