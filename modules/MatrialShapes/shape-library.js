.pragma library

.import "material-shapes.js" as M

var names = [
    "circle", "square", "slanted", "arch", "fan", "arrow", "semiCircle", "oval",
    "pill", "triangle", "diamond", "clamShell", "pentagon", "gem", "sunny", "verySunny",
    "cookie4", "cookie6", "cookie7", "cookie9", "cookie12", "ghostish", "clover4", "clover8",
    "burst", "softBurst", "boom", "softBoom", "flower", "puffy", "puffyDiamond", "pixelCircle",
    "pixelTriangle", "bun", "heart"
]

function get(name) {
    switch (name) {
    case "circle":        return M.getCircle()
    case "square":        return M.getSquare()
    case "slanted":       return M.getSlanted()
    case "arch":          return M.getArch()
    case "fan":           return M.getFan()
    case "arrow":         return M.getArrow()
    case "semiCircle":    return M.getSemiCircle()
    case "oval":          return M.getOval()
    case "pill":          return M.getPill()
    case "triangle":      return M.getTriangle()
    case "diamond":       return M.getDiamond()
    case "clamShell":     return M.getClamShell()
    case "pentagon":      return M.getPentagon()
    case "gem":           return M.getGem()
    case "sunny":         return M.getSunny()
    case "verySunny":     return M.getVerySunny()
    case "cookie4":       return M.getCookie4Sided()
    case "cookie6":       return M.getCookie6Sided()
    case "cookie7":       return M.getCookie7Sided()
    case "cookie9":       return M.getCookie9Sided()
    case "cookie12":      return M.getCookie12Sided()
    case "ghostish":      return M.getGhostish()
    case "clover4":       return M.getClover4Leaf()
    case "clover8":       return M.getClover8Leaf()
    case "burst":         return M.getBurst()
    case "softBurst":     return M.getSoftBurst()
    case "boom":          return M.getBoom()
    case "softBoom":      return M.getSoftBoom()
    case "flower":        return M.getFlower()
    case "puffy":         return M.getPuffy()
    case "puffyDiamond":  return M.getPuffyDiamond()
    case "pixelCircle":   return M.getPixelCircle()
    case "pixelTriangle": return M.getPixelTriangle()
    case "bun":           return M.getBun()
    case "heart":         return M.getHeart()
    }
    return null
}
