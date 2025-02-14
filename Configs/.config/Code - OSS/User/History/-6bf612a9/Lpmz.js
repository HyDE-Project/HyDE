// latte / frappe / macchiato / mocha
const palette = mocha;

const default_config = {
  overrideStorage: true,
  temperature: {
    location: "Takengon",
    scale: "C",
  },
  clock: {
    format: "h:i p",
    iconColor: palette.maroon,
  },
  disabled: [],
  fastlink: "https://github.com/Niumination",
  openLastVisitedTab: false,
  tabs: [
    {
      name: "NIUMINATION",
      background_url: "src/img/banners/window-room.png",
      categories: [
        {
          name: "media",
          links: [
            {
              name: "FB",
              url: "https://facebook.com",
              icon: "brand-facebook",
              icon_color: palette.blue,
            },
            {
              name: "X",
              url: "https://x.com",
              icon: "brand-x",
              icon_color: palette.sky,
            },
            {
              name: "RED",
              url: "https://www.reddit.com/",
              icon: "brand-reddit",
              icon_color: palette.teal,
            },
            {
              name: "YT",
              url: "https://www.youtube.com/",
              icon: "brand-youtube",
              icon_color: palette.red,
            },
            {
              name: "IG",
              url: "https://www.instagram.com/",
              icon: "brand-instagram",
              icon_color: palette.sapphire,
            },
            {
              name: "TB",
              url: "https://dm.terabox.app/",
              icon: "cloud-down",
              icon_color: palette.sky,
            },
            {
              name: "OD",
              url: "https://virtualeducationacademy-my.sharepoint.com/",
              icon: "brand-onedrive",
              icon_color: palette.lavender,
            },
            {
              name: "WA",
              url: "https://web.whatsapp.com/",
              icon: "brand-whatsapp",
              icon_color: palette.green,
            },            
          ],
        },
        {
          name: "Dinas",
          links: [
            {
              name: "SPBE",
              url: "https://tauval.spbe.go.id/",
              icon: "home-move",
              icon_color: palette.flamingo,
            },
            {
              name: "Kinerja",
              url: "https://kinerja.bkn.go.id/",
              icon: "stretching",
              icon_color: palette.rosewater,
            },
            {
              name: "MyASN",
              url: "https://myasn.bkn.go.id/",
              icon: "accessible",
              icon_color: palette.mauve,
            },
          ],
        },
        {
          name: "Shopping",
          links: [
            {
              name: "Oren",
              url: "https://shopee.co.id/",
              icon: "brand-shopee",
              icon_color: palette.maroon,
            },
            {
              name: "Toped",
              url: "https://www.tokopedia.com/",
              icon: "shopping-bag",
              icon_color: palette.green,
            },
          ],
        },
        {
          name: "Watching",
          links: [
            {
              name: "AC",
              url: "https://anichin.dev",
              icon: "brand-intercom",
              icon_color: palette.teal,
            },
            {
              name: "AX",
              url: "https://anixverse.com",
              icon: "brand-zhihu",
              icon_color: palette.yellow,
            },
            {
              name: "AK",
              url: "https://www.animekompi.vip",
              icon: "time-duration-30",
              icon_color: palette.mauve,
            },
            {
              name: "LK",
              url: "https://tv.lk21official.my",
              icon: "shopping-bag",
              icon_color: palette.rosewater,
            },
          ],
        },
      ],
    },
    {
      name: "dev",
      background_url: "src/img/banners/retro-mario.png",
      categories: [
        {
          name: "media",
          links: [
            {
              name: "github",
              url: "https://github.com",
              icon: "brand-github",
              icon_color: palette.green,
            },
            {
              name: "dev-community",
              url: "https://dev.to/",
              icon: "article",
              icon_color: palette.peach,
            },
            {
              name: "dotfyle",
              url: "https://dotfyle.com/",
              icon: "puzzle",
              icon_color: palette.blue,
            },
            {
              name: "vercel",
              url: "https://vercel.com/dashboard",
              icon: "brand-vercel",
              icon_color: palette.blue,
            },
          ],
        },
        {
          name: "learn",
          links: [
            {
              name: "leetcode",
              url: "https://leetcode.com",
              icon: "code-plus",
              icon_color: palette.green,
            },
            {
              name: "hacker-news",
              url: "https://news.ycombinator.com/ask",
              icon: "news",
              icon_color: palette.mauve,
            },
            {
              name: "stackoverflow",
              url: "https://stackoverflow.com",
              icon: "brand-stackoverflow",
              icon_color: palette.peach,
            },
            {
              name: "w3schools",
              url: "https://www.w3schools.com/",
              icon: "school",
              icon_color: palette.red,
            },
            {
              name: "exercism",
              url: "https://exercism.org/",
              icon: "calculator",
              icon_color: palette.blue,
            },
          ],
        },
        {
          name: "tools",
          links: [
            {
              name: "regex101",
              url: "https://regex101.com/",
              icon: "regex",
              icon_color: palette.green,
            },
            {
              name: "hoopscotch",
              url: "https://hoppscotch.io/",
              icon: "api",
              icon_color: palette.peach,
            },
            {
              name: "searchcode",
              url: "https://searchcode.com/",
              icon: "zoom-code",
              icon_color: palette.red,
            },
            {
              name: "codepen",
              url: "https://codepen.io/",
              icon: "brand-codepen",
              icon_color: palette.blue,
            },
            {
              name: "readme.so",
              url: "https://readme.so/editor",
              icon: "book-2",
              icon_color: palette.mauve,
            },
            {
              name: "postgres-new",
              url: "https://postgres.new/",
              icon: "database",
              icon_color: palette.sky,
            },
            {
              name: "penpot",
              url: "https://penpot.app/",
              icon: "edit-circle",
              icon_color: palette.lavender,
            },
            {
              name: "jsoncrack",
              url: "https://jsoncrack.com/editor",
              icon: "info-square-rounded",
              icon_color: palette.flamingo,
            },
            {
              name: "it-tools",
              url: "https://it-tools.tech/",
              icon: "tools",
              icon_color: palette.pink,
            },
          ],
        },
        {
          name: "docs",
          links: [
            {
              name: "devdocs",
              url: "https://devdocs.io/",
              icon: "books",
              icon_color: palette.green,
            },
            {
              name: "mdn",
              url: "https://developer.mozilla.org/en-US/",
              icon: "brand-firefox",
              icon_color: palette.peach,
            },
            {
              name: "cheatsheets",
              url: "https://cheatsheets.zip/",
              icon: "file-spreadsheet",
              icon_color: palette.red,
            },
          ],
        },
      ],
    },
    {
      name: "watching",
      background_url: "src/img/banners/doom-slayer.png",
      categories: [
        {
          name: "anime & donghua",
          links: [
            {
              name: "anichin.dev",
              url: "https://anichin.dev",
              icon: "brand-intercom",
              icon_color: palette.green,
            },
            {
              name: "anixverse.com",
              url: "https://anixverse.com",
              icon: "brand-zhihu",
              icon_color: palette.peach,
            },
            {
              name: "animekompi.vip",
              url: "https://www.animekompi.vip",
              icon: "time-duration-30",
              icon_color: palette.red,
            },
            {
              name: "lk21",
              url: "https://tv.lk21official.my",
              icon: "shopping-bag",
              icon_color: palette.red,
            },
          ],
        },
      ],
    },
    {
      name: "music",
      background_url: "src/img/banners/lofi.jpg",
      categories: [
        {
          name: "listen",
          links: [
            {
              name: "spotify",
              url: "https://open.spotify.com",
              icon: "brand-spotify",
              icon_color: palette.green,
            },
            {
              name: "soundcloud",
              url: "https://www.soundcloud.com",
              icon: "brand-soundcloud",
              icon_color: palette.peach,
            },
            {
              name: "youtube-music",
              url: "https://music.youtube.com/",
              icon: "brand-youtube",
              icon_color: palette.red,
            },
            {
              name: "tidal",
              url: "https://listen.tidal.com/",
              icon: "brand-tidal",
              icon_color: palette.blue,
            },
            {
              name: "genius",
              url: "https://genius.com/",
              icon: "abc",
              icon_color: palette.mauve,
            },
          ],
        },
        {
          name: "rating/tracking",
          links: [
            {
              name: "AOTY",
              url: "https://www.albumoftheyear.org/",
              icon: "calendar-time",
              icon_color: palette.green,
            },
            {
              name: "rateyourmusic",
              url: "https://rateyourmusic.com/",
              icon: "stars-off",
              icon_color: palette.peach,
            },
            {
              name: "lastfm",
              url: "https://www.last.fm",
              icon: "brand-lastfm",
              icon_color: palette.red,
            },
            {
              name: "listenbrainz",
              url: "https://listenbrainz.org",
              icon: "ear",
              icon_color: palette.blue,
            },
          ],
        },
        {
          name: "discussion",
          links: [
            {
              name: "r/musicproduction",
              url: "https://www.reddit.com/r/musicproduction/",
              icon: "device-speaker",
              icon_color: palette.green,
            },
            {
              name: "r/hiphopheads",
              url: "https://www.reddit.com/r/hiphopheads/",
              icon: "headphones",
              icon_color: palette.peach,
            },
            {
              name: "r/audiophile",
              url: "https://www.reddit.com/r/audiophile/",
              icon: "ear",
              icon_color: palette.red,
            },
            {
              name: "r/music",
              url: "https://www.reddit.com/r/music/",
              icon: "music-heart",
              icon_color: palette.blue,
            },
            {
              name: "r/metal",
              url: "https://www.reddit.com/r/metal/",
              icon: "guitar-pick",
              icon_color: palette.mauve,
            },
          ],
        },
        {
          name: "resources",
          links: [
            {
              name: "freesound",
              url: "https://freesound.org/",
              icon: "volume",
              icon_color: palette.green,
            },
            {
              name: "pluginboutique",
              url: "https://www.pluginboutique.com/",
              icon: "building-store",
              icon_color: palette.peach,
            },
            {
              name: "pianobook",
              url: "https://www.pianobook.co.uk",
              icon: "piano",
              icon_color: palette.red,
            },
            {
              name: "musescore",
              url: "https://musescore.com/",
              icon: "numbers",
              icon_color: palette.blue,
            },
            {
              name: "songsterr",
              url: "https://www.songsterr.com/",
              icon: "vinyl",
              icon_color: palette.mauve,
            },
          ],
        },
      ],
    },
    {
      name: "art",
      background_url: "src/img/banners/sky.png",
      categories: [
        {
          name: "media",
          links: [
            {
              name: "unsplash",
              url: "https://unsplash.com",
              icon: "brand-unsplash",
              icon_color: palette.green,
            },
            {
              name: "pixiv",
              url: "https://www.pixiv.net/en/",
              icon: "artboard",
              icon_color: palette.peach,
            },
            {
              name: "pinterest",
              url: "https://www.pinterest.com/",
              icon: "brand-pinterest",
              icon_color: palette.red,
            },
            {
              name: "artstation",
              url: "https://www.artstation.com",
              icon: "pencil-heart",
              icon_color: palette.blue,
            },
          ],
        },
        {
          name: "palettes",
          links: [
            {
              name: "catppuccin",
              url: "https://catppuccin.com/",
              icon: "heart",
              icon_color: palette.green,
            },
            {
              name: "nord",
              url: "https://www.nordtheme.com/",
              icon: "brand-nord-vpn",
              icon_color: palette.peach,
            },
            {
              name: "dracula",
              url: "https://draculatheme.com/",
              icon: "bat",
              icon_color: palette.red,
            },
            {
              name: "rose-pine",
              url: "https://rosepinetheme.com/",
              icon: "flower",
              icon_color: palette.blue,
            },
          ],
        },
        {
          name: "tools",
          links: [
            {
              name: "convert-image-palette",
              url: "https://farbenfroh.io/",
              icon: "adjustments",
              icon_color: palette.green,
            },
            {
              name: "excalidraw",
              url: "https://excalidraw.com/",
              icon: "pencil",
              icon_color: palette.peach,
            },
            {
              name: "squoosh",
              url: "https://squoosh.app/",
              icon: "aspect-ratio",
              icon_color: palette.red,
            },
            {
              name: "palette-generator",
              url: "https://colpat.itsvg.in/dashboard",
              icon: "palette",
              icon_color: palette.blue,
            },
            {
              name: "color-picker",
              url: "https://htmlcolorcodes.com/color-picker/",
              icon: "color-picker",
              icon_color: palette.mauve,
            },
          ],
        },
      ],
    },
    {
      name: "tools",
      background_url: "src/img/banners/tokyo.png",
      categories: [
        {
          name: "general",
          links: [
            {
              name: "alternative-to",
              url: "https://alternativeto.net/",
              icon: "box-multiple",
              icon_color: palette.green,
            },
            {
              name: "deepl",
              url: "https://www.deepl.com",
              icon: "language",
              icon_color: palette.peach,
            },
            {
              name: "monkeytype",
              url: "https://monkeytype.com/",
              icon: "keyboard",
              icon_color: palette.red,
            },
            {
              name: "dub",
              url: "https://dub.co/",
              icon: "external-link",
              icon_color: palette.blue,
            },
            {
              name: "speed-test",
              url: "https://librespeed.org/",
              icon: "brand-speedtest",
              icon_color: palette.mauve,
            },
            {
              name: ".to",
              url: "https://rentry.co/tosites",
              icon: "arrow-loop-right",
              icon_color: palette.sky,
            },
            {
              name: "cloudconvert",
              url: "https://cloudconvert.com/",
              icon: "transform",
              icon_color: palette.lavender,
            },
            {
              name: "is-it-down",
              url: "https://downforeveryoneorjustme.com/",
              icon: "server-off",
              icon_color: palette.flamingo,
            },
            {
              name: "selfh.st",
              url: "https://selfh.st/",
              icon: "server-2",
              icon_color: palette.pink,
            },
          ],
        },
        {
          name: "piracy",
          links: [
            {
              name: "fmhy",
              url: "https://fmhy.net/",
              icon: "barrier-block",
              icon_color: palette.green,
            },
            {
              name: "megathread",
              url: "https://rentry.org/megathread",
              icon: "skull",
              icon_color: palette.peach,
            },

            {
              name: "mobilism",
              url: "https://forum.mobilism.me/",
              icon: "device-mobile",
              icon_color: palette.red,
            },
          ],
        },
        {
          name: "privacy",
          links: [
            {
              name: "adblock-test",
              url: "https://d3ward.github.io/toolz/adblock.html",
              icon: "lock-access",
              icon_color: palette.green,
            },
            {
              name: "privacy-guides",
              url: "https://www.privacyguides.org/en/",
              icon: "arrow-guide",
              icon_color: palette.peach,
            },
            {
              name: "r/privacy",
              url: "https://www.reddit.com/r/privacy/",
              icon: "door-off",
              icon_color: palette.red,
            },
            {
              name: "guerrilla-mail",
              url: "https://www.guerrillamail.com",
              icon: "trash",
              icon_color: palette.blue,
            },
            {
              name: "cleanurl",
              url: "https://12ft.io/",
              icon: "spray",
              icon_color: palette.mauve,
            },
          ],
        },
        {
          name: "security",
          links: [
            {
              name: "cybersecurity-guide",
              url: "https://s0cm0nkey.gitbook.io/s0cm0nkeys-security-reference-guide",
              icon: "fingerprint",
              icon_color: palette.green,
            },
            {
              name: "virus-total",
              url: "https://www.virustotal.com",
              icon: "virus-search",
              icon_color: palette.peach,
            },
            {
              name: "hackthebox",
              url: "https://www.hackthebox.com/",
              icon: "biohazard",
              icon_color: palette.red,
            },
            {
              name: "triage",
              url: "https://tria.ge/",
              icon: "dna-2",
              icon_color: palette.blue,
            },
            {
              name: "cyberchef",
              url: "https://gchq.github.io/CyberChef/",
              icon: "chef-hat",
              icon_color: palette.mauve,
            },
            {
              name: "web-check",
              url: "https://web-check.xyz/",
              icon: "search",
              icon_color: palette.sky,
            },
          ],
        },
        {
          name: "ai",
          links: [
            {
              name: "chatgpt",
              url: "https://chatgpt.com/",
              icon: "brand-openai",
              icon_color: palette.green,
            },
            {
              name: "huggingface",
              url: "https://huggingface.co/",
              icon: "robot",
              icon_color: palette.peach,
            },
            {
              name: "open-webui",
              url: "http://127.0.0.1:8080/",
              icon: "message-chatbot",
              icon_color: palette.red,
            },
          ],
        },
      ],
    },
  ],
};

const CONFIG = new Config(default_config, palette);

const root = document.querySelector(":root");
root.style.setProperty("--bg", palette.mantle);
root.style.setProperty("--accent", palette.green);
