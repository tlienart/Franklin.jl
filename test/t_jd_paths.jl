@test_throws AssertionError JuDoc.set_paths!() # PATH_INPUT undef

td = mktempdir() * "/"
FOLDER_PATH = td

P = JuDoc.set_paths!()
@test JuDoc.JD_PATHS[:f] == td
@test JuDoc.JD_PATHS[:in] == td * "src/"
@test JuDoc.JD_PATHS[:in_css] == td * "src/_css/"
@test JuDoc.JD_PATHS[:in_html] == td * "src/_html_parts/"
@test JuDoc.JD_PATHS[:libs] == td * "libs/"
@test JuDoc.JD_PATHS[:out] == td * "pub/"
@test JuDoc.JD_PATHS[:out_css] == td * "css/"
@test P == JuDoc.JD_PATHS
mkdir(JuDoc.JD_PATHS[:in])
mkdir(JuDoc.JD_PATHS[:in_pages])
mkdir(JuDoc.JD_PATHS[:libs])
mkdir(JuDoc.JD_PATHS[:in_css])
mkdir(JuDoc.JD_PATHS[:in_html])
