#!/bin/zsh

awk '
BEGIN {skip=0}

/<!-- PROJECT_TREE_START -->/ {
    print;
    print "```text";
    print "parking-citation-data-project/";
    system("tree -L 2 --noreport -I '\''__pycache__|*.parquet|*.duckdb|.git|node_modules'\'' | tail -n +2");
    print "```";
    skip=1;
    next
}

/<!-- PROJECT_TREE_END -->/ {
    skip=0;
    print;
    next
}

skip==0 {
    print
}

' README.md > README_tmp.md

mv README_tmp.md README.md