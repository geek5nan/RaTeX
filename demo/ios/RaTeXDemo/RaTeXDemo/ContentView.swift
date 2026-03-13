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
            }
            .navigationTitle("RaTeX Demo")
        }
    }
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
