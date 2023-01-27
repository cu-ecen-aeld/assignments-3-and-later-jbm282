#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <linux/fs.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <syslog.h>
#include <signal.h>


const char *DATAFILE = "/var/tmp/aesdsocketdata";

void handler(int sig) {
	/*
	if (sig == SIGINT)
		printf("got sigint\n");
	if (sig == SIGTERM)
		printf("got sigterm\n");
		*/
	syslog(LOG_DEBUG, "Caught signal, exiting");
	remove(DATAFILE);
	exit(1);
}

int main(int argc, char **argv) {
	struct sigaction act;
	act.sa_handler = handler;
	sigemptyset(&act.sa_mask);
	act.sa_flags = 0;
	sigaction(SIGINT, &act, NULL);
	sigaction(SIGTERM, &act, NULL);
	int server_fd = socket(AF_INET, SOCK_STREAM, 0);
	openlog("aesdsocket",0,LOG_USER);

	struct addrinfo hints;
	memset(&hints, 0, sizeof hints);
	struct addrinfo *servinfo;
	hints.ai_flags = AI_PASSIVE;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_family = AF_INET;

	getaddrinfo(NULL,"9000",&hints, &servinfo);


	socklen_t yes = 1;
	setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof yes);
	bind(server_fd, (struct sockaddr*)servinfo->ai_addr, sizeof(struct sockaddr_in));
	freeaddrinfo(servinfo);
	if (argc > 1 && strcmp(argv[1], "-d") == 0) {
		if (fork() > 0)
			exit(EXIT_SUCCESS);
		setsid();
		chdir("/");
		close(0);
		close(1);
		close(2);
		open("/dev/null", O_RDWR);
		dup(0);
		dup(0);
	}
	listen(server_fd, 5);
	while (1) {
		struct sockaddr_in client_addr;
		char ipstr[INET_ADDRSTRLEN];
		int client_len = sizeof client_addr;
		int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
		inet_ntop(AF_INET, &client_addr.sin_addr, ipstr, sizeof ipstr);
		syslog(LOG_DEBUG, "Accepted connection from %s\n", ipstr);
		FILE *outFile = fopen(DATAFILE,"a");
		char ch;
		do {
		read(client_fd, &ch, 1);
		fputc(ch, outFile);
		if (ch == '\n') break;
		}
		while (1);
		fclose(outFile);
		int infd = open(DATAFILE, O_RDONLY);
		while (read(infd, &ch, 1) > 0) {
			write(client_fd, &ch, 1);
		}
		close(client_fd);
		syslog(LOG_DEBUG, "Closed connection from  %s\n", ipstr);
	}
	return 0;
}

