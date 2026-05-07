cmake_minimum_required(VERSION 3.16)
project(metanit_port)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_PREFIX_PATH "/opt/homebrew/opt/qt/lib/cmake/Qt6")  

find_package(Qt6 REQUIRED 
    COMPONENTS 
        Core 
        Gui 
        Widgets 
        Qml 
        QmlIntegration
        Quick
)

set(SOURCES 
    src/main.cpp
)

set(INCLUDES

)

add_executable(metanit_port
    ${SOURCES}
    ${INCLUDES}
)

target_link_libraries(DayPlanner 
    PRIVATE 
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets 
        Qt6::Qml 
        Qt6::QmlIntegration
        Qt6::Quick
)