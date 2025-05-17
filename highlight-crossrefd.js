// When the user hovers on elements with class "crossrefd" or focuses
// on one of their descendants, we want the cross-referenced element
// to be styled differently to make the connection visible.

// The "data-crossref" attribute stores the class of the referenced
// elements, and we temporarily append the "crossrefd-focus" class to
// those referenced elements.

setfocus = (target) => {
    ref = target.attributes.getNamedItem("data-crossref").value
    refd = document.getElementsByClassName(ref)
    for (const e of refd) {
        e.classList.add("crossrefd-focus")
    }
}
unsetfocus = (target) => {
    ref = target.attributes.getNamedItem("data-crossref").value
    refd = document.getElementsByClassName(ref)
    for (const e of refd) {
        e.classList.remove("crossrefd-focus")
    }
}

setfocus_here   = (event) => {   setfocus(event.target) }
unsetfocus_here = (event) => { unsetfocus(event.target) }

setfocus_ancestor   = (event) => {
    setfocus(event.target.closest(".crossrefd"))
}
unsetfocus_ancestor = (event) => {
    unsetfocus(event.target.closest(".crossrefd"))
}

cr = document.getElementsByClassName("crossrefd")
for (const e of cr) {
    e.addEventListener("mouseenter", setfocus_here)
    e.addEventListener("mouseleave", unsetfocus_here)
}

focusable = document.querySelectorAll('a') // Add other when needed
for (const e of focusable) {
    e.addEventListener("focusin", setfocus_ancestor)
    e.addEventListener("focusout", unsetfocus_ancestor)
}
