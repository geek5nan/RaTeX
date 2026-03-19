package io.ratex.demo

import android.os.Bundle
import android.text.Editable
import android.text.SpannableStringBuilder
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ratex.RaTeXException
import io.ratex.RaTeXSpan
import io.ratex.RaTeXView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // ── 独立公式示例 ──────────────────────────────────────────────────────────
    private val formulas = listOf(
        "二次方程" to """\frac{-b \pm \sqrt{b^2-4ac}}{2a}""",
        "欧拉公式" to """e^{i\pi} + 1 = 0""",
        "高斯积分" to """\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}""",
        "巴塞尔级数" to """\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}""",
        "矩阵" to """\begin{pmatrix}a & b \\ c & d\end{pmatrix}""",
        "Maxwell 安培定律" to """\nabla \times \mathbf{B} = \mu_0\left(\mathbf{J} + \varepsilon_0\frac{\partial \mathbf{E}}{\partial t}\right)""",
        "二项式定理" to """(x+y)^n = \sum_{k=0}^{n} \binom{n}{k} x^k y^{n-k}""",
        "傅里叶变换" to """\hat{f}(\xi) = \int_{-\infty}^{\infty} f(x)\,e^{-2\pi i x \xi}\,dx""",
        "薛定谔方程" to """i\hbar\frac{\partial}{\partial t}\Psi = \hat{H}\Psi""",
        "爱因斯坦场方程" to """G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4}T_{\mu\nu}""",
        "Gamma 函数" to """\Gamma(z) = \int_0^{\infty} t^{z-1}e^{-t}\,dt""",
        "留数定理" to """\oint_C f(z)\,dz = 2\pi i \sum_k \operatorname{Res}(f,z_k)""",
        "黎曼 Zeta 函数" to """\zeta(s) = \sum_{n=1}^{\infty}\frac{1}{n^s} = \prod_p \frac{1}{1-p^{-s}}""",
        "Bessel 函数" to """J_n(x) = \frac{1}{\pi}\int_0^{\pi}\cos(n\tau - x\sin\tau)\,d\tau""",
        "Stokes 定理" to """\oint_{\partial\Sigma}\mathbf{F}\cdot d\mathbf{r} = \iint_{\Sigma}(\nabla\times\mathbf{F})\cdot d\mathbf{S}""",
        "拉普拉斯变换" to """\mathcal{L}\{f(t)\} = \int_0^{\infty} f(t)\,e^{-st}\,dt""",
    )

    // ── 行内混排：(前缀, LaTeX, 后缀)，公式作为 Span 嵌入 TextView 自然流排 ──
    private val inlineFormulas = listOf(
        // 单行紧凑公式，前后均有文字
        Triple("黄金比例 φ = ", """\frac{1+\sqrt{5}}{2}""", " ≈ 1.618，广泛存在于自然界与艺术之中。"),
        Triple("由勾股定理 ", """a^2 + b^2 = c^2""", " 可直接求得直角三角形斜边长度。"),
        Triple("当 x > 0 时，", """\frac{d}{dx}\ln x = \frac{1}{x}""", " 在整个正实轴上处处成立。"),
        Triple("复数模长 |z| = ", """\sqrt{a^2+b^2}""", "，其中 z = a + bi 为复数的代数形式。"),
        Triple("当 n→∞ 时，", """\left(1+\frac{1}{n}\right)^n""", " 收敛于自然常数 e ≈ 2.71828。"),
        Triple("计算积分 ", """\int_0^{\pi}\sin x\,dx""", " = 2，这是一个基本的定积分结果。"),
        Triple("展开 ", """\sum_{k=0}^{n}\binom{n}{k}x^k y^{n-k}""", " 即得完整的二项式定理。"),
        // 高个公式（含分式/矩阵/积分），前后均有文字
        Triple("重要极限：", """\lim_{x \to 0} \frac{\sin x}{x}""", " = 1，是三角函数极限的基础结论。"),
        Triple("令换元 t = ", """\frac{x-\mu}{\sigma}""", "，可将一般正态积分化为标准正态形式。"),
        Triple("行列式 det(A) = ", """\begin{vmatrix}a & b \\ c & d\end{vmatrix}""", " = ad − bc，是线性代数的核心量。"),
        Triple("斯特林近似：", """n! \approx \sqrt{2\pi n}\left(\frac{n}{e}\right)^n""", "，n 越大相对误差越小，在组合数学中广泛使用。"),
        Triple("正态密度 p(x) = ", """\frac{1}{\sigma\sqrt{2\pi}}\,e^{-\frac{(x-\mu)^2}{2\sigma^2}}""", "，其中 μ 为均值，σ 为标准差。"),
        Triple("柯西不等式：", """\left|\sum_k a_k b_k\right|^2 \le \sum_k a_k^2\cdot\sum_k b_k^2""", "，等号当且仅当两序列成比例时成立。"),
        Triple("格林公式 ", """\oint_C (P\,dx+Q\,dy) = \iint_D\!\left(\frac{\partial Q}{\partial x}-\frac{\partial P}{\partial y}\right)dA""", " 将曲线积分转化为二重积分。"),
    )

    // ── 多行公式混排：(描述文字, 显示公式) ────────────────────────────────
    private val multilineFormulas = listOf(
        "含时薛定谔方程描述量子态的时间演化，其中 Ĥ 为哈密顿算符：" to
            """i\hbar\frac{\partial}{\partial t}\Psi(\mathbf{r},t) = \left[-\frac{\hbar^2}{2m}\nabla^2 + V(\mathbf{r},t)\right]\Psi(\mathbf{r},t)""",

        "麦克斯韦方程组（微分形式），法拉第感应定律与安培-麦克斯韦定律：" to
            """\nabla \times \mathbf{E} = -\frac{\partial \mathbf{B}}{\partial t}, \quad \nabla \times \mathbf{B} = \mu_0\mathbf{J} + \mu_0\varepsilon_0\frac{\partial \mathbf{E}}{\partial t}""",

        "广义相对论爱因斯坦场方程，左侧为时空曲率，右侧为能量-动量张量：" to
            """R_{\mu\nu} - \frac{1}{2}R\,g_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4}T_{\mu\nu}""",

        "不可压缩 Navier-Stokes 方程，描述粘性流体运动：" to
            """\rho\!\left(\frac{\partial \mathbf{v}}{\partial t} + \mathbf{v}\cdot\nabla\mathbf{v}\right) = -\nabla p + \mu\nabla^2\mathbf{v} + \mathbf{f}""",

        "泰勒级数展开（麦克劳林形式），f 在 0 处任意阶可微时成立：" to
            """f(x) = \sum_{n=0}^{\infty}\frac{f^{(n)}(0)}{n!}x^n = f(0) + f'(0)x + \frac{f''(0)}{2!}x^2 + \cdots""",

        "欧拉-拉格朗日方程，变分法中使作用量取极值的条件：" to
            """\frac{\partial \mathcal{L}}{\partial q} - \frac{d}{dt}\frac{\partial \mathcal{L}}{\partial \dot{q}} = 0""",

        "路径积分（费曼形式），描述量子系统传播子：" to
            """\langle x_f,t_f \mid x_i,t_i \rangle = \int \mathcal{D}[x(t)]\,\exp\!\left(\frac{i}{\hbar}\int_{t_i}^{t_f}\mathcal{L}\,dt\right)""",

        "黎曼 ζ 函数满足以下函数方程（反射公式）：" to
            """\zeta(s) = 2^s\pi^{s-1}\sin\!\left(\frac{\pi s}{2}\right)\Gamma(1-s)\,\zeta(1-s)""",
    )

    private val defaultLatex = """\frac{d}{dx}\left[\int_a^x f(t)\,dt\right] = f(x)"""
    private val fontSizeDp = 22f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val density = resources.displayMetrics.scaledDensity
        var fontSizePx = fontSizeDp * density

        val customLatex = findViewById<android.widget.EditText>(R.id.customLatex)
        val fontSizeLabel = findViewById<TextView>(R.id.fontSizeLabel)
        val fontSizeSeekBar = findViewById<SeekBar>(R.id.fontSizeSeekBar)
        val customMathView = findViewById<RaTeXView>(R.id.customMathView)
        val formulaExamplesContainer = findViewById<LinearLayout>(R.id.formulaExamplesContainer)
        val inlineMixContainer = findViewById<LinearLayout>(R.id.inlineMixContainer)
        val multilineMixContainer = findViewById<LinearLayout>(R.id.multilineMixContainer)

        customLatex.setText(defaultLatex)
        updateFontSizeLabel(fontSizeLabel, fontSizeSeekBar.progress)
        customMathView.onError = { e: RaTeXException ->
            Toast.makeText(this, e.message, Toast.LENGTH_SHORT).show()
        }
        customMathView.fontSize = fontSizePx
        customMathView.latex = customLatex.text.toString()

        customLatex.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                customMathView.latex = s?.toString() ?: ""
            }
        })

        fontSizeSeekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                updateFontSizeLabel(fontSizeLabel, progress)
                fontSizePx = progress * density
                customMathView.fontSize = fontSizePx
                customMathView.latex = customLatex.text.toString()
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })

        // ── 独立公式示例 ──────────────────────────────────────────────────
        for ((name, latex) in formulas) {
            formulaExamplesContainer.addView(makeSectionLabel(name))
            formulaExamplesContainer.addView(makeMathView(latex, fontSizeDp * density))
        }

        // ── 行内混排（公式作为 Span 嵌入 TextView） ───────────────────────
        for ((prefix, latex, suffix) in inlineFormulas) {
            addInlineRow(inlineMixContainer, prefix, latex, suffix, fontSizeDp * density)
        }

        // ── 多行公式混排 ──────────────────────────────────────────────────
        for ((description, latex) in multilineFormulas) {
            multilineMixContainer.addView(makeDescriptionLabel(description))
            multilineMixContainer.addView(makeCenteredMathView(latex, fontSizeDp * density))
            multilineMixContainer.addView(makeDivider())
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    // ── 行内混排：异步渲染公式 Bitmap，通过 ReplacementSpan 嵌入 TextView ──

    /**
     * 将 [prefix] + 公式 + [suffix] 拼成一个 TextView 行。
     * 公式渲染为 Bitmap 后作为 [FormulaSpan] 嵌入 SpannableString，
     * 文字与公式在同一 TextView 中自然流式排布，超出宽度时整体换行，
     * 公式基线与文字基线自动对齐。
     */
    private fun addInlineRow(
        container: LinearLayout,
        prefix: String,
        latex: String,
        suffix: String,
        sizePx: Float,
    ) {
        val tv = TextView(this).apply {
            text = "$prefix…$suffix"          // 占位文字，渲染完成后替换
            setTextAppearance(android.R.style.TextAppearance_Medium)
            setPadding(0, dp(8f), 0, dp(8f))
            setLineSpacing(dp(6f).toFloat(), 1f)
        }
        container.addView(tv)

        scope.launch {
            try {
                val span = RaTeXSpan.create(this@MainActivity, latex, sizePx)
                val ssb = SpannableStringBuilder()
                if (prefix.isNotEmpty()) ssb.append(prefix)
                val spanStart = ssb.length
                ssb.append("\u200B") // 零宽占位符，挂载 Span
                ssb.setSpan(span, spanStart, ssb.length, 0)
                if (suffix.isNotEmpty()) ssb.append(suffix)
                tv.text = ssb
            } catch (e: Exception) {
                tv.text = "$prefix [渲染失败] $suffix"
            }
        }
    }

    // ── 通用 UI 构建 helpers ───────────────────────────────────────────────

    private fun dp(value: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    private fun makeSectionLabel(text: String) = TextView(this).apply {
        this.text = text
        setTextAppearance(android.R.style.TextAppearance_Small)
        setPadding(0, dp(12f), 0, dp(4f))
    }

    private fun makeDescriptionLabel(text: String) = TextView(this).apply {
        this.text = text
        setTextAppearance(android.R.style.TextAppearance_Medium)
        setPadding(0, dp(12f), 0, dp(6f))
        setLineSpacing(0f, 1.3f)
    }

    private fun makeMathView(latex: String, sizePx: Float) = RaTeXView(this).apply {
        this.latex = latex
        this.fontSize = sizePx
        onError = { e: RaTeXException ->
            Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun makeCenteredMathView(latex: String, sizePx: Float): LinearLayout {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, dp(4f), 0, dp(4f))
        }
        container.addView(makeMathView(latex, sizePx))
        return container
    }

    private fun makeDivider() = android.view.View(this).apply {
        layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(0.5f)).also {
            it.topMargin = dp(8f)
        }
        setBackgroundColor(0x22000000)
    }

    private fun updateFontSizeLabel(label: TextView, pt: Int) {
        label.text = getString(R.string.font_size_label, pt)
    }
}
