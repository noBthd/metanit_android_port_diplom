cmake_minimum_required(VERSION 3.10)
project(metanit_port)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED 
    COMPONENTS 
        Core 
        Gui 
        Widgets 
        Qml 
        QmlIntegration
        Quick
)

qt_standard_project_setup()

set(SOURCES 
    src/app/main.cpp
)

set(INCLUDES

)

qt6_add_resources(RESOURCES
    src/ui/resources.qrc
)

add_executable(metanit_port
    ${SOURCES}
    ${INCLUDES}
    ${RESOURCES}
)

target_link_libraries(metanit_port
    PRIVATE 
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets 
        Qt6::Qml 
        Qt6::QmlIntegration
        Qt6::Quick
)