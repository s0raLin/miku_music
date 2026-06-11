import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import { createState, createComputed } from "ags"

// Poll playerctl metadata every second
const metadata = createPoll(
  "",
  1000,
  [
    "bash",
    "-c",
    `playerctl -a metadata --format '{{status}}|{{mpris:artUrl}}|{{title}}|{{artist}}|{{mpris:length}}|{{position}}' 2>/dev/null || echo "Stopped|||||0|0"`,
  ],
)

// Derived reactive values
const status = createComputed(() => metadata().split("|")[0] || "Stopped")
const coverUrl = createComputed(() => metadata().split("|")[1] || "")
const trackTitle = createComputed(() => metadata().split("|")[2] || "No Track")
const trackArtist = createComputed(() => metadata().split("|")[3] || "Unknown Artist")
const trackLength = createComputed(() => {
  const len = parseInt(metadata().split("|")[4])
  return len > 0 ? len / 1_000_000 : 1
})
const trackPosition = createComputed(() => {
  const pos = parseInt(metadata().split("|")[5])
  return pos > 0 ? pos / 1_000_000 : 0
})
const isPlaying = createComputed(() => status() === "Playing")
const hasPlayer = createComputed(() => status() !== "Stopped")

function formatTime(seconds: number): string {
  if (seconds <= 0) return "0:00"
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}:${secs.toString().padStart(2, "0")}`
}

const timeCurrent = createComputed(() => formatTime(trackPosition()))
const timeTotal = createComputed(() => formatTime(trackLength()))

const [expanded, setExpanded] = createState(false)

function collapse() {
  setExpanded(false)
}

function toggle() {
  setExpanded(!expanded())
}

function playPause() {
  execAsync(["playerctl", "play-pause"]).catch(() => {})
}

function previous() {
  execAsync(["playerctl", "previous"]).catch(() => {})
}

function next() {
  execAsync(["playerctl", "next"]).catch(() => {})
}

export default function DynamicIsland(gdkmonitor: Gdk.Monitor) {
  const { TOP } = Astal.WindowAnchor

  return (
    <window
      visible
      name="dynamic-island"
      class="DynamicIsland"
      gdkmonitor={gdkmonitor}
      anchor={TOP}
      exclusivity={Astal.Exclusivity.NORMAL}
      application={app}
      layer={Astal.Layer.OVERLAY}
    >
      <box class="island-wrapper" halign={Gtk.Align.CENTER}>
        {/* ============ COMPACT VIEW ============ */}
        <button
          class="compact-view"
          onClicked={toggle}
          visible={expanded.as((v) => !v)}
          sensitive={hasPlayer}
        >
          <box spacing={8}>
            <image
              class="compact-cover"
              file={coverUrl}
              iconName={hasPlayer.as((h) => (h ? "" : "audio-x-generic-symbolic"))}
              pixelSize={24}
            />
            <label
              class="compact-title"
              label={hasPlayer.as((h) => (h ? trackTitle() : "No Music Playing"))}
              maxWidthChars={20}
              ellipsize={3}
            />
            <image
              class="compact-status-icon"
              iconName={hasPlayer.as((h) =>
                h
                  ? isPlaying()
                    ? "media-playback-start-symbolic"
                    : "media-playback-pause-symbolic"
                  : "audio-volume-muted-symbolic",
              )}
              pixelSize={14}
            />
            <box
              class="audio-visualizer"
              spacing={2}
              visible={isPlaying}
            >
              <box class="vis-bar v1" valign={Gtk.Align.END} />
              <box class="vis-bar v2" valign={Gtk.Align.END} />
              <box class="vis-bar v3" valign={Gtk.Align.END} />
              <box class="vis-bar v4" valign={Gtk.Align.END} />
            </box>
          </box>
        </button>

        {/* ============ EXPANDED VIEW ============ */}
        <box
          class="expanded-view"
          orientation={Gtk.Orientation.VERTICAL}
          visible={expanded}
          spacing={16}
        >
          <image
            class="expanded-cover"
            file={coverUrl}
            iconName="audio-x-generic-symbolic"
            pixelSize={180}
            halign={Gtk.Align.CENTER}
          />
          <box
            orientation={Gtk.Orientation.VERTICAL}
            spacing={4}
            halign={Gtk.Align.CENTER}
          >
            <label
              class="track-title"
              label={hasPlayer.as((h) => (h ? trackTitle() : "No Music Playing"))}
              maxWidthChars={28}
              ellipsize={3}
              halign={Gtk.Align.CENTER}
            />
            <label
              class="track-artist"
              label={hasPlayer.as((h) => (h ? trackArtist() : "Open a media player to get started"))}
              maxWidthChars={28}
              ellipsize={3}
              halign={Gtk.Align.CENTER}
            />
          </box>
          <box
            orientation={Gtk.Orientation.VERTICAL}
            class="progress-section"
            spacing={4}
          >
            <slider
              class="progress-slider"
              value={trackPosition}
              min={0}
              max={trackLength}
              onChangeValue={({ value }: { value: number }) => {
                execAsync(["playerctl", "position", String(Math.floor(value * 1_000_000))]).catch(
                  () => {},
                )
              }}
              drawValue
              sensitive={hasPlayer}
            />
            <box class="time-labels">
              <label class="time-current" label={hasPlayer.as((h) => (h ? timeCurrent() : "--:--"))} />
              <box hexpand />
              <label class="time-total" label={hasPlayer.as((h) => (h ? timeTotal() : "--:--"))} />
            </box>
          </box>
          <box class="controls" halign={Gtk.Align.CENTER} spacing={16}>
            <button class="control-btn" onClicked={previous} sensitive={hasPlayer}>
              <image iconName="media-skip-backward-symbolic" pixelSize={24} />
            </button>
            <button class="play-pause-btn" onClicked={playPause} sensitive={hasPlayer}>
              <image
                iconName={isPlaying.as((p) =>
                  p ? "media-playback-pause-symbolic" : "media-playback-start-symbolic",
                )}
                pixelSize={36}
              />
            </button>
            <button class="control-btn" onClicked={next} sensitive={hasPlayer}>
              <image iconName="media-skip-forward-symbolic" pixelSize={24} />
            </button>
          </box>
          <button class="collapse-btn" onClicked={collapse} halign={Gtk.Align.CENTER}>
            <image iconName="go-up-symbolic" pixelSize={14} />
          </button>
        </box>
      </box>
    </window>
  )
}
