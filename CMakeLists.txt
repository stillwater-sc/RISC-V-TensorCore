cmake_minimum_required(VERSION 3.14 FATAL_ERROR)
#set(EXECNAME "tensorcore_tb")

project(tensorcore_tb VERSION 0.1.0 LANGUAGES CXX)

include(FetchContent)
FetchContent_Declare(universal
  GIT_REPOSITORY  https://github.com/stillwater-sc/universal.git
  GIT_TAG         main
  )
FetchContent_MakeAvailable(universal)

execute_process(COMMAND sandpiper-saas -i ${CMAKE_CURRENT_SOURCE_DIR}/src//hw/tensorcore.tlv -o tensorcore.sv --default_includes --iArgs)
##execute_process(COMMAND sandpiper-saas -i ${CMAKE_CURRENT_SOURCE_DIR}/src/hw/tensorcore.tlv -o tensorcore.sv --iArgs)
  
find_package(verilator HINTS $ENV{VERILATOR_ROOT})
if (NOT verilator_FOUND)
	message(FATAL_ERROR "Verilator was not found")
endif()

add_executable(tensorcore_tb src/tb/tensorcore_tb.cpp)
include_directories(src/tb/includes)
include_directories(${universal_SOURCE_DIR}/include/)
#add_dependencies(alu_tb sandpiper)

message(STATUS "CMAKE_CURRENT_BINARY_DIR = ${CMAKE_CURRENT_BINARY_DIR}")

verilate(tensorcore_tb 
    SOURCES
        ${CMAKE_CURRENT_BINARY_DIR}/tensorcore.sv
	##	${CMAKE_CURRENT_BINARY_DIR}/tensorcore_gen.sv
    INCLUDE_DIRS
        ${CMAKE_SOURCE_DIR}/src/hw/
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}/includes
        ${CMAKE_CURRENT_BINARY_DIR}/includes/proj_default
    VERILATOR_ARGS
        -Wno-MODDUP)
