cmake_minimum_required(VERSION 3.1)
# pass the following as a parameter: BOARD=<uno, mega, etc.>


# search through boards.txt for the relevant information
message(STATUS "Finding board properties...")

set(USB_DEFINITIONS "") # list for USB-related compile definitions that are parsed
set(USB_MANUFACTURER \"unknown\")

set(BOARD_TYPES default)

file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/boards.txt BOARDS_FILE_TEXT)


foreach(LINE ${BOARDS_FILE_TEXT})
	if("${LINE}" MATCHES "^${BOARD}\.build\.variant=(.*)$")
		set(BOARD_VARIANT "${CMAKE_MATCH_1}")
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.f_cpu=(.*)$")
		
		# remove "L" suffix, since the toolchain file adds that already
		string(REPLACE "L" "" MCU_SPEED_default "${CMAKE_MATCH_1}")
		
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.mcu=(.*)$")
		set(MCU_default "${CMAKE_MATCH_1}")
		
	elseif("${LINE}" MATCHES "^${BOARD}\.menu\.cpu\.(.*)\.build\.mcu=(.*)$")
		# multiple variants, remove "default"
		list(REMOVE_ITEM BOARD_TYPES default)
		
		list(APPEND BOARD_TYPES ${CMAKE_MATCH_1})
		
		set(MCU_${CMAKE_MATCH_1} ${CMAKE_MATCH_2})
		
	elseif("${LINE}" MATCHES "^${BOARD}\.menu\.cpu\.(.*)\.build\.f_cpu=(.*)$")
		string(REPLACE "L" "" MCU_SPEED_${CMAKE_MATCH_1} "${CMAKE_MATCH_2}")
	elseif("${LINE}" MATCHES "^${BOARD}\.vid\.1=(.*)$") # found USB flags
		list(APPEND USB_DEFINITIONS -DUSB_VID=${CMAKE_MATCH_1})
	elseif("${LINE}" MATCHES "^${BOARD}\.pid\.1=(.*)$")
		list(APPEND USB_DEFINITIONS -DUSB_PID=${CMAKE_MATCH_1}) # alternate variant of VID & PID flags
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.vid=(.*)$")
		list(APPEND USB_DEFINITIONS -DUSB_VID=${CMAKE_MATCH_1})
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.pid=(.*)$")
		list(APPEND USB_DEFINITIONS -DUSB_PID=${CMAKE_MATCH_1})
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.usb_product=(.*)$")
		list(APPEND USB_DEFINITIONS "-DUSB_PRODUCT=${CMAKE_MATCH_1}")
	elseif("${LINE}" MATCHES "^${BOARD}\.build\.usb_manufacturer=(.*)$")
		set(USB_MANUFACTURER ${CMAKE_MATCH_1})
	endif()
endforeach()

# add the last USB definition
list(APPEND USB_DEFINITIONS "-DUSB_MANUFACTURER=${USB_MANUFACTURER}")

message(STATUS "Variant: ${BOARD_VARIANT}")
message(STATUS "Board Types: ${BOARD_TYPES}")
message(STATUS "USB compile definitions: ${USB_DEFINITIONS}")

add_definitions(${USB_DEFINITIONS})

foreach(TYPE ${BOARD_TYPES})
	
	# ------------------------------------------------------
	# Find properties for type
	if(DEFINED MCU_${TYPE})
		set(AVR_MCU ${MCU_${TYPE}})
	else()
		set(AVR_MCU ${MCU_default})
	endif()
	
	if(DEFINED MCU_SPEED_${TYPE})
		set(MCU_SPEED ${MCU_SPEED_${TYPE}})
	else()
		set(MCU_SPEED ${MCU_SPEED_default})
	endif()
	
	message(STATUS "Board type ${TYPE}: MCU=${AVR_MCU}, MCU_SPEED=${MCU_SPEED}")
	
	if(${TYPE} STREQUAL "default")
		set(INSTALL_SUBDIR ".")
	else()
		set(INSTALL_SUBDIR "${TYPE}")
	endif()

	# ------------------------------------------------------
	# Create core library

	add_avr_library(arduino-core-${BOARD}-${TYPE}
		common-src/abi.cpp
		common-src/CDC.cpp
		common-src/HardwareSerial.cpp
		common-src/HardwareSerial0.cpp
		common-src/HardwareSerial1.cpp
		common-src/HardwareSerial2.cpp
		common-src/HardwareSerial3.cpp
		common-src/hooks.c
		common-src/IPAddress.cpp
		common-src/main.cpp
		common-src/new.cpp
		common-src/PluggableUSB.cpp
		common-src/Print.cpp
		common-src/Stream.cpp
		common-src/Tone.cpp
		common-src/USBCore.cpp
		common-src/WInterrupts.c
		common-src/wiring.c
		common-src/wiring_analog.c
		common-src/wiring_digital.c
		common-src/wiring_pulse.c
		common-src/wiring_pulse.S
		common-src/wiring_shift.c
		common-src/WMath.cpp
		common-src/WString.cpp)

	# include source dir and correct variant dir
	target_include_directories(arduino-core-${BOARD}-${TYPE} PUBLIC common-src variants/${BOARD_VARIANT})
		
	install(TARGETS arduino-core-${BOARD}-${TYPE} DESTINATION ${INSTALL_SUBDIR}/lib)
	
	# ------------------------------------------------------
	# install headers
	set(ARDUINO_HEADERS 
		common-src/Arduino.h
		common-src/binary.h
		common-src/Client.h
		common-src/HardwareSerial.h
		common-src/HardwareSerial_private.h
		common-src/IPAddress.h
		common-src/new.h
		common-src/PluggableUSB.h
		common-src/Print.h
		common-src/Printable.h
		common-src/Server.h
		common-src/Stream.h
		common-src/Udp.h
		common-src/USBAPI.h
		common-src/USBCore.h
		common-src/USBDesc.h
		common-src/WCharacter.h
		common-src/wiring_private.h
		common-src/WString.h
		variants/${BOARD_VARIANT}/pins_arduino.h)
	
	install(FILES ${ARDUINO_HEADERS} DESTINATION ${INSTALL_SUBDIR}/include)
	
endforeach()