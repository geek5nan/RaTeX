package io.ratex.demo

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ratex.RaTeXException
import io.ratex.RaTeXView

class MainActivity : AppCompatActivity() {

    private val formulas = listOf(
        "二次方程" to """\frac{-b \pm \sqrt{b^2-4ac}}{2a}""",
        "欧拉公式" to """e^{i\pi} + 1 = 0""",
        "高斯积分" to """\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}""",
        "级数" to """\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}""",
        "矩阵" to """\begin{pmatrix}a & b \\ c & d\end{pmatrix}""",
        "Maxwell" to """\nabla \times \mathbf{B} = \mu_0 \mathbf{J}""",
        "二项式" to """(x+y)^n = \sum_{k=0}^n \binom{n}{k} x^k y^{n-k}""",
        "中线符号" to """\left( \frac{a}{b} \middle| \frac{c}{d} \right)""",
    )

    private val defaultLatex = """\frac{d}{dx}\left[\int_a^x f(t)\,dt\right] = f(x)"""
    private val fontSizeDp = 22f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 字体由 RaTeXView 首次渲染时通过 ensureLoaded() 从 assets/fonts 自动加载，无需在此手动调用
        setContentView(R.layout.activity_main)

        val density = resources.displayMetrics.scaledDensity
        var fontSizePx = fontSizeDp * density

        val customLatex = findViewById<android.widget.EditText>(R.id.customLatex)
        val fontSizeLabel = findViewById<TextView>(R.id.fontSizeLabel)
        val fontSizeSeekBar = findViewById<SeekBar>(R.id.fontSizeSeekBar)
        val customMathView = findViewById<RaTeXView>(R.id.customMathView)
        val formulaExamplesContainer = findViewById<LinearLayout>(R.id.formulaExamplesContainer)

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

        for ((name, latex) in formulas) {
            val title = TextView(this).apply {
                text = name
                setTextAppearance(android.R.style.TextAppearance_Small)
                setPadding(0, TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 12f, resources.displayMetrics).toInt(), 0, TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 4f, resources.displayMetrics).toInt())
            }
            val mathView = RaTeXView(this).apply {
                this.latex = latex
                this.fontSize = fontSizeDp * density
                onError = { e: RaTeXException ->
                    Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
                }
            }
            formulaExamplesContainer.addView(title)
            formulaExamplesContainer.addView(mathView)
        }
    }

    private fun updateFontSizeLabel(label: TextView, pt: Int) {
        label.text = getString(R.string.font_size_label, pt)
    }
}
