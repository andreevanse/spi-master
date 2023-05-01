$FULL_PATH = (Get-Item $args[0]).FullName
cd (Get-Item $args[0]).DirectoryName
vsim -do "source {./dirs.tcl}; do {$FULL_PATH}"
