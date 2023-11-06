#!/bin/bash

if [[ $1 == "" || $2 == "" ]]; then
    echo "arg1 - GitHub project SLUG"
    echo "arg2 - results file, absolute path"
    exit
fi

NUMROUNDS=3

slug=$1
resultsfile=$2

# Download project
rm -rf $(echo ${slug} | cut -d'/' -f1)
git clone https://github.com/${slug} ${slug}

# Integrate NonDex
cd ${slug}
../../pom-modify/modify-project.sh .

# Get the SHA
sha=$(git rev-parse HEAD)

# Run NonDex, NUMROUNDS rounds
timeout 3600s mvn edu.illinois:nondex-maven-plugin:2.1.1:nondex -DnondexRuns=${NUMROUNDS}

# Run tests
timeout 3600s mvn test > test_output.txt 2>&1

# Grab all the detected tests
if [[ "$(find -name failures | wc -l)" != "0" ]]; then 
    for t in $(cat $(find -name failures) | sort -u); do
        # If the fully-qualified test name is also present in the test_output file then this test always fails 
        if ! grep -q $(tr '#' '.' <<< "$t") test_output.txt; then
            echo "${slug},${sha},${t}" >> "${resultsfile}" 
        fi
    done
fi

rm test_output.txt
