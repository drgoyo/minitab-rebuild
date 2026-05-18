"""
backend/app/visualization/sixpack_visualizer.py

Dieses Modul ist verantwortlich für die interaktive Plotly-Visualisierung
eines Minitab-äquivalenten Capability Sixpacks. Die statistischen Kennwerte
werden direkt aus der R-Engine bezogen und defensiv geparst.
"""

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from typing import TypedDict, List, Optional, Any, Set

class REngineOutput(TypedDict):
    """Typdefinition für die erwartete R-Eingangsstruktur."""
    raw_data: List[float]
    center_line: float
    ucl: float
    lcl: float
    sigma_within: float
    sigma_overall: float
    cp: Optional[float]
    cpk: Optional[float]
    pp: Optional[float]
    ppk: Optional[float]
    test1_violations: List[int]
    test2_violations: List[int]
    test3_violations: List[int]
    anderson_darling_pvalue: Optional[float]
    normality_test_used: str

class SixpackVisualizer:
    """
    Erstellt ein interaktives 3x2 Plotly Dashboard für das Capability Sixpack.
    Folgt strikt den Minitab-Visualisierungsstandards für Six Sigma.
    """

    def __init__(self, data: REngineOutput, lsl: Optional[float] = None, 
                 usl: Optional[float] = None, target: Optional[float] = None):
        self._validate_input(data)
        
        # Extrahieren und Bereinigen von NaN Werten
        raw_series = pd.Series(data["raw_data"])
        self.raw_data = raw_series.dropna().to_numpy()
        self.n = len(self.raw_data)
        
        self.center_line = data["center_line"]
        self.ucl = data["ucl"]
        self.lcl = data["lcl"]
        self.sigma_within = data["sigma_within"]
        self.sigma_overall = data["sigma_overall"]
        self.cp = data.get("cp")
        self.cpk = data.get("cpk")
        self.pp = data.get("pp")
        self.ppk = data.get("ppk")
        self.ad_pvalue = data.get("anderson_darling_pvalue")
        self.normality_test = data.get("normality_test_used", "None")
        
        # 1-basierte R-Indizes in 0-basierte Python-Indizes umwandeln
        self.violations_t1 = [i - 1 for i in data.get("test1_violations", []) if i > 0]
        self.violations_t2 = [i - 1 for i in data.get("test2_violations", []) if i > 0]
        self.violations_t3 = [i - 1 for i in data.get("test3_violations", []) if i > 0]
        self.all_violations: Set[int] = set(self.violations_t1 + self.violations_t2 + self.violations_t3)
        
        self.lsl = lsl
        self.usl = usl
        self.target = target

    def _validate_input(self, data: REngineOutput) -> None:
        """Prüft die Integrität der R-Struktur auf fehlende Keys."""
        required_keys = [
            "raw_data", "center_line", "ucl", "lcl", 
            "sigma_within", "sigma_overall"
        ]
        missing = [key for key in required_keys if key not in data]
        if missing:
            raise ValueError(f"Incomplete R-Engine Output. Missing keys: {missing}")

    def _get_marker_colors(self) -> List[str]:
        """Liefert die Farbcodes für normale vs. out-of-control Punkte."""
        return ["red" if i in self.all_violations else "blue" for i in range(self.n)]

    def _add_i_chart(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 1: I-Chart / X-quer-Chart."""
        indices = np.arange(1, self.n + 1)
        colors = self._get_marker_colors()
        
        fig.add_trace(go.Scatter(
            x=indices, y=self.raw_data, mode='lines+markers', 
            name='Value', marker=dict(color=colors, size=6), line=dict(color='blue')
        ), row=row, col=col)
        
        fig.add_hline(y=self.center_line, line_color="green", line_width=2, 
                      annotation_text=f"X_bar={self.center_line:.3f}", row=row, col=col)
        fig.add_hline(y=self.ucl, line_color="red", line_dash="dash", 
                      annotation_text=f"UCL={self.ucl:.3f}", row=row, col=col)
        fig.add_hline(y=self.lcl, line_color="red", line_dash="dash", 
                      annotation_text=f"LCL={self.lcl:.3f}", row=row, col=col)
        
        fig.update_xaxes(title_text="Observation", row=row, col=col)
        fig.update_yaxes(title_text="Value", row=row, col=col)

    def _add_mr_chart(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 2: MR-Chart / Moving Range Chart."""
        mr_data = np.abs(np.diff(self.raw_data))
        mr_indices = np.arange(2, self.n + 1)
        
        mr_bar = float(np.mean(mr_data)) if len(mr_data) > 0 else 0.0
        mr_ucl = 3.267 * mr_bar  # D4 für n=2
        mr_lcl = 0.0             # D3 für n=2
        
        fig.add_trace(go.Scatter(
            x=mr_indices, y=mr_data, mode='lines+markers', 
            name='Moving Range', marker=dict(color='blue', size=6), line=dict(color='blue')
        ), row=row, col=col)
        
        fig.add_hline(y=mr_bar, line_color="green", line_width=2, 
                      annotation_text=f"MR_bar={mr_bar:.3f}", row=row, col=col)
        fig.add_hline(y=mr_ucl, line_color="red", line_dash="dash", 
                      annotation_text=f"UCL={mr_ucl:.3f}", row=row, col=col)
        fig.add_hline(y=mr_lcl, line_color="red", line_dash="dash", 
                      annotation_text="LCL=0", row=row, col=col)
        
        fig.update_xaxes(title_text="Observation", row=row, col=col)
        fig.update_yaxes(title_text="Moving Range", row=row, col=col)

    def _add_run_chart(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 3: Run Chart der letzten 25 Beobachtungen."""
        n_last = min(25, self.n)
        last_data = self.raw_data[-n_last:]
        indices = np.arange(self.n - n_last + 1, self.n + 1)
        median_val = float(np.median(last_data)) if n_last > 0 else 0.0
        
        fig.add_trace(go.Scatter(
            x=indices, y=last_data, mode='lines+markers', 
            name='Last 25 Obs', marker=dict(color='gray', size=6), line=dict(color='gray')
        ), row=row, col=col)
        
        fig.add_hline(y=median_val, line_color="black", line_dash="dot", 
                      annotation_text=f"Median={median_val:.3f}", row=row, col=col)
        
        fig.update_xaxes(title_text="Observation", row=row, col=col)
        fig.update_yaxes(title_text="Value", row=row, col=col)

    def _add_capability_histogram(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 4: Capability Histogramm (Within/Overall & Spezifikationen)."""
        fig.add_trace(go.Histogram(
            x=self.raw_data, histnorm='probability density', 
            name='Density', marker_color='lightblue', opacity=0.7
        ), row=row, col=col)
        
        x_min, x_max = np.min(self.raw_data), np.max(self.raw_data)
        if self.lsl is not None and self.usl is not None:
            x_min = min(x_min, self.lsl)
            x_max = max(x_max, self.usl)
        
        x_grid = np.linspace(x_min - self.sigma_overall, x_max + self.sigma_overall, 200)
        
        if self.sigma_overall > 0:
            pdf_overall = (1 / (self.sigma_overall * np.sqrt(2 * np.pi))) * np.exp(-0.5 * ((x_grid - self.center_line) / self.sigma_overall)**2)
            fig.add_trace(go.Scatter(x=x_grid, y=pdf_overall, mode='lines', name='Overall', line=dict(color='black', dash='dash')), row=row, col=col)
            
        if self.sigma_within > 0:
            pdf_within = (1 / (self.sigma_within * np.sqrt(2 * np.pi))) * np.exp(-0.5 * ((x_grid - self.center_line) / self.sigma_within)**2)
            fig.add_trace(go.Scatter(x=x_grid, y=pdf_within, mode='lines', name='Within', line=dict(color='red')), row=row, col=col)

        if self.lsl is not None:
            fig.add_vline(x=self.lsl, line_color="red", line_width=2, line_dash="solid", annotation_text="LSL", row=row, col=col)
        if self.usl is not None:
            fig.add_vline(x=self.usl, line_color="red", line_width=2, line_dash="solid", annotation_text="USL", row=row, col=col)
        if self.target is not None:
            fig.add_vline(x=self.target, line_color="green", line_width=2, line_dash="dash", annotation_text="Target", row=row, col=col)

        fig.update_xaxes(title_text="Data", row=row, col=col)
        fig.update_yaxes(title_text="Density", row=row, col=col)

    def _approximate_inverse_normal(self, p: np.ndarray) -> np.ndarray:
        """Approximation für die inverse Normalverteilung."""
        c0, c1, c2 = 2.515517, 0.802853, 0.010328
        d1, d2, d3 = 1.432788, 0.189269, 0.001308
        
        is_less_half = p < 0.5
        q = np.where(is_less_half, p, 1 - p)
        t = np.sqrt(-2.0 * np.log(q))
        
        num = c0 + c1*t + c2*t**2
        den = 1.0 + d1*t + d2*t**2 + d3*t**3
        x = t - num / den
        
        return np.where(is_less_half, -x, x)

    def _add_probability_plot(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 5: Normal Probability Plot (Wahrscheinlichkeitsnetz)."""
        sorted_data = np.sort(self.raw_data)
        p = (np.arange(1, self.n + 1) - 0.375) / (self.n + 0.25)
        z_theo = self._approximate_inverse_normal(p)
        
        fig.add_trace(go.Scatter(
            x=sorted_data, y=z_theo, mode='markers', 
            name='Prob Plot', marker=dict(color='blue', size=6)
        ), row=row, col=col)
        
        if self.sigma_overall > 0:
            p1, p2 = np.percentile(sorted_data, [25, 75])
            z1, z2 = self._approximate_inverse_normal(np.array([0.25, 0.75]))
            slope = (z2 - z1) / (p2 - p1) if p2 != p1 else 1
            intercept = z1 - slope * p1
            
            x_line = np.array([np.min(sorted_data), np.max(sorted_data)])
            y_line = slope * x_line + intercept
            fig.add_trace(go.Scatter(
                x=x_line, y=y_line, mode='lines', name='Normal Ref', line=dict(color='red')
            ), row=row, col=col)

        p_val_text = f"P-Value: {self.ad_pvalue:.3f}" if self.ad_pvalue is not None else "P-Value: N/A"
        test_info = f"Test: {self.normality_test}"
        
        fig.add_annotation(
            xref=f"x{col+(row-1)*2}", yref=f"y{col+(row-1)*2}",
            x=0.05, y=0.95, text=f"{test_info}<br>{p_val_text}",
            showarrow=False, align="left", xanchor="left", yanchor="top"
        )
        
        fig.update_xaxes(title_text="Data", row=row, col=col)
        fig.update_yaxes(title_text="Theoretical Quantiles", row=row, col=col)

    def _add_capability_metrics(self, fig: go.Figure, row: int, col: int) -> None:
        """Chart 6: Capability Plot (Textmetriken Cp, Cpk, Pp, Ppk)."""
        def fmt(val: Optional[float]) -> str:
            return f"{val:.2f}" if val is not None and not np.isnan(val) else "*"
            
        metrics_html = f"""
        <b>Within (Short-Term Capability)</b><br>
        Cp:  {fmt(self.cp)}<br>
        Cpk: {fmt(self.cpk)}<br>
        <br>
        <b>Overall (Long-Term Performance)</b><br>
        Pp:  {fmt(self.pp)}<br>
        Ppk: {fmt(self.ppk)}<br>
        """
        
        fig.add_trace(go.Scatter(
            x=[0.5], y=[0.5], mode="text",
            text=[metrics_html], textposition="middle center",
            hoverinfo="none", showlegend=False
        ), row=row, col=col)
        
        fig.update_xaxes(visible=False, row=row, col=col)
        fig.update_yaxes(visible=False, row=row, col=col)

    def render(self) -> go.Figure:
        """Baut das Grid auf und liefert die fertige interaktive Plotly Figure."""
        fig = make_subplots(
            rows=3, cols=2,
            subplot_titles=(
                "I Chart", "Capability Histogram", 
                "Moving Range Chart", "Normal Probability Plot", 
                "Last 25 Observations", "Capability Metrics"
            )
        )

        self._add_i_chart(fig, row=1, col=1)
        self._add_capability_histogram(fig, row=1, col=2)
        
        self._add_mr_chart(fig, row=2, col=1)
        self._add_probability_plot(fig, row=2, col=2)
        
        self._add_run_chart(fig, row=3, col=1)
        self._add_capability_metrics(fig, row=3, col=2)

        fig.update_layout(
            title_text="Process Capability Sixpack",
            title_x=0.5, margin=dict(l=50, r=50, t=80, b=50),
            plot_bgcolor="white", showlegend=False, hovermode="closest",
            autosize=True  # Responsive ohne fixe Pixel-Angaben
        )
        
        fig.update_xaxes(showline=True, linewidth=1, linecolor='lightgray', gridcolor='lightgray')
        fig.update_yaxes(showline=True, linewidth=1, linecolor='lightgray', gridcolor='lightgray')

        return fig
