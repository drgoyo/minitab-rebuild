# Skill-Profil: Linear Models & Hypothesentests Expert
Target Area: backend/app/r_engine/linear_models/anova_regression.R

## 1. Globale System-Voraussetzung (CRITICAL TRAP)
Vor JEDER Modellanpassung (lm, aov, glm) in R MUSS zwingend die globale Kontrasteinstellung erzwungen werden:

options(contrasts = c('contr.sum', 'contr.poly'))

Hintergrund: R verwendet standardmäßig Behandlungs-Kontraste ('contr.treatment') und berechnet damit sequentielle Typ-I-Quadratsummen. Minitab hingegen fordert für unbalancierte Datensätze in ANOVA, GLM und Regression immer partielle Typ-III-Quadratsummen. Ohne diese globale Option weichen die berechneten P-Werte drastisch ab!

## 2. Funktionsumfang & Spezifikationen
- Deskriptive Kennzahlen: Berechnung von Mittelwert, Median, Varianz, Quartilen, Schiefe (Skewness) und Kurtosis exakt nach Minitab-Standard. Der Bericht soll analog zum 'Minitab Graphical Summary' aufgebaut sein.
- Hypothesentests: t-Tests (1-Stichprobe, 2-Stichproben, gepaart), Varianztests (F-Test, Levene-Test, Bartlett-Test) sowie Chi-Quadrat-Tests.
- Regressionsanalysen: Lineare und multiple Regression, schrittweise Verfahren (Stepwise, Forward, Backward) zur Variablen-Selektion sowie logistische (binär, ordinal, nominal) und Poisson-Regressionen.
- Varianzanalyse (ANOVA): Einfache und zweifache ANOVA, General Linear Model (GLM) für komplexe oder unbalancierte Versuchspläne sowie post-hoc-Mehrfachvergleiche (Tukey, Fisher, Dunnett oder Hsu).
- Nichtparametrische Verfahren: Vorzeichentest, Wilcoxon-Test, Mann-Whitney-Test und Kruskal-Wallis-Test.

## 3. Datenbereinigung & Fehlwerte
- Fehlende Werte (NA) müssen analog zu Minitab über ein striktes Listwise Deletion (Ausschluss des gesamten Falls im jeweiligen Modellschritt) behandelt werden (na.rm = TRUE bei Basiskennzahlen).
