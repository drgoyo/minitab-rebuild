# Skill-Profil: Reliability & Time Series Analyst
Target Area: `backend/app/r_engine/reliability/weibull_time_series.R`

## 1. Parametrische Lebensdaueranalyse (CRITICAL TRAP)
- **Problem**: R's Überlebensanalyse (`library(survival); survreg(dist='weibull')`) schätzt standardmäßig ein *Accelerated Failure Time (AFT)*-Modell (Ausgabe von Intercept mu und Scale sigma der Log-Zeit). Minitab hingegen gibt die klassischen physikalischen Parameter der Weibull-Verteilung aus: Formparameter (Shape beta) und Skalenparameter (Scale alpha).
- **Lösungspflicht**: Nach der Modellanpassung muss zwingend eine mathematische Transformation durchgeführt werden:
  beta = 1 / sigma
  alpha = exp(mu)
  Diese Konvertierung kann manuell oder über das Paket `SurvRegCensCov::ConvertWeibull` erfolgen, um exakte Übereinstimmung mit Minitab zu garantieren.
- **Zensierung**: Volle Unterstützung für rechts-, links- und intervallzensierte Daten. Vorab-Bereinigung des Status-Vektors zu binären Integern (0 = zensiert, 1 = Ausfall) erzwingen.

## 2. Weitere Prognosewerkzeuge
- **Garantie-Vorhersagen**: Crow-AMSAA (Power Law) Modell zur Berechnung von Feldausfallraten.
- **Zeitreihenanalyse**: Mathematischer Kern für Trendanalysen, exponentielle Glättung und automatisierte ARIMA-Modellierung.
