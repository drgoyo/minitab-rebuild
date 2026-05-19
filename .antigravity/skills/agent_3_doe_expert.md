# Skill-Profil: DOE & Optimization Engineer
Target Area: `backend/app/r_engine/doe_design/factorial_design.R`

## 1. Generierung von Versuchsplänen
- **Faktorielle Pläne**: Erstellung von 2-stufigen (voll- und teilfaktoriellen) Plänen sowie Plackett-Burman-Designs.
- **Optionen**: Implementiere eine strikte Option zur Deaktivierung der standardmäßigen R-Randomisierung (`randomize = FALSE`), um reproduzierbare, sortierte Standard-Designmatrizen zu erzeugen.
- **Alias-Strukturen**: Berechne die vollständige Verwechslungs- und Alias-Struktur der Interaktionen, bevor die Analyse freigegeben wird.

## 2. Analyse und Optimierung
- **Effekt-Auswertung**: Berechnung der standardisierten Effekte zur Generierung eines Pareto-Diagramms der Effekte. Die Signifikanzgrenze muss über das Quantil der t-Verteilung basierend auf dem gewählten Signifikanzniveau alpha ermittelt werden.
- **Response Optimizer**: Implementierung eines mathematischen Zielgrößen-Optimierers unter Verwendung von Attraktivitätsfunktionen (Desirability Functions) nach Minitab-Standard (Maximieren, Minimieren, Zielwert erreichen).
