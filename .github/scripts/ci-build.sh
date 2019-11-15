#!/usr/bin/env bash

set -x
set -e

echo "## prepare environment ##"
if [[ "${GITHUB_REF}" == "refs/heads/nightly" ]]; then
  echo "-- NIGHTLY --"
  export PUBLISH_BINARY="true"
  export PUBLISH_DIR="nightlies"
  export BUILD_TYPE="ReleaseWithDebInfo"
  export VERSION_TAG="$(date +%Y%m%d)"
elif [[ "${GITHUB_REF}" == "refs/tags/"* ]]; then
  echo "-- RELEASE --"
  export PUBLISH_BINARY="true"
  export PUBLISH_DIR="releases"
  export BUILD_TYPE="ReleaseWithDebInfo"
elif [[ "${GITHUB_REF}" == "refs/pull/"* ]]; then
  export PULL_REQUEST=$(echo "${GITHUB_REF}" | cut -d '/' -f 3)
  echo "-- PULL REQUEST ${PULL_REQUEST} --"
  export PUBLISH_BINARY="true"
  export PUBLISH_DIR="pull-requests/${PULL_REQUEST}"
  export VERSION_TAG="${PULL_REQUEST}pullrequest"
  export BUILD_TYPE="Debug"
else
  echo "-- QUICK BUILD --"
  export PUBLISH_BINARY="false"
  export BUILD_TYPE="Debug"
fi
export BUILD_CMD="cmake --build . --config $BUILD_TYPE"
export CONFIGURE_CMD="cmake -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DVERSION_TAG=${VERSION_TAG}"
if [[ "${BUILD_TYPE}" != "Debug" ]]; then
   export CONFIGURE_CMD="${CONFIGURE_CMD} -DWITH_EDITOR_SLF=ON"
fi
if [[ "${SFTP_PASSWORD}" == "" ]]; then
  export PUBLISH_BINARY="false"
fi
if [[ "$CI_TARGET" == "linux" ]]; then
  sudo apt update
  sudo apt install build-essential libsdl2-dev libfltk1.3-dev libboost-filesystem-dev libboost-system-dev
  export CONFIGURE_CMD="${CONFIGURE_CMD} -DCMAKE_INSTALL_PREFIX=/usr -DEXTRA_DATA_DIR=/usr/share/ja2 -DCPACK_GENERATOR=DEB"
elif [[ "$CI_TARGET" == "mingw" ]]; then
  sudo apt update
  sudo apt install build-essential mingw-w64
  #cmake make g++ libsdl2-dev libboost-all-dev fluid libfltk1.3-dev fakeroot mingw-w64
  export CONFIGURE_CMD="${CONFIGURE_CMD} -DCMAKE_TOOLCHAIN_FILE=./cmake/toolchain-mingw.cmake -DCPACK_GENERATOR=ZIP"
elif [[ "$CI_TARGET" == "mac" ]]; then
  #brew update
  #brew install cmake make g++ libsdl2-dev libboost-all-dev fluid libfltk1.3-dev fakeroot
  export CONFIGURE_CMD="${CONFIGURE_CMD} -DCMAKE_TOOLCHAIN_FILE=./cmake/toolchain-macos.cmake -DCPACK_GENERATOR=Bundle"
else
  echo "unexpected target ${CI_TARGET}"
  exit 1
fi
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=$(cat ./rust-toolchain) -y --profile minimal
export PATH=$PATH:$HOME/.cargo/bin
if [[ "$CI_TARGET" == "mingw" ]]; then
  rustup target add x86_64-pc-windows-gnu
else
  rustup component add rustfmt
  rustup component add clippy
  cargo clippy -- -V
  cargo fmt -- -V
fi
echo "PUBLISH_BINARY=${PUBLISH_BINARY}"
echo "PUBLISH_DIR=${PUBLISH_DIR}"
echo "BUILD_CMD=${BUILD_CMD}"
echo "CONFIGURE_CMD=${CONFIGURE_CMD}"
rustc -V
cargo -V
cmake --version

echo "## configure, build, package ##"
mkdir ci-build
cd ci-build
$CONFIGURE_CMD ..
cat ./CMakeCache.txt
$BUILD_CMD
$BUILD_CMD --target package

echo "## test ##"
if [[ "$CI_TARGET" != "mingw" ]]; then
  sudo $BUILD_CMD --target install
  $BUILD_CMD --target cargo-fmt-test
  $BUILD_CMD --target cargo-clippy-test
  $BUILD_CMD --target cargo-test
  ./ja2 -unittests
  ./ja2-launcher -help
  sudo $BUILD_CMD --target uninstall
fi

echo "## publish ##"
for file in ja2-stracciatella_*; do
  echo "$file"
  if [[ "$file" == *".deb" ]]; then
    dpkg -c "$file"
  elif [[ "$file" == *".zip" ]]; then
    unzip -l "$file"
  else
    echo "TODO list contents"
  fi
  if [[ "$PUBLISH_BINARY" == "true" ]]; then
    curl -v --retry 3 --connect-timeout 60 --max-time 150 --ftp-create-dirs -T "$file" -u $SFTP_USER:$SFTP_PASSWORD ftp://www61.your-server.de/$PUBLISH_DIR/
  fi
done

echo "## done ##"
