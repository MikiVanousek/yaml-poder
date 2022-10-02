import YAML, LightXML as lx
using Dates

pubdate_format = dateformat"dd-mm-yy";
iso822_dateformat = dateformat"e, dd u 20yy 00:00 \G\M\T"

function main()
    content_root, force = parse_arguments()
    podcast_properties = YAML.load_file(joinpath(content_root, "podcast.yaml"), dicttype=Dict{String,Any})
    rss = podcast_properties["rss"]
    episodes_root = joinpath(content_root, podcast_properties["episodes_directory"])
    logo = podcast_properties["logo"]
    output_root = podcast_properties["output_root"]
    url_base = podcast_properties["url_base"]


    remove_all_inside(output_root, force)

    xdoc = lx.XMLDocument()
    rss_tag = lx.create_root(xdoc, "rss")
    lx.set_attributes(rss_tag, Dict(
        "version" => "2.0",
        "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
        "xmlns:atom" => "http://www.w3.org/2005/Atom",
    ))

    channel_tag = lx.new_child(rss_tag, "channel")

    logo_path = joinpath(content_root, logo)
    if isfile(logo_path)
        println("Adding $logo as logo")
        symlink(logo_path, joinpath(output_root, logo))
        logo_tag = lx.new_child(channel_tag, "itunes:image")
        lx.set_attribute(logo_tag, "href", "$url_base/$logo")
    else
        println("WARNING: No logo found at $logo_path")
    end

    link_tag = lx.new_child(channel_tag, "atom:link")
    lx.set_attributes(link_tag, rel="self", href="$url_base/rss.xml")

    category_tag = lx.new_child(channel_tag, "itunes:category")
    lx.set_attribute(category_tag, "text", podcast_properties["category"])

    set_attributes_recursively(channel_tag, rss)
    parse_episodes(episodes_root, output_root, url_base, channel_tag)

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

        episode_properties = YAML.load_file(episode_properties_location)
        episode_url = "$url_base/eps/$episode_number/ep.mp3"
        dicttype = Dict{String,Any}
        episode_dict["guid"] = episode_url
        if episode_properties["hook"] === nothing
            episode_dict["title"] = "#$episode_number $(guest_name)"
            println("WARNING: No hook found for the episode")
        else
            episode_dict["title"] = "#$episode_number $guest_name: $(episode_properties["hook"])"
        end
        if length(episode_properties["description"]) > 1000
            println("WARNING: Description length exceeds 1000 characters and might get truncated!")
        end
        episode_dict["description"] = episode_properties["description"]

        if haskey(episode_properties, "pubdate") && episode_properties["pubdate"] !== nothing
            try
                pubdate = Date(episode_properties["pubdate"], pubdate_format)
                episode_dict["pubDate"] = Dates.format(pubdate, iso822_dateformat)
            catch ArgumentError
                throw(ErrorException("Failed to parse pubdate of episode #$(episode_number)!"))
            end
        else
            println("WARNING: No pubdate found for the episode")
        end

        destination_directory = joinpath(output_root, "eps", episode_number)
        mkpath(destination_directory)
        symlink(episode_sound_location, joinpath(destination_directory, "ep.mp3"))

        item_tag = lx.new_child(channel_element, "item")
        enclosure_tag = lx.new_child(item_tag, "enclosure")
        lx.set_attributes(enclosure_tag, url=episode_url, type="audio/mpeg", length=filesize(episode_sound_location))


        set_attributes_recursively(item_tag, episode_dict)
    end
end

function set_attributes_recursively(element, attributes)
    for (key, value) in attributes
        new_tag = lx.new_child(element, key)
        if value isa String
            lx.add_text(new_tag, value)
        elseif value isa Dict{String,Any}
            set_attributes_recursively(new_tag, value)
        else
            throw(Error("Illegal value $value in the data."))
        end
    end
end

function parse_arguments()
    force = false
    content_root = pwd()
    for arg in ARGS
        if arg === "-f"
            force = true
        elseif isdir(arg)
            content_root = arg
        else
            println("""ERROR: Invalid argument $(arg)!
            Usage: julia generator.jl -- [conten_rot] [-f]
            content_root: The home of your podcast description and audio files. By default ./ (current directory).
            -f(orce): Don't ask before deleting the contents of output_root 
            """)
            exit()
        end
    end
    content_root, force
end

function remove_all_inside(output_root, force)
    if !isdir(output_root)
        throw(Error("The output root directory needs to exist!"))
    end
    if !force
        println("Are you sure everyting in $output_root can be deleted (y/n)? ")
        if readline() !== "y"
            println("Goodbye then!")
            exit()
        end
        println("This question can be skipped by passing '-f' as an argument.")
    end
    foreach((d) -> rm(joinpath(output_root, d), recursive=true), readdir(output_root))
end

main()