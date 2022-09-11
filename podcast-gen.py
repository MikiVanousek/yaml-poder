import feedgen.feed as fg, yaml, os, re, shutil

def main():
    podcast_properties = read_yaml_file('podcast.yaml')
    # Deletes everything in output directory, so that we have a clean build.
    for filename in os.listdir(podcast_properties['output_root']):
        file_path = os.path.join(podcast_properties['output_root'], filename)
    try:
        if os.path.isfile(file_path) or os.path.islink(file_path):
            os.unlink(file_path)
        elif os.path.isdir(file_path):
            shutil.rmtree(file_path)
    except Exception as e:
        print('Failed to delete %s. Reason: %s' % (file_path, e))

    generator = fg.FeedGenerator()
    generator.load_extension('podcast')
    call_setters(generator, podcast_properties['rss'])
    generator.id(f'{podcast_properties["url_base"]}/atom.xml')
    generator.link(href='https://www.vanousek.com', rel='alternate')
    generator.link(href=f'{podcast_properties["url_base"]}/rss.xml')

    if not os.path.exists(podcast_properties['output_root']):
        # TODO Create output dir instead, ensure permissions
        raise Exception('The output root directory needs to exist!')

    parse_episodes(podcast_properties['episodes_root'], generator,
        podcast_properties['output_root'], podcast_properties['url_base'])

    generator.rss_file(os.path.join(podcast_properties['output_root'], 'rss.xml'), pretty=True) # Write the RSS feed to a file

    # generator.atom_file('atom.xml', pretty=True) # Write the ATOM feed to a file

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
        episode_sound_location = os.path.join(episodes_root, episode_dir_name, 'ep.mp3')
        if not os.path.exists(episode_sound_location):
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
        episode_url = f'{url_base}/eps/{name_components[0]}/ep.mp3'
        fe = feed_generator.add_entry()
        fe.id(episode_url)
        fe.title(f'#{name_components[0]}{guest_name}: {episode_properties["hook"]}')
        fe.description(episode_properties['description'])
        fe.enclosure(episode_url, 0, 'audio/mpeg')

        destination_directory = os.path.join(output_root, 'eps', name_components[0])
        os.makedirs(destination_directory)
        os.symlink(episode_sound_location, os.path.join(destination_directory, 'ep.mp3')) 

if __name__ == '__main__':
    main();
