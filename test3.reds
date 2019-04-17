Red/System []
#define handle!				[pointer! [integer!]]
#include %runtime/dlink.reds
#include %runtime/platform/definitions/windows.reds
#include %runtime/ports/usb-windows.reds

usb-windows/init
usb-windows/enum-all-devices

print-line "devices:"
pNode: as usb-windows/DEVICE-INFO-NODE! 0
list: usb-windows/device-list/list-head
entry: list/next
while [entry <> list][
    pNode: as usb-windows/DEVICE-INFO-NODE! entry
    print-line "desc-name:"
    dump-hex pNode/desc-name
    print-line pNode/desc-name-len
    print-line "driver-name:"
    dump-hex pNode/driver-name
    print-line pNode/driver-name-len
    print-line "port:"
    print-line pNode/port
    entry: entry/next
]
