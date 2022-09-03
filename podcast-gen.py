import feedgen.feed as fg, yaml, os, re

def read_yaml_file(location):
    with open(location, "r") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(f'Failed to parse {location} yaml file.')

def call_setters(object, properties):
    for key, value in properties.items():
        if not hasattr(object, key):
            raise Exception(f'Invalid podcast feed property {key}')
        setter = getattr(object, key)
        setter(value)

def parse_episodes(episodes_root, feed_generator, output_root, url_base):
    regex = '\d{4}([-]\w*)+'
    pattern = re.compile(regex)

    for episode_dir_name in sorted(os.listdir(episodes_root)):
        if not pattern.match(episode_dir_name):
            print(f'WARNING: Skipping {episode_dir_name}, it does not match the {regex}'
                + ' regular expression pattern')
            continue
        if not os.path.exists(os.path.join(episodes_root, episode_dir_name, 'ep.mp3')):
            print(f'WARNING: Skipping {episode_dir_name}, it does not contain ep.mp3')
            continue
        episode_properties_location = os.path.join(episodes_root, episode_dir_name, 'ep.yaml')
        if not os.path.exists(episode_properties_location):
            print(f'WARNING: Skipping {episode_dir_name}, it does not contain ep.yaml')
            continue

        name_components = episode_dir_name.split('-')
        guest_name = ' '.join(name_components[1:])
        print(f'Adding episode #{name_components[0]} with {guest_name}')

        episode_properties = read_yaml_file(episode_properties_location)
        fe = feed_generator.add_entry()
        fe.id(f'{url_base}/eps/{name_components[0]}')
        fe.title(f'#{name_components[0]}{guest_name}: {episode_properties}')
        # fe.link(href="http://lernfunk.de/feed")

        destination_directory = os.path.join(output_root, 'eps', name_components[0])
        if os.path.exists(destination_directory):
            # TODO Check last time modified was when this script ran
            print(f'Not copying {episode_dir_name}, because folder already exits')
            continue


fg = fg.FeedGenerator()
# fg.load_extension('podcast')
podcast_properties = read_yaml_file('podcast.yaml')
call_setters(fg, podcast_properties['rss'])
fg.id(f'{podcast_properties["url_base"]}/atom.xml')
fg.link(href='https://www.vanousek.com', rel='alternate')
fg.link(href=f'{podcast_properties["url_base"]}/rss.xml')

parse_episodes(podcast_properties['episodes_root'], fg,
    podcast_properties['output_root'], podcast_properties['url_base'])

fg.rss_file(os.path.join(podcast_properties['output_root'], 'rss.xml'), pretty=True) # Write the RSS feed to a file

# fg.atom_file('atom.xml', pretty=True) # Write the ATOM feed to a file