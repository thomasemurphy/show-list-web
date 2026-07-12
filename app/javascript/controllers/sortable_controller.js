import { Controller } from "@hotwired/stimulus"

// How far (as a fraction of a row/column's size, measured from that slot's
// start) the dragged item's center must reach before it swaps into that
// slot. 0.5 = must reach the slot's midpoint (a full slot's worth of
// movement from its own start). 0 = swaps as soon as it crosses the
// boundary (half a slot's worth of movement) — the common "50% overlap"
// convention. Lower = swaps with less movement, but too low gets twitchy.
const SWAP_THRESHOLD = 0

// Drag-and-drop reordering for the dashboard table: band rows via the grip
// in each row header, zip columns via the grip in each column header.
//
// Uses pointer events (not HTML5 drag-and-drop) so the grabbed row/column
// can visually lift and continuously follow the cursor, while the other
// rows/columns slide smoothly out of the way (a simplified FLIP animation)
// instead of jumping. The DOM is only actually reordered once, on drop.
export default class extends Controller {
  static values = { bandsUrl: String, zipsUrl: String }

  startRow(event) {
    if (event.button !== 0) return
    const trs = [...this.element.querySelectorAll("tbody tr[data-band]")]
    const groups = trs.map((tr) => ({ cells: [...tr.cells], tr, key: tr.dataset.band }))
    const draggedTr = event.currentTarget.closest("tr")
    const draggedGroup = groups.find((g) => g.tr === draggedTr)
    this.beginDrag(event, { axis: "y", groups, draggedGroup, url: this.bandsUrlValue })
  }

  startColumn(event) {
    if (event.button !== 0) return
    const originTh = event.currentTarget.closest("th")
    const rows = [...this.element.rows]
    const groups = [...this.element.querySelectorAll("thead th[data-zip]")].map((zipTh) => {
      const idx = zipTh.cellIndex
      return { cells: rows.map((row) => row.cells[idx]).filter(Boolean), key: zipTh.dataset.zip }
    })
    const draggedGroup = groups.find((g) => g.cells.includes(originTh))
    this.beginDrag(event, { axis: "x", groups, draggedGroup, url: this.zipsUrlValue })
  }

  beginDrag(event, { axis, groups, draggedGroup, url }) {
    event.preventDefault()
    const handle = event.currentTarget
    handle.setPointerCapture(event.pointerId)

    const start = (el) => (axis === "y" ? el.getBoundingClientRect().top : el.getBoundingClientRect().left)
    const size = (el) => (axis === "y" ? el.getBoundingClientRect().height : el.getBoundingClientRect().width)

    const positions = groups.map((g) => start(g.cells[0]))
    const draggedSize = size(draggedGroup.cells[0])
    const draggedIndex = groups.indexOf(draggedGroup)
    const startPointer = axis === "y" ? event.clientY : event.clientX

    for (const el of draggedGroup.cells) el.classList.add("sortable-dragging")

    // order[slot] = original index of the group currently occupying that slot.
    let order = groups.map((_, i) => i)

    const applyTransforms = (offset) => {
      order.forEach((originalIndex, slot) => {
        const group = groups[originalIndex]
        const isDragged = originalIndex === draggedIndex
        const translate = isDragged ? offset : positions[slot] - positions[originalIndex]
        for (const el of group.cells) {
          el.style.transition = isDragged ? "none" : "transform 150ms ease"
          el.style.transform = translate ? `translate${axis === "y" ? "Y" : "X"}(${translate}px)` : ""
          if (isDragged) el.style.zIndex = "30"
        }
      })
    }

    const move = (e) => {
      const pointer = axis === "y" ? e.clientY : e.clientX
      const offset = pointer - startPointer
      const draggedCenter = positions[draggedIndex] + draggedSize / 2 + offset

      let newSlot = 0
      positions.forEach((pos, slot) => {
        if (draggedCenter > pos + draggedSize * SWAP_THRESHOLD) newSlot = slot
      })

      const curSlot = order.indexOf(draggedIndex)
      if (newSlot !== curSlot) {
        order.splice(curSlot, 1)
        order.splice(newSlot, 0, draggedIndex)
      }

      applyTransforms(offset)
    }

    const finish = () => {
      handle.removeEventListener("pointermove", move)
      handle.removeEventListener("pointerup", finish)
      handle.removeEventListener("pointercancel", finish)

      const finalGroups = order.map((i) => groups[i])
      for (const group of groups) {
        for (const el of group.cells) {
          el.style.transition = ""
          el.style.transform = ""
          el.style.zIndex = ""
        }
      }
      for (const el of draggedGroup.cells) el.classList.remove("sortable-dragging")

      this.commit(axis, finalGroups)
      this.persist(url, finalGroups.map((g) => g.key))
    }

    handle.addEventListener("pointermove", move)
    handle.addEventListener("pointerup", finish)
    handle.addEventListener("pointercancel", finish)
  }

  commit(axis, finalGroups) {
    if (axis === "y") {
      const tbody = finalGroups[0].tr.parentNode
      for (const group of finalGroups) tbody.appendChild(group.tr)
      const addRow = [...tbody.rows].find((tr) => !tr.dataset.band)
      if (addRow) tbody.appendChild(addRow)
    } else {
      const rows = [...this.element.rows]
      rows.forEach((row, r) => {
        const bandCell = row.cells[0]
        const groupCells = finalGroups.map((g) => g.cells[r]).filter(Boolean)
        const remaining = [...row.cells].filter((c) => c !== bandCell && !groupCells.includes(c))
        for (const cell of [bandCell, ...groupCells, ...remaining]) row.appendChild(cell)
      })
    }
  }

  persist(url, order) {
    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        Accept: "application/json",
      },
      body: JSON.stringify({ order }),
    })
  }
}
