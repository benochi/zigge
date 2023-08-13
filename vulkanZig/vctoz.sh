#! /bin/sh
zig translate-c cimports.h -lc -I"C:\VulkanSDK\1.3.250.1\Include" > src/c.zig