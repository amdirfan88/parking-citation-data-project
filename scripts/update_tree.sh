#!/bin/zsh

TREE=$(tree -L 2 -I '__pycache__|*.parquet|*.duckdb|.git|node_modules')

awk '
/<!-- PROJECT_TREE_START -->/ {
    print;
    print "```text";
    system("tree -L 2 -I '\''__pycache__|*.parquet|*.duckdb|.git|node_modules'\''");
    print "```";
    skip=1;
    next
}
/<!-- PROJECT_TREE_END -->/ {
    skip=0
}
!skip
' README.md > README_tmp.md

mv README_tmp.md README.md