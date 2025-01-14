document.addEventListener("click", function (event) {
    const target = event.target;
    if (target.tagName === "SUMMARY" && target.parentElement.tagName === "DETAILS") {
        event.preventDefault(); // Prevent default behavior
        const details = target.parentElement;

        // Toggle the open state programmatically
        if (details.hasAttribute("open")) {
            details.removeAttribute("open");
        } else {
            details.setAttribute("open", "open");
        }
    }
});
