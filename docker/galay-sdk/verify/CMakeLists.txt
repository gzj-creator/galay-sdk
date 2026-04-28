cmake_minimum_required(VERSION 3.28)
project(galay-sdk-verify LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_PREFIX_PATH "/usr/local" ${CMAKE_PREFIX_PATH})
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

find_package(galay-utils REQUIRED CONFIG)
find_package(galay-kernel 4.0.0 REQUIRED CONFIG)
find_package(galay-ssl 2.0.0 REQUIRED CONFIG)
find_package(galay-http 3.0.0 REQUIRED CONFIG)
find_package(galay-rpc 2.0.0 REQUIRED CONFIG)
find_package(galay-mcp 2.0.0 REQUIRED CONFIG)
find_package(galay-redis 2.0.0 REQUIRED CONFIG)
find_package(galay-mysql REQUIRED CONFIG)
find_package(galay-mongo REQUIRED CONFIG)
find_package(galay-etcd REQUIRED CONFIG)

add_executable(galay-sdk-verify main.cpp)

target_link_libraries(galay-sdk-verify PRIVATE
    galay::galay-utils
    galay-kernel::galay-kernel
    galay-ssl::galay-ssl
    galay-http::galay-http
    galay-rpc::galay-rpc
    galay-mcp
    galay-redis::galay-redis
    galay-mysql::galay-mysql
    galay-mongo::galay-mongo
    galay-etcd::galay-etcd
)
