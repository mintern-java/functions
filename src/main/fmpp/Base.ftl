<#function _buildModule artifactId>
    -- e.g., functions-binary-core
    <#local parts = artifactId?split("-")>
    <#return {
        "name": parts[1],
        "argc": ARGC_NAMES?seq_index_of(parts[1]),
        "group": parts[2]!
    }>
</#function>

<#assign module = _buildModule(ARTIFACT_ID)>

<#function package checked>
    <#return PACKAGE_BASE + "." + module.name + checked?string(".checked", "")>
</#function>

<#function filename basename checked>
    <#return module.name + "/" + checked?string("checked/", "") + basename + ".java">
</#function>
