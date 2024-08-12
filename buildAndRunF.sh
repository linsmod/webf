runsample(){
    ret=$PWD
    cd webf/example && flutter run --release
    cd $ret
}
runsampled(){
    ret=$PWD
    cd webf/example && flutter run
    cd $ret
}
buildLinux(){
    npm run build:bridge:linux:release
}
buildLinuxd(){
    npm run build:bridge:linux
}
echo To initialize the build, using buildLinux or buildLinuxd:
echo then use runsample for release build, or runsampled for debug build

