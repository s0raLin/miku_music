import app from "ags/gtk4/app"
import style from "./style.scss"
import DynamicIsland from "./widget/DynamicIsland"

app.start({
  css: style,
  main() {
    app.get_monitors().map(DynamicIsland)
  },
})
