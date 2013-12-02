local sc_parser = {
    "query", "queryex", "start", "pause", "interrogate", "continue", "stop",
    "config", "description", "failure", "failureflag", "sidtype", "privs",
    "managedaccount", "qc", "qdescription", "qfailure", "qfailureflag",
    "qsidtype", "qprivs", "qtriggerinfo", "qpreferrednode", "qrunlevel",
    "qmanagedaccount", "delete", "create", "control", "sdshow", "sdset",
    "showsid", "triggerinfo", "preferrednode", "runlevel", "GetDisplayName",
    "GetKeyName", "EnumDepend", "boot", "Lock", "QueryLock", "/?"
}

clink.arg.register_parser("sc", sc_parser)