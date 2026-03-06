(function () {
  "use strict";

  function replaceMermaidCodeBlocks() {
    var codeBlocks = document.querySelectorAll("code.language-mermaid");

    codeBlocks.forEach(function (codeBlock) {
      var source = (codeBlock.textContent || "").trim();
      if (!source) {
        return;
      }

      var container = document.createElement("div");
      container.className = "mermaid";
      container.textContent = source;

      var wrapper = codeBlock.closest("div.highlight");
      var pre = codeBlock.closest("pre");
      var target = wrapper || pre;

      if (target && target.parentNode) {
        target.parentNode.replaceChild(container, target);
      }
    });
  }

  function initMermaid() {
    if (typeof mermaid === "undefined") {
      return;
    }

    replaceMermaidCodeBlocks();

    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",
      theme: "neutral",
      flowchart: {
        htmlLabels: true
      }
    });

    mermaid.run({ querySelector: ".mermaid" }).catch(function (error) {
      console.error("Mermaid rendering error:", error);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initMermaid);
  } else {
    initMermaid();
  }
})();
