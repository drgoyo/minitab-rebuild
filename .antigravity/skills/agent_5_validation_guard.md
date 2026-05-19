# Skill-Profil: Deterministischer Validierungs-Wächter
Target Area: `tests/` (Gilt übergreifend für das gesamte Projekt)

## Kernauftrag & Qualitäts-Gate
1. **Automatisierte Unit-Tests**: Generiere nach jeder Code-Änderung der anderen Agenten automatisierte Tests via `testthat` (für R) und `pytest` (für die Python-Datenbrücke).
2. **Referenz-Auditing**: Füttere die R-Berechnungsroutinen mit standardisierten QM-Datensätzen (z. B. aus den AIAG-SPC-Handbüchern oder verifizierten Minitab-Datensätzen).
3. **Harte Toleranzgrenze (< 1%)**: Vergleiche die berechneten statistischen Kennwerte (insbesondere Cp, Cpk, Pp, Ppk, p-Werte und Eingriffsgrenzen) mit den validierten Minitab-Sollwerten.
4. Wenn eine Abweichung >= 1% auftritt, muss der Test fehlschlagen, der Code verworfen und eine Fehlermeldung mit der exakten mathematischen Differenz ausgegeben werden.
