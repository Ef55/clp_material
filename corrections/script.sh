#!/bin/bash

# This script tries to be as agnostic as possible to the format of the archive provided by the students
# Fell free to report any archive which is not recoginized

# Variables to set
# ==================================================

CLPSPEC_DIR="<CLPSEPC PATH>/compiler"
TEST_SET="<LAB NUMBER>"


# Additional variables
# ==================================================

BRANCH="amy2021"
MOODLE_ARCH_FORMAT="CS-320-*"

# Actual script
# ==================================================

TESTS="CompilerTest.scala TestUtils.scala TestSuite.scala"  # Tests which will be run
DEP=""                                                      # Files which WON'T be taken from the student's submission
if [[ $TEST_SET = 1 ]]; then
    TESTS+=" InterpreterTests.scala ExecutionTests.scala"

elif [[ $TEST_SET = 2 ]]; then
    TESTS+=" LexerTests.scala"

elif [[ $TEST_SET = 3 ]]; then
    TESTS+=" ParserTests.scala"
    DEP+=" src/amyc/parsing/Lexer.scala"

elif [[ $TEST_SET = 4 ]]; then
    TESTS+=" TyperTests.scala"
    DEP+=" src/amyc/parsing/Lexer.scala src/amyc/parsing/Parser.scala"

elif [[ $TEST_SET = 5 ]]; then
    TESTS+=" CodegenTests.scala ExecutionTests.scala"
    DEP+=" src/amyc/parsing/Lexer.scala src/amyc/parsing/Parser.scala src/amyc/analyzer/TypeChecker.scala"

else
    echo "Unknown test set: ${TEST_SET}"
    exit -1
fi


# Setup CLPSPEC
BASE_DIR=$( pwd )
cd $CLPSPEC_DIR

if [ -z "$(git status --porcelain -uno)" ]; then
    # Working directory clean
    echo "CLPSPEC is clear"
    git checkout ${BRANCH} > /dev/null 2> /dev/null
else
    # Uncommitted changes
    echo "Please clean the working tree of CLPSPECS"
    exit -1
fi

cd $BASE_DIR

# Dir creation

rm -rf tmp
mkdir -p tmp

unzip -o -q -j -d tmp ${MOODLE_ARCH_FORMAT}

for archive in tmp/*; do

    # Setup the directories nicely
    group="${archive##*/}"
    group="${group%.*}"

    mkdir -p $group

    files=$( zipinfo -1 ${archive} | grep ".*src/amyc/.*.scala$" | awk '{ printf("\"%s\"\n", $0);  }'   )

    rm -rf ${group}
    echo ${files} | xargs unzip -o -q ${archive} -d ${group}

    src=$( find ${group} -path "*/src" )
    mv "${src}" tmp/
    rm -rf ${group}/*
    mv tmp/src ${group}


    # Run the submissions
    echo "Verifying: ${group}"
    cp -f -r ${group}/src ${CLPSPEC_DIR}
    cd ${CLPSPEC_DIR}

    rm test/scala/amyc/test/*
    for test in ${TESTS}; do
        git checkout test/scala/amyc/test/${test} 2> /dev/null
    done

    filename="${BASE_DIR}/${group}.out"
    sbt test > ${filename}
    echo "Generated: ${filename}"

    ## Restore previous labs files (to avoid penalizing mistakes from previous labs)
    git checkout -- ${DEP}

    filename="${BASE_DIR}/${group}.isolated.out"
    sbt test > ${filename}
    echo "Generated: ${filename}"

    filename="${BASE_DIR}/${group}.diff"
    git --no-pager diff --output=${filename} -- "src/*"
    echo "Generated: ${filename}"

    git checkout -- .
    git clean -f
    echo "Cleaned clpspecs"
    cd ${BASE_DIR}

done

rm -rf tmp
