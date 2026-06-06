import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const ClipboardApp());

class ClipboardApp extends StatelessWidget {
  const ClipboardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '剪贴板历史', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true, brightness: Brightness.dark),
    home: const ClipboardHomePage(),
  );
}

class ClipItem {
  String id, content;
  bool pinned;
  DateTime time;
  ClipItem({required this.id, required this.content, this.pinned = false, required this.time});
  Map<String, dynamic> toJson() => {'id': id, 'content': content, 'pinned': pinned, 'time': time.toIso8601String()};
  factory ClipItem.fromJson(Map<String, dynamic> j) => ClipItem(id: j['id'], content: j['content'], pinned: j['pinned'] ?? false, time: DateTime.parse(j['time']));
}

class ClipboardHomePage extends StatefulWidget {
  const ClipboardHomePage({super.key});
  @override
  State<ClipboardHomePage> createState() => _ClipboardHomePageState();
}

class _ClipboardHomePageState extends State<ClipboardHomePage> {
  List<ClipItem> _items = [];
  final _addCtrl = TextEditingController();
  String _searchQuery = '';
  bool _mergeMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('clipboard_items');
    if (d != null) setState(() => _items = (json.decode(d) as List).map((e) => ClipItem.fromJson(e)).toList());
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('clipboard_items', json.encode(_items.map((e) => e.toJson()).toList()));
  }

  List<ClipItem> get _filtered {
    var list = _items;
    if (_searchQuery.isNotEmpty) list = list.where((i) => i.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    list.sort((a, b) { if (a.pinned && !b.pinned) return -1; if (!a.pinned && b.pinned) return 1; return b.time.compareTo(a.time); });
    return list;
  }

  void _add() {
    if (_addCtrl.text.trim().isEmpty) return;
    setState(() => _items.insert(0, ClipItem(id: DateTime.now().millisecondsSinceEpoch.toString(), content: _addCtrl.text.trim(), time: DateTime.now())));
    _addCtrl.clear(); _save();
  }

  void _togglePin(ClipItem item) { setState(() => item.pinned = !item.pinned); _save(); }
  void _delete(ClipItem item) { setState(() => _items.removeWhere((i) => i.id == item.id)); _save(); }
  void _copy(ClipItem item) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制: ${item.content.substring(0, item.content.length > 30 ? 30 : item.content.length)}...'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1))); }

  void _toggleMergeMode() { setState(() { _mergeMode = !_mergeMode; _selectedIds.clear(); }); }
  void _toggleSelect(String id) { setState(() { if (_selectedIds.contains(id)) _selectedIds.remove(id); else _selectedIds.add(id); }); }

  void _mergeSelected() {
    if (_selectedIds.length < 2) return;
    final selected = _items.where((i) => _selectedIds.contains(i.id)).toList();
    final merged = selected.map((i) => i.content).join('\n---\n');
    setState(() {
      _items.removeWhere((i) => _selectedIds.contains(i.id));
      _items.insert(0, ClipItem(id: DateTime.now().millisecondsSinceEpoch.toString(), content: '📋 合并内容:\n$merged', time: DateTime.now()));
      _mergeMode = false; _selectedIds.clear();
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已合并选中内容'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 剪贴板历史'), centerTitle: true, actions: [
        IconButton(icon: Icon(_mergeMode ? Icons.merge : Icons.merge_type), onPressed: _toggleMergeMode, tooltip: _mergeMode ? '退出合并' : '合并模式'),
        if (_mergeMode) IconButton(icon: const Icon(Icons.check), onPressed: _mergeSelected, tooltip: '合并选中'),
        IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('清空确认'), content: const Text('清空所有未固定的剪贴板记录？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), FilledButton(onPressed: () { setState(() => _items.removeWhere((i) => !i.pinned)); _save(); Navigator.pop(ctx); }, child: const Text('清空'))])), tooltip: '清空'),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: TextField(controller: _addCtrl, decoration: const InputDecoration(hintText: '手动添加剪贴板内容...', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), maxLines: 1, onSubmitted: (_) => _add())),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('添加')),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: '搜索剪贴板...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
        const SizedBox(height: 8),
        Expanded(child: _filtered.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.content_paste, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('剪贴板为空', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)), const SizedBox(height: 8), Text('复制内容会自动记录', style: TextStyle(color: Colors.grey.shade400))])) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: _filtered.length, itemBuilder: (ctx, i) {
          final item = _filtered[i];
          final isSelected = _selectedIds.contains(item.id);
          return Card(margin: const EdgeInsets.only(bottom: 8), color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null, child: InkWell(onTap: _mergeMode ? () => _toggleSelect(item.id) : () => _copy(item), onLongPress: !_mergeMode ? () => _togglePin(item) : null, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (_mergeMode) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey, size: 20)),
              if (item.pinned) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 16, color: Colors.orange)),
              Expanded(child: Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text(_formatTime(item.time), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const Spacer(),
              if (!_mergeMode) ...[
                IconButton(icon: Icon(item.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18), onPressed: () => _togglePin(item), tooltip: item.pinned ? '取消固定' : '固定', visualDensity: VisualDensity.compact),
                IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () => _copy(item), tooltip: '复制', visualDensity: VisualDensity.compact),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red), onPressed: () => _delete(item), tooltip: '删除', visualDensity: VisualDensity.compact),
              ],
            ]),
          ]))));
        })),
      ]),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${t.month}/${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
  }
}
