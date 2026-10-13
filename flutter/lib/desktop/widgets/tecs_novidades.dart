import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _kTecsNovidadesUrl =
    'https://raw.githubusercontent.com/tecnicosdecuritiba/rustdesk/master/tecs/novidades.json';

class TecsNovidades extends StatefulWidget {
  const TecsNovidades({Key? key}) : super(key: key);

  @override
  State<TecsNovidades> createState() => _TecsNovidadesState();
}

class _TecsNovidadesState extends State<TecsNovidades> {
  List<Map<String, dynamic>> _cartoes = [];
  int _atual = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final resp = await http
          .get(Uri.parse(_kTecsNovidadesUrl))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final dados = jsonDecode(utf8.decode(resp.bodyBytes));
      final cartoes = (dados['cartoes'] as List)
          .whereType<Map<String, dynamic>>()
          .where((c) => (c['titulo'] ?? '').toString().isNotEmpty)
          .toList();
      if (!mounted || cartoes.isEmpty) return;
      final intervalo = (dados['intervalo'] as num?)?.toInt() ?? 15;
      setState(() => _cartoes = cartoes);
      if (cartoes.length > 1) {
        _timer = Timer.periodic(Duration(seconds: intervalo < 5 ? 5 : intervalo),
            (_) {
          if (mounted) setState(() => _atual = (_atual + 1) % _cartoes.length);
        });
      }
    } catch (e) {
      debugPrint('TecsNovidades: $e');
    }
  }

  Color _cor(String? hex) {
    final v = int.tryParse((hex ?? '').replaceAll('#', ''), radix: 16);
    return v == null ? const Color(0xFF0A6FB0) : Color(0xFF000000 | v);
  }

  @override
  Widget build(BuildContext context) {
    if (_cartoes.isEmpty) return const SizedBox.shrink();
    final c = _cartoes[_atual % _cartoes.length];
    final imagem = (c['imagem'] ?? '').toString();
    final link = (c['link'] ?? '').toString();
    final botao = (c['botao'] ?? '').toString();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('Novidades TECS',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9AA3B5))),
            ),
          ),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: imagem.isNotEmpty
                ? Image.network(imagem,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: _cor(c['cor'])))
                : Container(
                    color: _cor(c['cor']),
                    alignment: Alignment.center,
                    child: Text((c['icone'] ?? '').toString(),
                        style: const TextStyle(fontSize: 36)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(c['titulo'].toString(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF04225E))),
          ),
          if ((c['texto'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              child: Text(c['texto'].toString(),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF4A5F86))),
            ),
          if (botao.isNotEmpty && link.startsWith('https://'))
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7931E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => launchUrl(Uri.parse(link),
                      mode: LaunchMode.externalApplication),
                  child: Text(botao,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
