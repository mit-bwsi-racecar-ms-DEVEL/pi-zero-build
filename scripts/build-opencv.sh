#!/usr/bin/env bash

set -e

# change default constants here:
readonly PREFIX=/usr/local  # install prefix, (can be ~/.local for a user install)
readonly DEFAULT_VERSION=4.5.2  # controls the default version (gets reset by the first argument)
readonly PYTHON3_VERSION=3.9.5

configure () {
    local CMAKEFLAGS="
        -D CMAKE_BUILD_TYPE=RELEASE
        -D CMAKE_INSTALL_PREFIX=${PREFIX}
        -D BUILD_OPENCV_PYTHON2=OFF
        -D BUILD_OPENCV_PYTHON3=ON
        -D OPENCV_PYTHON3_VERSION=${PYTHON3_VERSION}
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules
        -D ENABLE_NEON=OFF
        -D ENABLE_VFPV3=OFF
        -D INSTALL_PYTHON_EXAMPLES=OFF
        -D OPENCV_ENABLE_NONFREE=OFF
        -D CMAKE_SHARED_LINKER_FLAGS=-latomic
        -D BUILD_EXAMPLES=OFF"

    if [[ "$1" != "test" ]] ; then
        CMAKEFLAGS="
        ${CMAKEFLAGS}
        -D BUILD_PERF_TESTS=OFF
        -D BUILD_TESTS=OFF"
    fi

    echo "cmake flags: ${CMAKEFLAGS}"

#    cd opencv
#    mkdir build
#    cd build
    cmake ${CMAKEFLAGS} .. 2>&1 | tee -a configure.log
}

main () {

    local VER=${DEFAULT_VERSION}

    # parse arguments
    if [[ "$#" -gt 0 ]] ; then
        VER="$1"  # override the version
    fi

    if [[ "$#" -gt 1 ]] && [[ "$2" == "test" ]] ; then
        DO_TEST=1
    fi

    # prepare for the build:
#    setup
#    install_dependencies
#    git_source ${VER}

    if [[ ${DO_TEST} ]] ; then
        configure test
    else
        configure
    fi

    # start the build
    make 2>&1 | tee -a build.log

    if [[ ${DO_TEST} ]] ; then
        make test 2>&1 | tee -a test.log
    fi

    # avoid a sudo make install (and root owned files in ~) if $PREFIX is writable
    if [[ -w ${PREFIX} ]] ; then
        make install 2>&1 | tee -a install.log
    else
        sudo make install 2>&1 | tee -a install.log
    fi

#    cleanup --test-warning

}

main "$@"
