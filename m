From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:10:56 +0200
Subject: [PATCH v3 02/15] mount_service: warn about paths not named on the
 command line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-2-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=5454; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=tlW2RGmk9z+wyqd6HpA1AWICCh0mEz5JcRuPuaBgsBQ=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cmXxmO/dt/ZU865Y7dl1WxfdKmS53M5ddCTwwLYT7
 KHZs3YKd5SyMIhxMMiKKbJ0SeyxnfKPT1bt6/rrMHNYmUCGMHBxCsBEdjMz/FM2+Tv9xmmRpKU7
 dz68Lbm611moa7PMxVuCIROFrhy8um4fw18J76X8QhsNu1lWrtzSyxglprEkaTqL4Vq3vUtE237
 V/mUBAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In a service mount, the fuse server runs as a systemd service in a
sandbox that has no access to the user's files. The user runs mount,
which starts fuservicemount3, a setuid-root helper. The fuse server
sends requests to the helper over a socket. With an OPEN request, the
server asks the helper to open its backing file, for example the disk
image named on the mount command line. The helper opens the file with
the user's credentials and passes the file descriptor to the server.
fusermount3 opens nothing for the fuse server except /dev/fuse; the
server runs as the user and opens its own files.

The helper opens any path the server sends. An attacker who controlled
the server could use this to read every file the user can read, for
example ~/.ssh/id_ed25519, and the sandbox does not prevent it. The
helper now prints a warning if the user did not name the path when
mounting: as a whole argument, as the value of a name=value option, or
glued to a short option as in "-J/dev/sdb1". The helper splits the
options with fuse_opt_parse(), as the fuse server does, so both see the
same option values. The helper still opens the path, because a server
can take a path in a form that none of these checks recognizes.

Enforced permissions follow up in the next commit.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 util/mount_service.c | 73 +++++++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 66 insertions(+), 7 deletions(-)

diff --git a/util/mount_service.c b/util/mount_service.c
index 7549e0b5024f..446f37f61916 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -770,9 +770,55 @@ static bool arg_in_cmdline(int argc, const char * const argv[],
 	return false;
 }
 
+struct option_value_match {
+	const char *path;
+	bool found;
+};
+
+/* fuse_opt_parse() callback: set match->found if the path is this option's value */
+static int match_option_value(void *data, const char *arg, int key,
+			      struct fuse_args *outargs)
+{
+	struct option_value_match *match = data;
+	const char *value = strchr(arg, '=');
+
+	(void) outargs;
+
+	if (key != FUSE_OPT_KEY_OPT)
+		return 0;
+
+	if (value && !strcmp(value + 1, match->path))
+		match->found = true;
+
+	/* Short option with its value glued on, as in "-J/dev/sdb1" */
+	if (arg[0] == '-' && arg[1] && arg[1] != '-' &&
+	    !strcmp(arg + 2, match->path))
+		match->found = true;
+
+	return 0;
+}
+
+/* @return true for the path in "-o name=path", "--name=path" or "-Xpath" */
+static bool option_value_in_cmdline(int argc, const char * const argv[],
+				    const char *path)
+{
+	struct option_value_match match = {
+		.path = path,
+	};
+	struct fuse_args args = FUSE_ARGS_INIT(argc, (char **)argv);
+	int ret;
+
+	/* Parse like the fuse server does, so both see the same values */
+	ret = fuse_opt_parse(&args, &match, NULL, match_option_value);
+	fuse_opt_free_args(&args);
+
+	return !ret && match.found;
+}
+
 static int mount_service_open_path(const struct mount_service *mo,
 				   mode_t expected_fmt,
-				   struct fuse_service_packet *p, size_t psz)
+				   struct fuse_service_packet *p, size_t psz,
+				   int argc, const char * const argv[])
 {
 	const struct fuse_service_open_command *oc =
 			container_of(p, struct fuse_service_open_command, p);
@@ -800,6 +846,15 @@ static int mount_service_open_path(const struct mount_service *mo,
 		return mount_service_send_file_error(mo, EINVAL, oc->path);
 	}
 
+	/*
+	 * The file is opened outside the service sandbox, so report a path
+	 * the user did not name.
+	 */
+	if (!arg_in_cmdline(argc, argv, oc->path) &&
+	    !option_value_in_cmdline(argc, argv, oc->path))
+		fprintf(stderr, "%s: %s: warning: file not in command line arguments\n",
+			mo->msgtag, oc->path);
+
 	open_flags = ntohl(oc->open_flags) | O_CLOEXEC;
 	drop_privs();
 	fd = open(oc->path, open_flags, ntohl(oc->create_mode));
@@ -834,16 +889,18 @@ static int mount_service_open_path(const struct mount_service *mo,
 
 static int mount_service_handle_open_cmd(const struct mount_service *mo,
 					 struct fuse_service_packet *p,
-					 size_t psz)
+					 size_t psz, int argc,
+					 const char * const argv[])
 {
-	return mount_service_open_path(mo, 0, p, psz);
+	return mount_service_open_path(mo, 0, p, psz, argc, argv);
 }
 
 static int mount_service_handle_open_bdev_cmd(const struct mount_service *mo,
 					      struct fuse_service_packet *p,
-					      size_t psz)
+					      size_t psz, int argc,
+					      const char * const argv[])
 {
-	return mount_service_open_path(mo, S_IFBLK, p, psz);
+	return mount_service_open_path(mo, S_IFBLK, p, psz, argc, argv);
 }
 
 #ifdef HAVE_NEW_MOUNT_API
@@ -1838,10 +1895,12 @@ int mount_service_main(int argc, char *argv[])
 
 		switch (ntohl(p->magic)) {
 		case FUSE_SERVICE_OPEN_CMD:
-			ret = mount_service_handle_open_cmd(&mo, p, sz);
+			ret = mount_service_handle_open_cmd(&mo, p, sz,
+					argc, (const char * const *)argv);
 			break;
 		case FUSE_SERVICE_OPEN_BDEV_CMD:
-			ret = mount_service_handle_open_bdev_cmd(&mo, p, sz);
+			ret = mount_service_handle_open_bdev_cmd(&mo, p, sz,
+					argc, (const char * const *)argv);
 			break;
 		case FUSE_SERVICE_FSOPEN_CMD:
 			ret = mount_service_handle_fsopen_cmd(&mo, p, sz);

-- 
2.53.0

