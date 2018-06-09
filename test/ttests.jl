using JuDoc
using Base.Test


#FOLDER_PATH = mktempdir() * "/"
FOLDER_PATH = "/Users/tlienart/Desktop/website/"

#### SET PATHS NOTE-OK
JuDoc.set_paths!()
@test JuDoc.JD_PATHS[:f] == FOLDER_PATH

#### SCAN INPUT DIR NOTE-OK
md_files = Dict{Pair{String, String}, Float64}()
html_files = similar(md_files)
other_files = similar(md_files)
infra_files = similar(md_files)
watched_files = [md_files, html_files, other_files, infra_files]
watched_names = ["md", "html", "other", "infra"]
watched = zip(watched_names, watched_files)

JuDoc.scan_input_dir!(watched_files..., false)

#### CONFIG NOTE-OK
JuDoc.process_config()
@test JuDoc.JD_GLOB_VARS["author"].first == "T. Lienart"

#### PREPARE OUTPUT NOTE-OK
JuDoc.prepare_output_dir(false)


####
head = readstring(JuDoc.JD_PATHS[:in_html] * "head.html")
pg_foot = readstring(JuDoc.JD_PATHS[:in_html] * "page_foot.html")
foot = readstring(JuDoc.JD_PATHS[:in_html] * "foot.html")

clear_out_dir = true
verb = true

verb && print("Compiling the full folder once... ")
start = time()
for (name, dict) ∈ watched, (fpair, t) ∈ dict
    if name == "md"
        JuDoc.write_page(fpair..., head, pg_foot, foot)
    elseif name == "html"
        raw_html = readstring(joinpath(fpair...))
        proc_html = JuDoc.process_html_blocks(raw_html, JuDoc.JD_GLOB_VARS)
        write(JuDoc.out_path(fpair.first) * fpair.second, proc_html)
    elseif name == "other"
        opath = JuDoc.out_path(fpair.first) * fpair.second
        # only copy it again if necessary (particularly relevant)
        # when the asset files take quite a bit of space.
        if clear_out_dir || !isfile(opath) || JuDoc.last(opath) < t
            cp(joinpath(fpair...), opath, remove_destination=true)
        end
    else # name == "infra"
        continue
        # potentially here:
        # - process the CSS
        # - copy it out
        # --> but then no-need to do the copy step in the prepare_output_dir
    end
end
verb && JuDoc.time_it_took(start)
