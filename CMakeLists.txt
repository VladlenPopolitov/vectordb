cmake_minimum_required(VERSION 3.15)

project(vectordb)
file(GLOB all_src_files_vector CONFIGURE_DEPENDS "external/pgvector/src/*.c")
add_executable(vectordb main.c ${all_src_files_vector} )

find_package(PostgreSQL)
if(PostgreSQL_FOUND)
  set(PG_LIBRARIES ${PostgreSQL_LIBRARIES})
  set(PG_INCLUDE_DIRS ${PostgreSQL_INCLUDE_DIRS})
  message(STATUS "pg inc: " ${PostgreSQL_INCLUDE_DIRS})
  add_library(pg_lib INTERFACE IMPORTED)
  set_target_properties(pg_lib
                        PROPERTIES INTERFACE_INCLUDE_DIRECTORIES
                                   "${PostgreSQL_INCLUDE_DIRS}"
                                   INTERFACE_LINK_LIBRARIES
                                   "${PostgreSQL_LIBRARIES}")
  mark_as_advanced(PG_INCLUDE_DIRS PG_LIBRARIES)
endif(PostgreSQL_FOUND)

include_directories(vectordb PUBLIC external/postgresql-15.4/src/include)
include_directories(vectordb PUBLIC external/pgvector/src)
#link_directories(vectordb /usr/local/pgsql/lib/)
message(status ${CMAKE_CURRENT_SOURCE_DIR}/external/postgresql-15.4/src/interfaces/libpq/)
link_directories(vectordb ${CMAKE_CURRENT_SOURCE_DIR}/external/postgresql-15.4/src/interfaces/libpq/)
link_libraries(vectordb pq  )

