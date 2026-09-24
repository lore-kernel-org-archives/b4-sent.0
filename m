From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:30 +0200
Subject: [PATCH 02/10] mount_service: open only paths named on the command
 line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-2-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=5650; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=P2CSGcAfv6+PvrZYNqdiqGQFVx+i35br17hQxuU+n3Q=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2LnpyYafzJcGe04XPP1pPFHPbvHLC1LzNiyo9g9VmO
 lbmbD5e1VHKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQATqctmZJj94l06x/d77xl9
 hTzFdsd0LhS4wH5XOGHnD37nd1FvOU0Y/oqEaZj1c0p1KjTfYL1UUZjTdvqrrOaikDMqDGv/vRI
 L4wcA
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

The helper opened any path the server sent. An attacker who controlled
the server could use this to read every file the user can read, for
example ~/.ssh/id_ed25519, and the sandbox did not prevent it. The
helper now compares the requested path with the arguments it was
started with. For "mount -t fuse.service_ll /srv/disk.img /mnt", these
include "/srv/disk.img" and "/mnt". The helper opens the path only if
the string is equal to one of these arguments, so the server can open
only a file that the user named when mounting. The helper already made
the same check for the mount point.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 doc/fuservicemount3.8  |  4 ++++
 include/fuse_service.h |  5 ++++-
 util/mount_service.c   | 29 ++++++++++++++++++++++-------
 3 files changed, 30 insertions(+), 8 deletions(-)

diff --git a/doc/fuservicemount3.8 b/doc/fuservicemount3.8
index aa2167cb4872..06755d7c3c4e 100644
--- a/doc/fuservicemount3.8
+++ b/doc/fuservicemount3.8
@@ -19,6 +19,10 @@ Mount a filesystem using a FUSE server that runs as a socket service.
 These servers can be contained using the platform's service management
 framework.
 
+The FUSE server may ask fuservicemount3 to open files on its behalf.
+fuservicemount3 opens only paths that appear verbatim on its command line
+and refuses any other request with EPERM.
+
 The second form checks if there is a FUSE service available for the given
 filesystem type.
 .SH "AUTHORS"
diff --git a/include/fuse_service.h b/include/fuse_service.h
index d6aedea8f0f8..3954f62aa2b8 100644
--- a/include/fuse_service.h
+++ b/include/fuse_service.h
@@ -139,6 +139,8 @@ int fuse_service_parse_cmdline_opts(struct fuse_args *args,
 
 /**
  * Ask the mount.service helper to open a file on behalf of the fuse server.
+ * The helper refuses a path that is not verbatim on the mount command line;
+ * fuse_service_receive_file() then reports -EPERM.
  *
  * @param sf service context
  * @param path the path to file
@@ -153,7 +155,8 @@ int fuse_service_request_file(const struct fuse_service *sf, const char *path,
 
 /**
  * Ask the mount.service helper to open a block device on behalf of the fuse
- * server.
+ * server.  The path must be verbatim on the mount command line, as for a
+ * file request.
  *
  * @param sf service context
  * @param path the path to file
diff --git a/util/mount_service.c b/util/mount_service.c
index 7549e0b5024f..835d3d94aa4a 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -772,7 +772,8 @@ static bool arg_in_cmdline(int argc, const char * const argv[],
 
 static int mount_service_open_path(const struct mount_service *mo,
 				   mode_t expected_fmt,
-				   struct fuse_service_packet *p, size_t psz)
+				   struct fuse_service_packet *p, size_t psz,
+				   int argc, const char * const argv[])
 {
 	const struct fuse_service_open_command *oc =
 			container_of(p, struct fuse_service_open_command, p);
@@ -800,6 +801,16 @@ static int mount_service_open_path(const struct mount_service *mo,
 		return mount_service_send_file_error(mo, EINVAL, oc->path);
 	}
 
+	/*
+	 * The file is opened outside the service sandbox, so only hand out
+	 * what the user named.
+	 */
+	if (!arg_in_cmdline(argc, argv, oc->path)) {
+		fprintf(stderr, "%s: %s: file must be in command line arguments\n",
+			mo->msgtag, oc->path);
+		return mount_service_send_file_error(mo, EPERM, oc->path);
+	}
+
 	open_flags = ntohl(oc->open_flags) | O_CLOEXEC;
 	drop_privs();
 	fd = open(oc->path, open_flags, ntohl(oc->create_mode));
@@ -834,16 +845,18 @@ static int mount_service_open_path(const struct mount_service *mo,
 
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
@@ -1838,10 +1851,12 @@ int mount_service_main(int argc, char *argv[])
 
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

