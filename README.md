YamlPoder helps me self-host my podcast.
It builds the RSS feed and I then use a web-server to make the feed as well as audio files publicly accessible. 

## Motivation
I host [a podcast](https://www.vanousek.com) where I interview the amazing people of this world about their passions and lives.
Most people don't realize this, but you don't upload the episodes of your podcast to every platform it's available on (Spotify, Apple Podcasts, Google Podcasts...).
The audio is hosted by a provider that charges you for their services.
Platforms then read all the information about the podcast from an RSS feed, display the information, and allow users to download the audio from the provider.

I decided to self-host my podcast, for the following reasons:
- Hosting of long form conversations is far from cheap -- around $100 a year.
- I owned a Raspberry Pi already and I live on campus with very good internet speed.
- It is a fun project.

## How it works
I have the folder with the individual episodes synced from my desktop to my Pi with open source backup software [Syncthing](https://syncthing.net/).
I call this folder where I edit individual episodes `content_root`.
This is what it looks like:
```
voi/
├── profile.png
├── podcast.yaml
├── eps
│   ├── 0001-Štěpán-Riethof
│   │   ├── ep.aup
│   │   ├── ep.mp3
│   │   └── ep.yaml
│   ├── 0002-Alex-Gilman
│   │   ├── ep.aup
│   │   ├── ep.mp3
│   │   └── ep.yaml
    ⋮
│   └── 0017-Jáchym-Rauš
│       ├── ep.aup
│       ├── ep.mp3
│       └── ep.yaml
⋮
```

Besides the audio files (`.mp3`) and audacity files (`.aup`),
I include all other information to be displayed in the `.yaml` files in `podcast.yaml` and I include the information that is necessary for building the feed.
All the things about the podcast and individual episodes you can see in Spotify is contained here.

`podcast.yaml` describes the entire show:
```yaml
episodes_directory: eps # Relative path to the directory that contains all the episodes
logo: profile.png # Relative path to the picture to be used as cover art for the podcast
output_root: /var/www # The web directory that will be served by web server. 
url_base: https://pi.vanousek.com # The url the web server is accessible on.
category: Technology # The itunes category
rss: # RSS tags, as described here https://support.google.com/podcast-publishers/answer/9889544?hl=en
  title: Voice of Miki Vanoušek
  link: https://www.vanousek.com
  description:
    Deep conversations with the awesome people of this world about their passions and lives.
    How did they define success and how they reached it?
    Listen every other Sunday!
  language: en
  copyright: © 2022 Miki Vanoušek – Licensed under CC BY-SA 4.0
  "itunes:owner":
    "itunes:email": vanousekmikulas+voice@gmail.com
  "itunes:author": Miki Vanoušek
  "itunes:explicit": yes
```

Individual episodes have information about them in the directory name (episode number and guest) and the `ep.yaml`:
```yaml
pubdate: 25-9-22 # The day the episode was released in the dd-mm-yy format
hook: Dance, Sex and Dating # Hook is used to create the title of the episode: `#0017 Jáchym Rauš: Dance, Sex and Dating`
description: Jáchym Rauš is a top-level competitive dancer and one of my dearest friends. Enjoy! # Info about this episode.
```

This script then generates the following in `output_root`:
```
/var/www
├── eps
│   ├── 0001
│   │   └── ep.mp3 -> /home/miki/voi/eps/0001-Štěpán-Riethof/ep.mp3
│   ├── 0002
│   │   └── ep.mp3 -> /home/miki/voi/eps/0002-Alex-Gilman/ep.mp3
│   ├── 0003
│   │   └── ep.mp3 -> /home/miki/voi/eps/0003-Kryštof-Mitka/ep.mp3
│   ├── 0004
│   │   └── ep.mp3 -> /home/miki/voi/eps/0004-Joe-Osborne/ep.mp3
│   ├── 0005
│   │   └── ep.mp3 -> /home/miki/voi/eps/0005-Chris-Albanese/ep.mp3
│   ├── 0006
│   │   └── ep.mp3 -> /home/miki/voi/eps/0006-Andreas-Kohl-Martines/ep.mp3
│   ├── 0007
│   │   └── ep.mp3 -> /home/miki/voi/eps/0007-Scott-Beibin/ep.mp3
│   ├── 0008
│   │   └── ep.mp3 -> /home/miki/voi/eps/0008-Vít-Jedlička/ep.mp3
│   ├── 0009
│   │   └── ep.mp3 -> /home/miki/voi/eps/0009-Bibi-Stevens/ep.mp3
│   ├── 0011
│   │   └── ep.mp3 -> /home/miki/voi/eps/0011-Gerard-Bel-Catala/ep.mp3
│   ├── 0012
│   │   └── ep.mp3 -> /home/miki/voi/eps/0012-Bart-Sprenkles/ep.mp3
│   ├── 0013
│   │   └── ep.mp3 -> /home/miki/voi/eps/0013-Nelly-Litvak/ep.mp3
│   ├── 0014
│   │   └── ep.mp3 -> /home/miki/voi/eps/0014-Bill-Cohn/ep.mp3
│   ├── 0015
│   │   └── ep.mp3 -> /home/miki/voi/eps/0015-Káťa-Homolková/ep.mp3
│   ├── 0016
│   │   └── ep.mp3 -> /home/miki/voi/eps/0016-Christoff-Heunis/ep.mp3
│   └── 0017
│       └── ep.mp3 -> /home/miki/voi/eps/0017-Jáchym-Rauš/ep.mp3
├── profile.png -> /home/miki/voi/profile.png
└── rss.xml
```


## Usage

1. Make `output_root` directory with correct permissions. (Your web server needs to be able to read it!)
2. Install julia packages:
```sh
julia -e 'import Pkg; Pkg.add("YAML"); Pkg.add("LightXML")'
```
3. Run the script:
```sh
julia yaml_poder.jl -- [content_root] [-f]
```
By default, `content_root` is the directory you run the script from.
If you want to skip the confirmation dialog for deleting everything in `output_root`, add `-f` (as in force).