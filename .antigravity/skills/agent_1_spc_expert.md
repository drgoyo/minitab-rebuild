# Skill-Profil: SPC & Quality Tools Expert (Minitab Core Rebuild)
Target Area: `backend/app/r_engine/spc_quality/sixpack_engine.R`

## 1. Mathematische Kern-Algorithmen (Minitab Exact Alignment)
### A. Prozessfähigkeit (Normalverteilt)
- **Potential Capability ($C_p, C_{pk}$)**: Schätzung über die Streuung *innerhalb* der Untergruppen ($\hat{\sigma}_{within}$).
  - *Untergruppengröße $n = 1$*: Schätzung über die durchschnittliche gleitende Spannweite (Moving Range) von 2 aufeinanderfolgenden Werten: $\hat{\sigma}_{within} = \overline{MR} / d_2$, wobei $d_2 = 1.128$.
  - *Untergruppengröße $n > 1$*: Schätzung standardmäßig über die gepoolte Standardabweichung: $\hat{\sigma}_{within} = S_p / c_4(d+1)$, oder alternativ über die R-Bar-Methode: $\hat{\sigma}_{within} = \bar{R} / d_2$.
- **Overall Performance ($P_p, P_{pk}$)**: Schätzung über die Gesamtstreuung des Prozesses ($\hat{\sigma}_{overall}$). Berechnung über die empirische Standardabweichung mit Freiheitsgrad $n-1$: $\hat{\sigma}_{overall} = \sqrt{\sum(x - \bar{x})^2 / (n-1)}$.
- **Formeln**:
  - $C_p = (USL - LSL) / (6 \cdot \hat{\sigma}_{within})$
  - $C_{pk} = \min((USL - \bar{x}) / (3 \cdot \hat{\sigma}_{within}), (\bar{x} - LSL) / (3 \cdot \hat{\sigma}_{within}))$
  - $P_p = (USL - LSL) / (6 \cdot \hat{\sigma}_{overall})$
  - $P_{pk} = \min((USL - \bar{x}) / (3 \cdot \hat{\sigma}_{overall}), (\bar{x} - LSL) / (3 \cdot \hat{\sigma}_{overall}))$

### B. Regelkarten & Stabilitäts-Tests (Nelson / Western Electric Rules)
- **Test 1**: Ein Punkt liegt weiter als 3 Standardabweichungen von der Mittellinie entfernt ($> UCL$ oder $< LCL$).
- **Test 2**: 9 aufeinanderfolgende Punkte liegen auf derselben Seite der Mittellinie. *R-Logik*: Implementierung via `rle(x > x_bar)` und Auswertung von `lengths >= 9`.
- **Test 3**: 6 aufeinanderfolgende Punkte steigen oder fallen kontinuierlich. *R-Logik*: Prüfung auf Vorzeichenkontinuität der Differenzen via `diff(x)`.

## 2. Datenübergabe
Alle Arrays (Rohdaten, berechnete Eingriffsgrenzen UCL/LCL, Trendlinien, geflaggte Verletzungspunkte und Anderson-Darling P-Werte via `nortest::ad.test`) müssen als flache, benannte Listen exportiert werden.
