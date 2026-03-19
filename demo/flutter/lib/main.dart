// RaTeX Flutter Demo
//
// Demonstrates native LaTeX rendering via RaTeXWidget / RaTeXEngine.
//
// Font note: glyph outlines are compiled into the Rust static library
// (libratex_ffi) — no font files are bundled in the Flutter app.
// The xcframework's simulator slice (arm64 + x86_64) is linked at build time
// by CocoaPods, so `flutter run` on an iOS Simulator works without extra steps.

import 'package:flutter/material.dart';
import 'package:ratex_flutter/ratex_flutter.dart';

// ---------------------------------------------------------------------------
// Inline math paragraph helper
//
// Parses a string that contains inline LaTeX segments delimited by $...$
// and builds a RichText with WidgetSpans for the math parts.
// ---------------------------------------------------------------------------

/// Parses [text] with `$...$` inline math markers and returns a [RichText]
/// that intermixes plain [TextSpan]s with [WidgetSpan]s containing
/// [RaTeXWidget]s.
Widget buildInlineMath(
  String text, {
  double mathFontSize = 18,
  TextStyle? textStyle,
}) {
  final style = textStyle ??
      const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87);

  final parts = text.split('\$');
  final spans = <InlineSpan>[];

  for (int i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    if (i.isEven) {
      // Plain text segment
      spans.add(TextSpan(text: parts[i], style: style));
    } else {
      // Inline math segment
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        baseline: TextBaseline.alphabetic,
        child: RaTeXWidget(
          latex: parts[i],
          fontSize: mathFontSize,
          onError: (e) => debugPrint('RaTeX inline error: $e'),
          loading: const SizedBox.shrink(),
        ),
      ));
    }
  }

  return RichText(text: TextSpan(children: spans));
}

void main() {
  runApp(const RaTeXDemoApp());
}

class RaTeXDemoApp extends StatelessWidget {
  const RaTeXDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaTeX Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo page
// ---------------------------------------------------------------------------

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Preset formulas (same set as the iOS demo)
  static const _formulas = [
    (name: '二次方程',  latex: r'\frac{-b \pm \sqrt{b^2-4ac}}{2a}'),
    (name: '欧拉公式',  latex: r'e^{i\pi} + 1 = 0'),
    (name: '高斯积分',  latex: r'\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}'),
    (name: '级数',      latex: r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}'),
    (name: '矩阵',      latex: r'\begin{pmatrix}a & b \\ c & d\end{pmatrix}'),
    (name: 'Maxwell',   latex: r'\nabla \times \mathbf{B} = \mu_0 \mathbf{J}'),
    (name: '二项式',    latex: r'(x+y)^n = \sum_{k=0}^n \binom{n}{k} x^k y^{n-k}'),
    (name: '中线符号',  latex: r'\left( \frac{a}{b} \middle| \frac{c}{d} \right)'),
    (name: '微积分基本定理', latex: r'\frac{d}{dx}\left[\int_a^x f(t)\,dt\right] = f(x)'),
    (name: 'Stokes',    latex: r'\oint_{\partial\Sigma} \mathbf{F}\cdot d\mathbf{r} = \iint_\Sigma (\nabla\times\mathbf{F})\cdot d\mathbf{S}'),
  ];

  final _controller = TextEditingController(
    text: r'\frac{d}{dx}\left[\int_a^x f(t)\,dt\right] = f(x)',
  );
  double _fontSize = 24;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RaTeX Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Custom input ────────────────────────────────────────────────
          _SectionHeader('自定义公式'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: '输入 LaTeX',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                    autocorrect: false,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('字号: ${_fontSize.toInt()}px',
                          style: Theme.of(context).textTheme.bodySmall),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 14,
                          max: 48,
                          divisions: 17,
                          label: '${_fontSize.toInt()}',
                          onChanged: (v) => setState(() => _fontSize = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FormulaCard(
                      latex: _controller.text, fontSize: _fontSize),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Inline math in text ─────────────────────────────────────────
          _SectionHeader('行内公式'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Single-line example
                  Text('单行示例',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 6),
                  buildInlineMath(
                    r'欧拉恒等式 $e^{i\pi}+1=0$ 被誉为最美丽的数学公式。',
                  ),
                  const SizedBox(height: 16),
                  // Multi-line example 1 — physics
                  Text('多行示例（物理）',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 6),
                  buildInlineMath(
                    r'质能等价关系为 $E = mc^2$，其中光速 $c \approx 3\times10^8\ \text{m/s}$。'
                    '\n'
                    r'动量 $p = mv$ 满足牛顿第二定律 $F = \frac{dp}{dt}$。',
                  ),
                  const SizedBox(height: 16),
                  // Multi-line example 2 — math
                  Text('多行示例（数学）',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 6),
                  buildInlineMath(
                    r'二次方程 $ax^2+bx+c=0$ 的根为 $x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}$。'
                    '\n'
                    r'调和级数 $\sum_{n=1}^{\infty}\frac{1}{n}$ 发散，'
                    r'但交错调和级数 $\sum_{n=1}^{\infty}\frac{(-1)^{n+1}}{n}=\ln 2$ 收敛。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Preset formulas ─────────────────────────────────────────────
          _SectionHeader('公式示例'),
          ..._formulas.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        _FormulaCard(latex: f.latex, fontSize: 22),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

/// Renders a single LaTeX formula with error fallback.
class _FormulaCard extends StatelessWidget {
  final String latex;
  final double fontSize;

  const _FormulaCard({required this.latex, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    if (latex.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: RaTeXWidget(
        latex: latex,
        fontSize: fontSize,
        onError: (e) => debugPrint('RaTeX error: $e'),
        // Show a red label on parse error instead of crashing.
        loading: const SizedBox.shrink(),
      ),
    );
  }
}
