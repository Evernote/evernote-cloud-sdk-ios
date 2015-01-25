# Sets the target folders and the final framework product.
FMK_NAME=ENSDK
FMK_VERSION=A
SRCROOT="$(pwd)/../"
RESOURCE_NAME=ENSDKResources.bundle

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
INSTALL_DIR=${SRCROOT}/Products/${FMK_NAME}.framework

# Working dir will be deleted after the framework creation.
WRK_DIR=${SRCROOT}/build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework

echo "Building $FMK_NAME library."

# Building both architectures.
xcodebuild -project "${SRCROOT}/evernote-sdk-ios.xcodeproj" -configuration "Release" -target "${FMK_NAME}" -sdk iphoneos
xcodebuild -project "${SRCROOT}/evernote-sdk-ios.xcodeproj" -configuration "Release" -target "${FMK_NAME}" -sdk iphonesimulator

# Cleaning the oldest.
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi

# Creates and renews the final product folder.
mkdir -p "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}/Versions"
mkdir -p "${INSTALL_DIR}/Versions/${FMK_VERSION}"
mkdir -p "${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources"
mkdir -p "${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers"
mkdir -p "${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers/Advanced"

# Creates the internal links.
# It MUST uses relative path, otherwise will not work when the folder is copied/moved.
ln -s "${FMK_VERSION}" "${INSTALL_DIR}/Versions/Current"
ln -s "Versions/Current/Headers" "${INSTALL_DIR}/Headers"
ln -s "Versions/Current/Resources" "${INSTALL_DIR}/Resources"
ln -s "Versions/Current/${FMK_NAME}" "${INSTALL_DIR}/${FMK_NAME}"

# Copies the headers and resources files to the final product folder.
cp -R "${DEVICE_DIR}/Headers/" "${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers/"
cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/"
cp -R "${DEVICE_DIR}/PrivateHeaders/" "${INSTALL_DIR}/Versions/${FMK_VERSION}/Headers/Advanced/"

# Removes the binary and header from the resources folder.
rm -r "${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/Headers" "${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/PrivateHeaders" "${INSTALL_DIR}/Versions/${FMK_VERSION}/Resources/${FMK_NAME}"

# Uses the Lipo Tool to merge both binary files (i386 + armv6/armv7) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/Versions/${FMK_VERSION}/${FMK_NAME}"

rm -r "${WRK_DIR}"

# Copy resource to Products folder
cp -R "${SRCROOT}/${RESOURCE_NAME}" ${INSTALL_DIR}/../

echo "Framework built successfully! Please find in ${INSTALL_DIR}"
exit 0
