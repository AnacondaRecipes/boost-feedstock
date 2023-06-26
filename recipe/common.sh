#!/bin/bash
#!/usr/bin/env bash

if [[ "${target_platform}" == osx* ]]; then
    TOOLSET=clang
elif [[ "${target_platform}" == linux* ]]; then
    TOOLSET=gcc
fi