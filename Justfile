tag-version version:
    #!/usr/bin/env sh
    sed -i 's,config/version=".*",config/version="{{version}}",' project.godot
    sed -i 's,application/version=".*",application/version="{{version}}",' export_presets.cfg
    sed -i 's,application/short_version=".*",application/short_version="{{version}}",' export_presets.cfg

commit-version version:
    #!/usr/bin/env sh
    git commit -m "Release {{version}}"
    git tag "v{{version}}"