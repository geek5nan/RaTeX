import React, {useState} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useColorScheme,
} from 'react-native';
import {RaTeXView} from 'ratex-react-native';

const FORMULAS = [
  {name: '二次方程', latex: String.raw`\frac{-b \pm \sqrt{b^2-4ac}}{2a}`},
  {name: '欧拉公式', latex: String.raw`e^{i\pi} + 1 = 0`},
  {name: '高斯积分', latex: String.raw`\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}`},
  {name: '级数', latex: String.raw`\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}`},
  {name: '矩阵', latex: String.raw`\begin{pmatrix}a & b \\ c & d\end{pmatrix}`},
  {name: 'Maxwell', latex: String.raw`\nabla \times \mathbf{B} = \mu_0 \mathbf{J}`},
];

export default function App() {
  const isDark = useColorScheme() === 'dark';
  const [custom, setCustom] = useState(String.raw`\frac{1}{\sqrt{2\pi}}`);
  const [fontSize, setFontSize] = useState(28);
  const [error, setError] = useState('');

  return (
    <SafeAreaView style={[styles.root, isDark && styles.dark]}>
      <StatusBar barStyle={isDark ? 'light-content' : 'dark-content'} />
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={[styles.title, isDark && styles.textLight]}>RaTeX Demo</Text>

        {/* Custom input */}
        <View style={styles.card}>
          <TextInput
            style={styles.input}
            value={custom}
            onChangeText={v => {
              setCustom(v);
              setError('');
            }}
            placeholder="输入 LaTeX..."
            autoCapitalize="none"
          />
          <View style={styles.sizeRow}>
            <TouchableOpacity onPress={() => setFontSize(f => Math.max(14, f - 2))}>
              <Text style={styles.btn}>−</Text>
            </TouchableOpacity>
            <Text style={styles.sizeLabel}>{fontSize}px</Text>
            <TouchableOpacity onPress={() => setFontSize(f => Math.min(48, f + 2))}>
              <Text style={styles.btn}>＋</Text>
            </TouchableOpacity>
          </View>
          {error ? <Text style={styles.err}>{error}</Text> : null}
          <RaTeXView
            latex={custom}
            fontSize={fontSize}
            style={styles.formula}
            onError={e => setError(e.nativeEvent.error)}
          />
        </View>

        {/* Preset formulas */}
        {FORMULAS.map(({name, latex}) => (
          <View key={name} style={styles.card}>
            <Text style={[styles.label, isDark && styles.textLight]}>{name}</Text>
            <RaTeXView latex={latex} fontSize={24} style={[styles.formula]} />
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1, backgroundColor: '#fff'},
  dark: {backgroundColor: '#111'},
  scroll: {padding: 16, gap: 12},
  title: {fontSize: 22, fontWeight: '700', marginBottom: 8, color: '#111'},
  textLight: {color: '#eee'},
  card: {backgroundColor: '#f5f5f5', borderRadius: 12, padding: 12},
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 8,
    fontFamily: 'monospace',
  },
  sizeRow: {flexDirection: 'row', alignItems: 'center', gap: 12, marginTop: 8},
  btn: {fontSize: 20, fontWeight: '600', paddingHorizontal: 10},
  sizeLabel: {fontSize: 14, color: '#555'},
  err: {color: 'red', marginTop: 4, fontSize: 12},
  formula: {marginTop: 8, width: '100%'},
  label: {fontSize: 13, color: '#555', marginBottom: 4},
});
