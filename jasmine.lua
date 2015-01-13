local parser = clink.arg.new_parser

jasmine_parser = parser({dir_match_generator},
    "--autotest", 
    "--watch" .. parser({dir_match_generator}), 
    "--color", 
    "--noColor", 
    "-m", "--match", 
    "--matchall", 
    "--verbose", 
    "--coffee", 
    "--junitreport", 
    "--output", 
    "--teamcity", 
    "--growl", 
    "--runWithRequireJs", 
    "--requireJsSetup", 
    "--test-dir" .. parser({dir_match_generator}), 
    "--nohelpers", 
    "--forceexit", 
    "--captureExceptions", 
    "--config", 
    "--noStack", 
    "--version", 
    "-h", "--help"
)

clink.arg.register_parser("jasmine-node", jasmine_parser)
