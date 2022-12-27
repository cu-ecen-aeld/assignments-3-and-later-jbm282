#include <stdio.h>
#include <syslog.h>

int main(int argc, char **argv) {
openlog("writer",0,LOG_USER);
if (argc != 3) {
	syslog(LOG_ERR, "missing params");
	return 1;
}

char *writefile = argv[1];
char *writestr = argv[2];

FILE *outFile = fopen(writefile, "w");
fprintf(outFile, "%s", writestr);
syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);
fclose(outFile);
return 0;
}
