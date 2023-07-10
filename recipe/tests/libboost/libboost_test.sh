
${CXX} -I$PREFIX/include -L$PREFIX/lib -Wl,-rpath,$PREFIX/lib test_iostreams_zlib.cpp -lboost_iostreams -lz -lbz2 -llzma -lzstd && ./a.out
