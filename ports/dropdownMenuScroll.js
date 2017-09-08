function registerDropdownMenuScrollPort(elmApp) {
  elmApp.ports.dropdownMenuScroll.subscribe(scrollIntoView)


  function scrollIntoView(elementId) {

    const element = document.getElementById(elementId)
    const parentElement = element && element.parentElement

    if (element && parentElement) {
      const elementRect = element.getBoundingClientRect()
      const parentRect = parentElement.getBoundingClientRect()

      if (elementRect.top < parentRect.top) {
        parentElement.scrollTop -= parentRect.top - elementRect.top
      }

      if (elementRect.bottom > parentRect.bottom) {
        parentElement.scrollTop += elementRect.bottom - parentRect.bottom
      }
    }
  }
}
