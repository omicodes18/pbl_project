// Forensic Gait Presentation Console Controller
document.addEventListener("DOMContentLoaded", () => {
  const resultView = document.getElementById("resultView");
  const terminalView = document.getElementById("terminalView");
  const tabWaveformBtn = document.getElementById("tabWaveformBtn");
  const tabTerminalBtn = document.getElementById("tabTerminalBtn");
  const backToWaveformBtn = document.getElementById("backToWaveformBtn");

  const showWaveform = () => {
    if (resultView && terminalView) {
      terminalView.classList.remove("is-active");
      resultView.classList.add("is-active");
      if (tabWaveformBtn) tabWaveformBtn.classList.add("is-active");
      if (tabTerminalBtn) tabTerminalBtn.classList.remove("is-active");
    }
  };

  const showTerminal = () => {
    if (resultView && terminalView) {
      resultView.classList.remove("is-active");
      terminalView.classList.add("is-active");
      if (tabTerminalBtn) tabTerminalBtn.classList.add("is-active");
      if (tabWaveformBtn) tabWaveformBtn.classList.remove("is-active");
    }
  };

  if (tabWaveformBtn) tabWaveformBtn.addEventListener("click", showWaveform);
  if (tabTerminalBtn) tabTerminalBtn.addEventListener("click", showTerminal);
  if (backToWaveformBtn) backToWaveformBtn.addEventListener("click", showWaveform);
});
