# External libs and configs

These pieces are not specific to crambda – but they can be used to help build
crambda binaries for the Lambda environment.

`libcrystal.a` (0.28.0) was extracted as follows:

```
curl -sSL https://github.com/crystal-lang/crystal/releases/download/0.28.0/crystal-0.28.0-1-linux-x86_64.tar.gz | \
  tar -xz --strip-components 5 -- crystal-0.28.0-1/share/crystal/src/ext/libcrystal.a
```

`libgc.a` (7.6.8) was extracted as follows:

```
curl -sSL https://github.com/crystal-lang/crystal/releases/download/0.28.0/crystal-0.28.0-1-linux-x86_64.tar.gz | \
  tar -xz --strip-components 4 -- crystal-0.28.0-1/lib/crystal/lib/libgc.a
```

`libevent.a` (2.1.8) was built as follows:

```
docker run --rm lambci/lambda:build-provided sh -c '
  curl -sSL https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz |
    tar -xz --strip-components 1 &&
    ./autogen.sh &&
    ./configure --disable-shared --disable-debug-mode &&
    make -j$(nproc) &&
    make install-strip &&
    cat /usr/local/lib/libevent.a
  ' > libevent.a
```

`libssl.pc` and `libcrypto.pc` were created as follows:

```
for lib in libssl libcrypto; do
  docker run --rm lambci/lambda:build-provided cat /usr/lib64/pkgconfig/${lib}.pc > ${lib}.pc
done
```
