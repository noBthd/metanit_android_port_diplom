cmake_minimum_required(VERSION 3.16)
project(metanit_port VERSION 1.0.0 LANGUAGES CXX)

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

# На iOS — bundle, на десктопе — обычный executable
if(IOS)
    qt_add_executable(metanit_port
        MANUAL_FINALIZATION
        ${MOC_SOURCES}
        ${SOURCES}
        ${RESOURCES}
    )
else()
    add_executable(metanit_port
        ${MOC_SOURCES}
        ${SOURCES}
        ${RESOURCES}
    )
endif()

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

# === iOS-специфичные настройки ===
if(IOS)
    set_target_properties(metanit_port PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.diplom.metanit"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
        
        # Минимальная версия iOS
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "15.0"
        
        # Ориентация — только портретная
        XCODE_ATTRIBUTE_INFOPLIST_KEY_UISupportedInterfaceOrientations "UIInterfaceOrientationPortrait"
        
        # Скрыть статус-бар (опционально)
        XCODE_ATTRIBUTE_INFOPLIST_KEY_UIStatusBarHidden "NO"
        
        # Подпись — автоматическая
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
        XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "YES"
        
        # Разрешить HTTP (для локального API)
        XCODE_ATTRIBUTE_INFOPLIST_KEY_NSAppTransportSecurity_NSAllowsArbitraryLoads "YES"
    )

    # Финализация (нужно для qt_add_executable)
    qt_finalize_target(metanit_port)
endif()
