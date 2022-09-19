import YAML, LightXML as lx

function main()
    podcast_properties = YAML.load_file("podcast.yaml"; dicttype=Dict{String,Any})
    rss = podcast_properties["rss"]
    content_root = podcast_properties["content_root"]
    episodes_root = joinpath(content_root, podcast_properties["episodes_directory"])
    logo = podcast_properties["logo"]
    output_root = podcast_properties["output_root"]
    url_base = podcast_properties["url_base"]


    if !isdir(output_root)
        throw(Error("The output root directory needs to exist!"))
    end
    # Clean up the output_root
    # TODO Make sure this is desired
    foreach((d) -> rm(joinpath(output_root, d), recursive=true), readdir(output_root))

    logo_path = joinpath(content_root, logo)
    if !isfile(logo_path)
        symlink(logo_path, joinpath(output_root, logo))
        rss["itunes:image"] = "$url_base/$logo"
        print("Adding $logo as logo")
    else
        print("WARNING: No logo found at $logo_path")
    end

    # Generate rss.xml
    xdoc = lx.XMLDocument()
    rss_tag = lx.create_root(xdoc, "rss")
    channel_tag = lx.new_child(rss_tag, "channel")
    lx.set_attribute(rss_tag, "version", "2.[1]")
    set_attributes_recursively(rss_tag, rss)
    eps = parse_episodes(episodes_root, output_root, url_base, channel_tag)



    println(xdoc)
    lx.save_file(xdoc, joinpath(output_root, "rss.xml"))
end


function parse_episodes(episodes_root, output_root, url_base, channel_element)
    regex = r"\d{4}([-]\w*)+"

    for episode_dir_name in sort(readdir(episodes_root))
        episode_dict = Dict()
        if !occursin(regex, episode_dir_name)
            println("WARNING: Skipping $episode_dir_name, it does not match the $regex regular expression pattern")
            continue
        end

        episode_sound_location = joinpath(episodes_root, episode_dir_name, "ep.mp3")
        if !isfile(episode_sound_location)
            println("WARNING: Skipping $episode_dir_name, it does not contain ep.mp3")
            continue
        end

        episode_properties_location = joinpath(episodes_root, episode_dir_name, "ep.yaml")
        if !isfile(episode_properties_location)
            println("WARNING: Skipping $episode_dir_name, it does not contain ep.yaml")
            continue
        end

        name_components = split(episode_dir_name, "-")
        episode_number = name_components[1]
        guest_name = join(name_components[2:end], " ")
        println("Adding episode #$episode_number with $guest_name")

        episode_properties = YAML.load_file(episode_properties_location; dicttype=Dict{String,Any})
        episode_url = "$url_base/eps/$episode_number/ep.mp3"
        episode_dict["id"] = episode_url
        if episode_properties["hook"] === nothing
            episode_dict["title"] = "#$episode_number $(guest_name)"
        else
            episode_dict["title"] = "#$episode_number $guest_name: $(episode_properties["hook"])"
        end
        episode_dict["description"] = episode_properties["description"]

        destination_directory = joinpath(output_root, "eps", episode_number)

        mkpath(destination_directory)
        symlink(episode_sound_location, joinpath(destination_directory, "ep.mp3"))

        item = lx.new_child(channel_element, "item")
        enclosure_tag = lx.new_element(item, "enclosure")

        set_attributes_recursively(item, episode_dict)
    end
end

function set_attributes_recursively(element, attributes)
    for (key, value) in attributes
        new_element = lx.new_child(element, key)
        if value isa String
            lx.add_text(new_element, value)
        elseif value isa Dict{String,Any}
            set_attributes_recursively(new_element, value)
        else
            throw(Error("Illegal value $value in the data."))
        end
    end
end

main()