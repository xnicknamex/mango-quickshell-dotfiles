import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Media player control via MPRIS. One source of truth for the bar entry,
// its popup and the mango keybinds:
// qs ipc call media <playPause|previous|next|seekBack|seekForward>
// Controlled player: the pinned one (chosen in the bar popup), otherwise
// the first playing player, otherwise the first one found.
Scope {
    id: media
    readonly property real seekStep: 10

    readonly property var players: [...Mpris.players.values]
    // Set by the bar popup; null = auto
    property MprisPlayer pinned: null
    // A pinned player that has closed no longer counts
    readonly property bool isPinned: pinned !== null && players.includes(pinned)
    readonly property MprisPlayer player: isPinned
        ? pinned
        : (players.find(p => p.isPlaying) ?? players[0] ?? null)

    // "Artist – Title", "Title", or the player name if nothing is playing
    function title(p) {
        if (!p)
            return "";
        if (!p.trackTitle)
            return p.identity;
        return p.trackArtist ? `${p.trackArtist} – ${p.trackTitle}` : p.trackTitle;
    }

    // "Spotify — Artist – Title", or just the player name
    function describe(p) {
        return p.trackTitle ? `${p.identity} — ${title(p)}` : p.identity;
    }

    function playPause(p) {
        if (p?.canTogglePlaying)
            p.togglePlaying();
    }

    function previous(p) {
        if (p?.canGoPrevious)
            p.previous();
    }

    function next(p) {
        if (p?.canGoNext)
            p.next();
    }

    function seek(p, offset) {
        if (p?.canSeek)
            p.seek(offset);
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            media.playPause(media.player);
        }

        function previous(): void {
            media.previous(media.player);
        }

        function next(): void {
            media.next(media.player);
        }

        function seekBack(): void {
            media.seek(media.player, -media.seekStep);
        }

        function seekForward(): void {
            media.seek(media.player, media.seekStep);
        }
    }
}
