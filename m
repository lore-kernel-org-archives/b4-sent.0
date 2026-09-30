From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:10:57 +0200
Subject: [PATCH v3 03/15] mount_service: refuse paths the user did not name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-3-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=13605; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=KjuHj65yEOPcdMP+4/ThHDrs1EdjoBS6xT5kMOaJnNc=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cmUZpvZnz1UI2dhlvOzn0elLLwvmvROfd3KCqNXrJ
 oWJJbk1HaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCRiymMDF9L95Z9PffeOUHI
 l2nm+9PvytddK/rG2BxhwC1VYfPMoprhf/SlJ2aNpTOKptx60XvhceCLE/4t878Ht+Wt9+Wdl+W
 ZyQkA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fuservicemount3 warns about a path that the user did not name on the
command line, but still opens it. A server can take a path in a form
that the helper cannot split, for example "-journal/dev/sdb1" or its
own option syntax. The administrator can now list such paths in
/etc/fuse.conf, per filesystem type:

    service_open_path = ext4 /dev/sd*

The pattern is matched with fnmatch() and FNM_PATHNAME, so "*" does not
match "/". A requested path with a "." or ".." component never matches,
because "*" matches "..", and "/dev/*" would then open "/". The helper
now refuses any other path with EPERM.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 doc/fuservicemount3.8  |  16 ++++++++
 doc/mount.fuse3.8      |   7 ++++
 include/fuse_service.h |   4 +-
 test/test_fuser_conf.c |  59 +++++++++++++++++++++++++++
 util/fuse.conf         |  12 ++++++
 util/fuser_conf.c      | 106 +++++++++++++++++++++++++++++++++++++++++++++++++
 util/fuser_conf.h      |   3 ++
 util/mount_service.c   |  13 +++---
 8 files changed, 214 insertions(+), 6 deletions(-)

diff --git a/doc/fuservicemount3.8 b/doc/fuservicemount3.8
index aa2167cb4872..18e285c1ab29 100644
--- a/doc/fuservicemount3.8
+++ b/doc/fuservicemount3.8
@@ -19,6 +19,22 @@ Mount a filesystem using a FUSE server that runs as a socket service.
 These servers can be contained using the platform's service management
 framework.
 
+The FUSE server may ask fuservicemount3 to open files on its behalf.
+fuservicemount3 opens a path only in these cases:
+.IP \- 2
+The path is a command line argument, for example /srv/disk.img.
+.IP \- 2
+The path is the value in a key=value option, for example /dev/sdb1 in
+"-o journal_dev=/dev/sdb1".
+.IP \- 2
+The path directly follows a short option, for example /dev/sdb1 in
+"-J/dev/sdb1".
+.IP \- 2
+A service_open_path line in /etc/fuse.conf lists the path for the filesystem
+type.
+.PP
+It refuses any other request with EPERM.
+
 The second form checks if there is a FUSE service available for the given
 filesystem type.
 .SH "AUTHORS"
diff --git a/doc/mount.fuse3.8 b/doc/mount.fuse3.8
index 2e587458a06e..d55c96139d9f 100644
--- a/doc/mount.fuse3.8
+++ b/doc/mount.fuse3.8
@@ -38,6 +38,13 @@ Allow non-root users to specify the \fBallow_other\fP or
 \fBallow_root\fP mount options (see below).
 .TP
 These limits are enforced by the \fBfusermount3\fP helper, so they can be avoided by filesystems that run as root.
+.TP
+\fBservice_open_path = SUBTYPE PATTERN\fP
+Allow \fBfuservicemount3\fP(8) to open paths that match \fIPATTERN\fP for the
+server of a service mount of type \fBfuse.\fISUBTYPE\fR, in addition to the
+paths on the mount command line. \fIPATTERN\fP is an absolute path in which "*"
+does not match "/". A pattern that matches a directory gives the server every
+file below it. The line can be repeated.
 .SH OPTIONS
 Most of the generic mount options described in \fBmount\fP are
 supported (\fBro\fP, \fBrw\fP, \fBsuid\fP, \fBnosuid\fP, \fBdev\fP,
diff --git a/include/fuse_service.h b/include/fuse_service.h
index d6aedea8f0f8..2114e7772bf5 100644
--- a/include/fuse_service.h
+++ b/include/fuse_service.h
@@ -139,6 +139,8 @@ int fuse_service_parse_cmdline_opts(struct fuse_args *args,
 
 /**
  * Ask the mount.service helper to open a file on behalf of the fuse server.
+ * The helper refuses a path that the mount command line does not name and
+ * fuse.conf does not list; fuse_service_receive_file() then reports -EPERM.
  *
  * @param sf service context
  * @param path the path to file
@@ -153,7 +155,7 @@ int fuse_service_request_file(const struct fuse_service *sf, const char *path,
 
 /**
  * Ask the mount.service helper to open a block device on behalf of the fuse
- * server.
+ * server.  The helper refuses the same paths as for a file request.
  *
  * @param sf service context
  * @param path the path to file
diff --git a/test/test_fuser_conf.c b/test/test_fuser_conf.c
index 4d974931cf58..5f714d5c2561 100644
--- a/test/test_fuser_conf.c
+++ b/test/test_fuser_conf.c
@@ -105,6 +105,63 @@ static int test_trimmed_options(void)
 	return 0;
 }
 
+static int test_service_open_path(void)
+{
+	const char *test = "service_open_path";
+
+	if (write_conf("service_open_path = ext4 /dev/sd*\n"
+		       "service_open_path = ext4 /dev/nvme*\n"
+		       "service_open_path = ext4 relative/path\n"
+		       "service_open_path = xfs\t/srv/xfs.img\n"
+		       "service_open_path = xfs /srv/img/*\n"
+		       " \tservice_open_path = ext4 /srv/indented.img\n"
+		       "service_open_path = * /proc/pressure\n"
+		       "service_open_path =\x20\n"
+		       "service_open_path = ext4\n") == -1)
+		return fail(test, "could not write the config file");
+
+	read_conf(progname);
+
+	if (!service_open_path_listed("ext4", "/dev/sda"))
+		return fail(test, "/dev/sd* did not match /dev/sda");
+	if (!service_open_path_listed("ext4", "/dev/nvme0n1"))
+		return fail(test, "a second ext4 line was not recognised");
+	if (!service_open_path_listed("ext4", "/srv/indented.img"))
+		return fail(test, "an indented line was not recognised");
+	if (service_open_path_listed("ext4", "/dev/sda/x"))
+		return fail(test, "* matched a /");
+	if (service_open_path_listed("xfs", "/dev/sda"))
+		return fail(test, "an ext4 line matched for xfs");
+	if (!service_open_path_listed("ext4", "/proc/pressure") ||
+	    !service_open_path_listed("xfs", "/proc/pressure"))
+		return fail(test, "a \"*\" subtype did not match every subtype");
+	if (service_open_path_listed("ext4", "relative/path"))
+		return fail(test, "a relative pattern was accepted");
+	if (!service_open_path_listed("xfs", "/srv/xfs.img"))
+		return fail(test, "a tab-separated line was not recognised");
+	if (!service_open_path_listed("xfs", "/srv/img/a.img"))
+		return fail(test, "/srv/img/* did not match /srv/img/a.img");
+	if (service_open_path_listed("xfs", "/srv/img/..") ||
+	    service_open_path_listed("xfs", "/srv/img/."))
+		return fail(test, "a . or .. component was accepted");
+	/* Either line, if stored, would match the empty path */
+	if (service_open_path_listed("", ""))
+		return fail(test, "a line without a subtype was accepted");
+	if (service_open_path_listed("ext4", ""))
+		return fail(test, "a line without a pattern was accepted");
+
+	if (write_conf("\n") == -1)
+		return fail(test, "could not write the config file");
+
+	read_conf(progname);
+
+	if (service_open_path_listed("ext4", "/dev/sda"))
+		return fail(test, "a line survived re-reading the config");
+
+	printf("PASS: %s\n", test);
+	return 0;
+}
+
 int main(void)
 {
 	char tempdir[] = "/tmp/test_fuser_conf.XXXXXX";
@@ -123,6 +180,8 @@ int main(void)
 		goto out_unlink;
 	if (test_trimmed_options())
 		goto out_unlink;
+	if (test_service_open_path())
+		goto out_unlink;
 
 	printf("All fuse.conf parser tests passed\n");
 	result = 0;
diff --git a/util/fuse.conf b/util/fuse.conf
index ab048e0347b2..fb9ac5ff84e2 100644
--- a/util/fuse.conf
+++ b/util/fuse.conf
@@ -15,3 +15,15 @@
 # equals sign).
 
 #mount_max = 1000
+
+
+# service_open_path = <subtype> <pattern> - a FUSE server that runs as a socket
+# service may ask fuservicemount3 to open paths that match <pattern>, in
+# addition to the paths on the mount command line. <subtype> is the filesystem
+# type after "fuse.", or "*" to match every subtype. <pattern> an absolute
+# path in which "*" does not match "/". The line can be repeated to allow
+# different patterns and subtypes.
+# A pattern that matches a directory gives the server every file below it.
+
+#service_open_path = ext4 /dev/sd*
+#service_open_path = ext4 /dev/nvme*
diff --git a/util/fuser_conf.c b/util/fuser_conf.c
index 12688f6c42b7..35e4bb561db4 100644
--- a/util/fuser_conf.c
+++ b/util/fuser_conf.c
@@ -18,6 +18,7 @@
 #include <stdio.h>
 #include <stdlib.h>
 #include <errno.h>
+#include <fnmatch.h>
 #include <mntent.h>
 #include <unistd.h>
 #include <sys/fsuid.h>
@@ -35,6 +36,14 @@ int mount_max = 1000;
 static uid_t oldfsuid;
 static gid_t oldfsgid;
 
+struct service_open_path {
+	struct service_open_path *next;
+	char *subtype;
+	char *pattern;
+};
+
+static struct service_open_path *service_open_paths;
+
 // Older versions of musl libc don't unescape entries in /etc/mtab
 
 // unescapes octal sequences like \040 in-place
@@ -192,12 +201,107 @@ static void strip_line(char *line)
 		memmove(line, s, strlen(s)+1);
 }
 
+/*
+ * Store one service_open_path line. For the line
+ * "service_open_path = ext4 /dev/sd*", str is "ext4 /dev/sd*".
+ */
+static void parse_service_open_path(const char *str, int linenum,
+				    const char *progname)
+{
+	/* <subtype> ends at the first blank */
+	const size_t subtype_len = strcspn(str, " \t");
+	const char *pattern = str + subtype_len;
+	struct service_open_path *entry;
+
+	/* The rest of the line is <pattern>, blanks inside it included */
+	pattern += strspn(pattern, " \t");
+	/* A relative pattern would depend on each user's working directory */
+	if (!subtype_len || pattern[0] != '/') {
+		fprintf(stderr,
+			"%s: invalid service_open_path in %s at line %i\n",
+			progname, FUSE_CONF, linenum);
+		return;
+	}
+
+	entry = calloc(1, sizeof(*entry));
+	if (entry) {
+		entry->subtype = strndup(str, subtype_len);
+		entry->pattern = strdup(pattern);
+	}
+	/* Going on without the line would refuse paths the admin allowed */
+	if (!entry || !entry->subtype || !entry->pattern) {
+		fprintf(stderr, "%s: failed to allocate memory\n", progname);
+		exit(1);
+	}
+
+	/* Order does not matter, the lookup checks every entry */
+	entry->next = service_open_paths;
+	service_open_paths = entry;
+}
+
+/* The config can be read more than once; drop the lines of the last read */
+static void free_service_open_paths(void)
+{
+	while (service_open_paths) {
+		struct service_open_path *entry = service_open_paths;
+
+		service_open_paths = entry->next;
+		free(entry->subtype);
+		free(entry->pattern);
+		free(entry);
+	}
+}
+
+/* @return true if a path component is "." or "..", as in "/srv/img/.." */
+static bool has_dot_component(const char *path)
+{
+	const char *comp = path;
+
+	for (;;) {
+		const size_t len = strcspn(comp, "/");
+
+		if ((len == 1 && comp[0] == '.') ||
+		    (len == 2 && comp[0] == '.' && comp[1] == '.'))
+			return true;
+		if (!comp[len])
+			return false;
+		comp += len + 1;
+	}
+}
+
+bool service_open_path_listed(const char *subtype, const char *path)
+{
+	const struct service_open_path *entry;
+
+	/* "*" also matches "..", which reaches the parent directory */
+	if (has_dot_component(path))
+		return false;
+
+	/*
+	 * subtype is whatever the untrusted client passed to fuservicemount
+	 * -t; it is never checked against the actual filesystem, so "*"
+	 * grants nothing a client could not already get by naming a subtype
+	 * that has its own allow-list entry.
+	 */
+	for (entry = service_open_paths; entry; entry = entry->next)
+		if ((!strcmp(entry->subtype, "*") ||
+		     !strcmp(entry->subtype, subtype)) &&
+		    !fnmatch(entry->pattern, path, FNM_PATHNAME))
+			return true;
+
+	return false;
+}
+
 static void parse_line(const char *line, int linenum, const char *progname)
 {
 	int tmp;
+	int value_pos = -1;
 
 	if (strcmp(line, "user_allow_other") == 0)
 		user_allow_other = 1;
+	else if (sscanf(line, "service_open_path = %n", &value_pos) == 0 &&
+		 value_pos >= 0)
+		parse_service_open_path(line + value_pos, linenum, progname);
 	else if (sscanf(line, "mount_max = %i", &tmp) == 1) {
 		if (tmp < -1)
 			fprintf(stderr,
@@ -216,6 +320,8 @@ void read_conf(const char *progname)
 {
 	FILE *fp = fopen(FUSE_CONF, "r");
 
+	free_service_open_paths();
+
 	if (fp != NULL) {
 		int linenum = 1;
 		char line[256];
diff --git a/util/fuser_conf.h b/util/fuser_conf.h
index ea58537cc4c2..ccfc58877100 100644
--- a/util/fuser_conf.h
+++ b/util/fuser_conf.h
@@ -8,6 +8,7 @@
 #ifndef FUSER_CONF_H_
 #define FUSER_CONF_H_
 
+#include <stdbool.h>
 #include <sys/vfs.h>
 #include <sys/stat.h>
 
@@ -40,6 +41,8 @@ int count_fuse_fs(const char *progname);
 
 void read_conf(const char *progname);
 
+bool service_open_path_listed(const char *subtype, const char *path);
+
 void drop_privs(void);
 void restore_privs(void);
 
diff --git a/util/mount_service.c b/util/mount_service.c
index 446f37f61916..b4081d53273e 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -847,13 +847,16 @@ static int mount_service_open_path(const struct mount_service *mo,
 	}
 
 	/*
-	 * The file is opened outside the service sandbox, so report a path
-	 * the user did not name.
+	 * The file is opened outside the service sandbox, so only hand out
+	 * what the user named or fuse.conf lists.
 	 */
 	if (!arg_in_cmdline(argc, argv, oc->path) &&
-	    !option_value_in_cmdline(argc, argv, oc->path))
-		fprintf(stderr, "%s: %s: warning: file not in command line arguments\n",
-			mo->msgtag, oc->path);
+	    !option_value_in_cmdline(argc, argv, oc->path) &&
+	    !service_open_path_listed(mo->subtype, oc->path)) {
+		fprintf(stderr, "%s: %s: file must be in command line arguments or in %s\n",
+			mo->msgtag, oc->path, FUSE_CONF);
+		return mount_service_send_file_error(mo, EPERM, oc->path);
+	}
 
 	open_flags = ntohl(oc->open_flags) | O_CLOEXEC;
 	drop_privs();

-- 
2.53.0

