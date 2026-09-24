From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 25 Sep 2026 00:23:29 +0200
Subject: [PATCH 01/10] mount_service: move the command line check into
 arg_in_cmdline()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-mount-service-bound-open-v1-1-bbf1a84c7995@bsbernd.com>
References: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
In-Reply-To: <20260925-mount-service-bound-open-v1-0-bbf1a84c7995@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1922; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=wuQi+/gnpOxzYsO4UTEWLR5x15IeF2nd5B2RO4Na2EM=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK2Lnqclvq0Y+OnHdlRUw89qOWVX1C1wax37r7HD5W0c
 28cuagq2VHKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQAT4Wtg+F+nZNkitbbdyIzR
 4aJyqKjdxfkPjn2YFXtypu+fizdO/vjB8M+iLfmSzbfJiZ5HfdNsq3/Ja1TbrWUQNLvN1yPV2PH
 /CCcA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mount_service_handle_mountpoint_cmd() compared the mount point with
each argument of fuservicemount3 in its own loop. The next patch makes
the same check for OPEN requests, so the loop moves into
arg_in_cmdline(). There is no change in behaviour.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 util/mount_service.c | 22 +++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

diff --git a/util/mount_service.c b/util/mount_service.c
index 0b3266309a8a..7549e0b5024f 100644
--- a/util/mount_service.c
+++ b/util/mount_service.c
@@ -758,6 +758,18 @@ static int prepare_bdev(const struct mount_service *mo,
 	return 0;
 }
 
+static bool arg_in_cmdline(int argc, const char * const argv[],
+			   const char *value)
+{
+	int i;
+
+	for (i = 0; i < argc; i++)
+		if (!strcmp(argv[i], value))
+			return true;
+
+	return false;
+}
+
 static int mount_service_open_path(const struct mount_service *mo,
 				   mode_t expected_fmt,
 				   struct fuse_service_packet *p, size_t psz)
@@ -1248,8 +1260,6 @@ static int mount_service_handle_mountpoint_cmd(struct mount_service *mo,
 			container_of(p, struct fuse_service_mountpoint_command, p);
 	char *mntpt;
 	mode_t expected_fmt;
-	bool foundit = false;
-	int i;
 
 	if (psz < sizeof_fuse_service_mountpoint_command(1)) {
 		fprintf(stderr, "%s: mount point command too small\n",
@@ -1289,13 +1299,7 @@ static int mount_service_handle_mountpoint_cmd(struct mount_service *mo,
 	}
 
 	/* Mountpoint must be mentioned in the caller's argument list */
-	for (i = 0; i < argc; i++) {
-		if (!strcmp(argv[i], oc->value)) {
-			foundit = true;
-			break;
-		}
-	}
-	if (!foundit) {
+	if (!arg_in_cmdline(argc, argv, oc->value)) {
 		fprintf(stderr, "%s: mount point must be in command line arguments\n",
 			mo->msgtag);
 		return mount_service_send_reply(mo, EINVAL);

-- 
2.53.0

