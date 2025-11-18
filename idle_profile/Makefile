# Makefile for idle_profile using ext-idle-notify-v1 Wayland protocol

CC = gcc
CFLAGS = -Wall -Wextra -O2 $(shell pkg-config --cflags wayland-client)
LDFLAGS = $(shell pkg-config --libs wayland-client)

WAYLAND_SCANNER = $(shell pkg-config --variable=wayland_scanner wayland-scanner)
WAYLAND_PROTOCOLS_DIR = $(shell pkg-config --variable=pkgdatadir wayland-protocols)

# Protocol files
PROTOCOL_XML = $(WAYLAND_PROTOCOLS_DIR)/staging/ext-idle-notify/ext-idle-notify-v1.xml
PROTOCOL_HEADER = ext-idle-notify-v1-client-protocol.h
PROTOCOL_CODE = ext-idle-notify-v1-client-protocol.c

TARGET = idle_profile

all: $(TARGET)

# Generate protocol files from XML
$(PROTOCOL_HEADER): $(PROTOCOL_XML)
	$(WAYLAND_SCANNER) client-header $< $@

$(PROTOCOL_CODE): $(PROTOCOL_XML)
	$(WAYLAND_SCANNER) private-code $< $@

# Build the program
$(TARGET): idle_profile.c $(PROTOCOL_CODE) $(PROTOCOL_HEADER)
	$(CC) $(CFLAGS) -o $@ idle_profile.c $(PROTOCOL_CODE) $(LDFLAGS)

clean:
	rm -f $(TARGET) $(PROTOCOL_HEADER) $(PROTOCOL_CODE)

install: $(TARGET)
	install -m 755 $(TARGET) $(HOME)/bin/$(TARGET)

.PHONY: all clean install
