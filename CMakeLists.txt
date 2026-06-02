cmake_minimum_required(VERSION 3.16)
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
        Network
)

qt_standard_project_setup()

set(SOURCES 
    src/app/main.cpp
    src/core/services/article_service.cpp
    src/core/services/article_model.cpp
    src/core/services/markdown_service.cpp
    src/core/services/network_service.cpp
)

set(INCLUDES
    src/core/models/article.h
    src/core/services/article_service.h
    src/core/services/article_model.h
    src/core/services/markdown_service.h
    src/core/services/network_service.h
)

qt6_add_resources(RESOURCES
    src/ui/resources.qrc
)

qt_wrap_cpp(MOC_SOURCES ${INCLUDES})

add_executable(metanit_port
    ${MOC_SOURCES}
    ${SOURCES}
    ${RESOURCES}
)

target_include_directories(metanit_port 
    PRIVATE
        src/core
)

target_link_libraries(metanit_port
    PRIVATE 
        Qt6::Core
        Qt6::Gui
        Qt6::Widgets 
        Qt6::Qml 
        Qt6::QmlIntegration
        Qt6::Quick
        Qt6::Network
)
