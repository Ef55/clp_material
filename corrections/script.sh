#!/bin/bash

# This script tries to be as agnostic as possible to the format of the archive provided by the students
# Fell free to report any archive which is not recoginized

CLPSPEC_DIR="<Path to CLPSPEC repository>/compiler"
BASE_DIR=$( pwd )

# To be changed for each lab
TESTS="<TEST FILES>"

# Setup CLPSPEC
cd $CLPSPEC_DIR

if [ -z "$(git status --porcelain)" ]; then
    # Working directory clean
    echo "CLPSPEC is clear"
    git checkout amy2021 > /dev/null
else
    # Uncommitted changes
    echo "Please clean the working tree of CLPSPECS"
    exit -1
fi

cd $BASE_DIR

# Dir creation

rm -rf tmp
mkdir -p tmp

unzip -o -q -j -d tmp "CS-320-*"

for archive in tmp/*; do

    # Setup the directories nicely
    group="${archive##*/}"
    group="${group%.*}"

    mkdir -p $group

    files=$( zipinfo -1 ${archive} | grep ".*src/amyc/.*.scala$" )

    rm -rf ${group}
    unzip -o -q ${archive} ${files} -d ${group}

    src=$( find ${group} -path "*/src" )
    mv $src tmp/
    rm -rf ${group}/*
    mv tmp/src ${group}


    # Run the submissions
    echo "Verifying: ${group}"
    cp -f -r ${group}/src/ ${CLPSPEC_DIR}
    cd ${CLPSPEC_DIR}

    git --no-pager diff --output="${BASE_DIR}/${group}.diff"

    rm test/scala/amyc/test/*
    for test in ${TESTS}; do
        git checkout test/scala/amyc/test/${test}
    done

    sbt test > "${BASE_DIR}/${group}.out"

    git checkout -- .
    git clean -f
    cd ${BASE_DIR}

done

rm -rf tmp
