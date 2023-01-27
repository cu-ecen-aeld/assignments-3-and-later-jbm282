CC=$(CROSS_COMPILE)gcc
all: aesdsocket
aesdsocket: aesdsocket.c
	rm -f /var/tmp/aesdsocketdata
	$(CC) -o aesdsocket aesdsocket.c
clean:
	rm -f aesdsocket
	rm -f /var/tmp/aesdsocketdata
