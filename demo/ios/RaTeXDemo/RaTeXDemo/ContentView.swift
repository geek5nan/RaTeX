import SwiftUI

// 展示 RaTeX 渲染效果的 Demo 界面
struct ContentView: View {

    // 预置公式列表
    let formulas: [(name: String, latex: String)] = [
        ("二次方程", #"\frac{-b \pm \sqrt{b^2-4ac}}{2a}"#),
        ("欧拉公式", #"e^{i\pi} + 1 = 0"#),
        ("高斯积分", #"\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}"#),
        ("级数",     #"\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}"#),
        ("矩阵",     #"\begin{pmatrix}a & b \\ c & d\end{pmatrix}"#),
        ("Maxwell", #"\nabla \times \mathbf{B} = \mu_0 \mathbf{J}"#),
        ("二项式",   #"(x+y)^n = \sum_{k=0}^n \binom{n}{k} x^k y^{n-k}"#),
        ("中线符号", #"\left( \frac{a}{b} \middle| \frac{c}{d} \right)"#),
        // 较宽公式，用于观察溢出行为
        ("薛定谔方程", #"i\hbar\frac{\partial}{\partial t}\Psi(\mathbf{r},t) = \left[-\frac{\hbar^2}{2m}\nabla^2 + V(\mathbf{r},t)\right]\Psi(\mathbf{r},t)"#),
        ("泰勒展开",   #"f(x) = \sum_{n=0}^{\infty}\frac{f^{(n)}(0)}{n!}x^n = f(0) + f'(0)x + \frac{f''(0)}{2!}x^2 + \frac{f'''(0)}{3!}x^3 + \cdots"#),
    ]

    @State private var customLatex: String = #"\frac{d}{dx}\left[\int_a^x f(t)\,dt\right] = f(x)"#
    @State private var fontSize: Double = 24

    var body: some View {
        NavigationStack {
            List {
                // 自定义输入区
                Section("自定义公式") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("输入 LaTeX", text: $customLatex)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        HStack {
                            Text("字号: \(Int(fontSize))pt")
                                .font(.caption)
                            Slider(value: $fontSize, in: 14...48, step: 2)
                        }

                        RaTeXFormulaCell(latex: customLatex, fontSize: CGFloat(fontSize))
                    }
                    .padding(.vertical, 8)
                }

                // 预置公式
                Section("公式示例") {
                    ForEach(formulas, id: \.name) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            RaTeXFormulaCell(latex: item.latex, fontSize: 22)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // 图文混排：行内公式（FlowLayout 自动折行 + 基线对齐）
                Section("行内混排") {
                    InlineExamplesView()
                }

                // 图文混排：段落 + 块级公式
                Section("段落混排") {
                    BlockExamplesView()
                }

                // 图文混排：推导过程
                Section("推导过程") {
                    DerivationView()
                }
            }
            .navigationTitle("RaTeX Demo")
        }
    }
}

// MARK: - FlowLayout

/// 自动折行布局：子视图按水平方向排列，超出宽度后换行。
/// 同行内对齐策略：
///   - RaTeXFormula → 读取 RaTeXFormulaAscentKey（库内置，第一帧即可用）
///   - 普通 Text 视图 → 用 SwiftUI 原生 firstTextBaseline
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var lineSpacing: CGFloat = 6

    typealias Cache = [[(index: Int, size: CGSize)]]
    func makeCache(subviews: Subviews) -> Cache { [] }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        cache = lines(for: subviews, maxWidth: maxWidth)

        var h: CGFloat = 0
        for (i, line) in cache.enumerated() {
            h += line.map(\.size.height).max() ?? 0
            if i < cache.count - 1 { h += lineSpacing }
        }
        return CGSize(width: maxWidth, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        if cache.isEmpty {
            cache = lines(for: subviews, maxWidth: bounds.width)
        }

        var y = bounds.minY
        for line in cache {
            // 读取每个子视图的基线：
            //   RaTeXFormula → RaTeXFormulaAscentKey（库内置，第一帧即可用）
            //   普通 Text    → d[.firstTextBaseline]（SwiftUI 原生，对 Text 准确）
            let baselines: [CGFloat] = line.map { item in
                let customAscent = subviews[item.index][RaTeXFormulaAscentKey.self]
                if customAscent > 0 {
                    return customAscent
                }
                let d = subviews[item.index].dimensions(in: ProposedViewSize(item.size))
                let native = d[.firstTextBaseline]
                return native > 0 ? native : item.size.height / 2
            }

            let maxBaseline = baselines.max() ?? 0
            let lineHeight  = line.map(\.size.height).max() ?? 0

            var x = bounds.minX
            for (i, item) in line.enumerated() {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (maxBaseline - baselines[i])),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }
            y += lineHeight + lineSpacing
        }
    }

    private func lines(for subviews: Subviews, maxWidth: CGFloat) -> Cache {
        var result: Cache = []
        var currentLine: [(index: Int, size: CGSize)] = []
        var currentX: CGFloat = 0

        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = currentLine.isEmpty ? size.width : size.width + horizontalSpacing

            if currentX + needed > maxWidth, !currentLine.isEmpty {
                result.append(currentLine)
                currentLine = [(i, size)]
                currentX = size.width
            } else {
                if !currentLine.isEmpty { currentX += horizontalSpacing }
                currentLine.append((i, size))
                currentX += size.width
            }
        }
        if !currentLine.isEmpty { result.append(currentLine) }
        return result
    }
}

// MARK: - 行内混排示例

/// 每个示例使用 FlowLayout 将文字片段与公式视图混排，
/// 超出屏幕宽度自动折行，同行内保持基线对齐。
struct InlineExamplesView: View {
    // 公式字号与周围 body 文字视觉匹配
    private let fs: CGFloat = 17

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // ── 示例 1：牛顿第二定律 ──────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Label("牛顿第二定律", systemImage: "atom")
                    .font(.caption.bold()).foregroundStyle(.secondary)

                FlowLayout(horizontalSpacing: 3, lineSpacing: 6) {
                    Text("物体所受合力")
                    RaTeXFormula(latex: #"F"#,      fontSize: fs, onError: { _ in })
                    Text("等于质量")
                    RaTeXFormula(latex: #"m"#,      fontSize: fs, onError: { _ in })
                    Text("与加速度")
                    RaTeXFormula(latex: #"a"#,      fontSize: fs, onError: { _ in })
                    Text("之积，即")
                    RaTeXFormula(latex: #"F = ma"#, fontSize: fs, onError: { _ in })
                    Text("（单位：N = kg·m/s²）")
                }
            }

            Divider()

            // ── 示例 2：圆的几何量 ───────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Label("圆的几何量", systemImage: "circle")
                    .font(.caption.bold()).foregroundStyle(.secondary)

                FlowLayout(horizontalSpacing: 3, lineSpacing: 6) {
                    Text("半径为")
                    RaTeXFormula(latex: #"r"#,                   fontSize: fs, onError: { _ in })
                    Text("的圆：面积")
                    RaTeXFormula(latex: #"S = \pi r^2"#,         fontSize: fs, onError: { _ in })
                    Text("，周长")
                    RaTeXFormula(latex: #"C = 2\pi r"#,          fontSize: fs, onError: { _ in })
                    Text("，其中")
                    RaTeXFormula(latex: #"\pi \approx 3.14159"#, fontSize: fs, onError: { _ in })
                }
            }

            Divider()

            // ── 示例 3：一元二次方程的判别式 ─────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Label("一元二次方程的判别式", systemImage: "function")
                    .font(.caption.bold()).foregroundStyle(.secondary)

                FlowLayout(horizontalSpacing: 3, lineSpacing: 6) {
                    Text("判别式")
                    RaTeXFormula(latex: #"\Delta = b^2 - 4ac"#, fontSize: fs, onError: { _ in })
                    Text("决定根的个数：")
                    RaTeXFormula(latex: #"\Delta > 0"#,          fontSize: fs, onError: { _ in })
                    Text("两个不等实根，")
                    RaTeXFormula(latex: #"\Delta = 0"#,          fontSize: fs, onError: { _ in })
                    Text("重根，")
                    RaTeXFormula(latex: #"\Delta < 0"#,          fontSize: fs, onError: { _ in })
                    Text("无实数根")
                }
            }

            Divider()

            // ── 示例 4：机械能守恒 ───────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Label("机械能守恒", systemImage: "bolt.circle")
                    .font(.caption.bold()).foregroundStyle(.secondary)

                FlowLayout(horizontalSpacing: 3, lineSpacing: 6) {
                    Text("只有重力做功时，动能")
                    RaTeXFormula(latex: #"E_k"#,            fontSize: fs, onError: { _ in })
                    Text("与势能")
                    RaTeXFormula(latex: #"E_p"#,            fontSize: fs, onError: { _ in })
                    Text("之和守恒，即")
                    RaTeXFormula(latex: #"E_k + E_p = C"#, fontSize: fs, onError: { _ in })
                    Text("（C 为常量）")
                }
            }

            Divider()

            // ── 示例 5：行列式 ───────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Label("行列式", systemImage: "grid")
                    .font(.caption.bold()).foregroundStyle(.secondary)

                FlowLayout(horizontalSpacing: 3, lineSpacing: 8) {
                    Text("若")
                    RaTeXFormula(latex: #"A = \begin{vmatrix} a & b \\ c & d \end{vmatrix}"#, fontSize: fs, onError: { _ in })
                    Text("，则")
                    RaTeXFormula(latex: #"\det(A) = ad - bc"#, fontSize: fs, onError: { _ in })
                    Text("；3阶行列式")
                    RaTeXFormula(latex: #"B = \begin{vmatrix} a & b & c \\ d & e & f \\ g & h & i \end{vmatrix}"#, fontSize: fs, onError: { _ in })
                    Text("按第一行展开得")
                    RaTeXFormula(latex: #"\det(B) = a(ei-fh) - b(di-fg) + c(dh-eg)"#, fontSize: fs, onError: { _ in })
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 段落混排示例

/// 段落混排：散文段落中嵌入居中块级公式
struct BlockExamplesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // 示例 1：质能方程
            VStack(alignment: .leading, spacing: 8) {
                Label("质能方程", systemImage: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("爱因斯坦在狭义相对论中推导出：静止质量为 m 的物体，其静能为")
                    .fixedSize(horizontal: false, vertical: true)

                RaTeXFormula(latex: #"E = mc^2"#, fontSize: 28, onError: { _ in })
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)

                Text("其中 c ≈ 3×10⁸ m/s 为真空光速。该公式表明质量与能量可以相互转换，是核能利用的理论基础。")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            Divider()

            // 示例 2：麦克斯韦方程组
            VStack(alignment: .leading, spacing: 8) {
                Label("麦克斯韦方程组（积分形式）", systemImage: "wave.3.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("电磁场由以下四个方程完整描述：")

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(maxwellEquations, id: \.label) { eq in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(eq.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .trailing)
                            RaTeXFormula(latex: eq.latex, fontSize: 18, onError: { _ in })
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.vertical, 4)

            Divider()

            // 示例 3：泰勒展开
            VStack(alignment: .leading, spacing: 8) {
                Label("泰勒展开", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("函数 f(x) 在 x = a 处的泰勒级数展开为：")
                    .fixedSize(horizontal: false, vertical: true)

                RaTeXFormula(
                    latex: #"f(x) = \sum_{n=0}^{\infty} \frac{f^{(n)}(a)}{n!}(x-a)^n"#,
                    fontSize: 20,
                    onError: { _ in }
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)

                Text("常用展开：")

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(taylorExamples, id: \.name) { item in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(item.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                            RaTeXFormula(latex: item.latex, fontSize: 17, onError: { _ in })
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
    }

    private let maxwellEquations: [(label: String, latex: String)] = [
        ("高斯定律",   #"\oint \mathbf{E} \cdot d\mathbf{A} = \frac{Q}{\varepsilon_0}"#),
        ("磁高斯定律", #"\oint \mathbf{B} \cdot d\mathbf{A} = 0"#),
        ("法拉第定律", #"\oint \mathbf{E} \cdot d\mathbf{l} = -\frac{d\Phi_B}{dt}"#),
        ("安培定律",   #"\oint \mathbf{B} \cdot d\mathbf{l} = \mu_0 I + \mu_0\varepsilon_0 \frac{d\Phi_E}{dt}"#),
    ]

    private let taylorExamples: [(name: String, latex: String)] = [
        ("eˣ",    #"e^x = 1 + x + \frac{x^2}{2!} + \frac{x^3}{3!} + \cdots"#),
        ("sin x", #"\sin x = x - \frac{x^3}{3!} + \frac{x^5}{5!} - \cdots"#),
        ("cos x", #"\cos x = 1 - \frac{x^2}{2!} + \frac{x^4}{4!} - \cdots"#),
    ]
}

// MARK: - 推导过程示例

/// 推导过程：分步骤展示公式推导，文字与公式交替出现
struct DerivationView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("二次公式推导", systemImage: "graduationcap")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            ForEach(derivationSteps.indices, id: \.self) { i in
                let step = derivationSteps[i]
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(i + 1).")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .trailing)
                        Text(step.description)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let latex = step.latex {
                        RaTeXFormula(latex: latex, fontSize: 20, onError: { _ in })
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                            .padding(.leading, 26)
                    }
                }
                .padding(.vertical, 4)

                if i < derivationSteps.count - 1 {
                    Divider().padding(.leading, 26)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private struct Step {
        let description: String
        let latex: String?
    }

    private let derivationSteps: [Step] = [
        Step(
            description: "从标准形式出发",
            latex: #"ax^2 + bx + c = 0 \quad (a \neq 0)"#
        ),
        Step(
            description: "两边除以 a，使二次项系数为 1",
            latex: #"x^2 + \frac{b}{a}x + \frac{c}{a} = 0"#
        ),
        Step(
            description: "配方：将左侧凑成完全平方形式",
            latex: #"\left(x + \frac{b}{2a}\right)^2 = \frac{b^2 - 4ac}{4a^2}"#
        ),
        Step(
            description: "两边开平方（注意取 ±）",
            latex: #"x + \frac{b}{2a} = \pm\frac{\sqrt{b^2 - 4ac}}{2a}"#
        ),
        Step(
            description: "移项得到二次公式",
            latex: #"x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}"#
        ),
    ]
}

// MARK: - 单个公式 Cell（带错误显示）

struct RaTeXFormulaCell: View {
    let latex: String
    let fontSize: CGFloat

    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let err = errorMessage {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                // RaTeXFormula 来自 Sources/RaTeX/RaTeXView.swift
                RaTeXFormula(
                    latex: latex,
                    fontSize: fontSize,
                    onError: { e in errorMessage = e.localizedDescription }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: latex) { _ in errorMessage = nil }
    }
}

#Preview {
    ContentView()
}
