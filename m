From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:11:00 +0200
Subject: [PATCH v3 06/15] mount.fuse: free the options on the service mount
 return path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-6-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2562; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=gDoDSgMI9gAOrS8CuaxP8AOtiQE/Nkp1TOfH7s24Z0I=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cmV/qM0X5MpxXNhWb2Y1K0l94s9QJcWPRUddi8Rv3
 3RlUuvqKGVhEONgkBVTZOmS2GM75R+frNrX9ddh5rAygQxh4OIUgIk0vmH4w79V8922bsaJ4mx7
 lka0nbxX80D8+FbFte7vZnwv8l7wezojw8k3j0+vOBkXmpopFWHzZlE55+kZ7syHxRvf/U7tD0g
 35gYA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These leaks were detected by the new tests.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 util/mount.fuse.c | 42 ++++++++++++++++++++++++++----------------
 1 file changed, 26 insertions(+), 16 deletions(-)

diff --git a/util/mount.fuse.c b/util/mount.fuse.c
index c67a0c2b7f2f..1414265fd274 100644
--- a/util/mount.fuse.c
+++ b/util/mount.fuse.c
@@ -56,9 +56,7 @@
 #endif
 
 #include "fuse.h"
-#ifdef HAVE_SERVICEMOUNT
-# include "mount_service.h"
-#endif
+#include "mount_service.h"
 
 static char *progname;
 
@@ -396,6 +394,18 @@ out:
 	fuse_opt_free_args(&args);
 	return ret;
 }
+#else
+static int try_service_main(const char *argv0, const char *fstype,
+			    const char *source, const char *mountpoint,
+			    const char *options)
+{
+	(void)argv0;
+	(void)fstype;
+	(void)source;
+	(void)mountpoint;
+	(void)options;
+	return MOUNT_SERVICE_FALLBACK_NEEDED;
+}
 #endif
 
 int main(int argc, char *argv[])
@@ -415,6 +425,7 @@ int main(int argc, char *argv[])
 	int fuse_fd = 0;
 	int drop_privileges = 0;
 	char *dev_fd_mountpoint = NULL;
+	int ret;
 
 	progname = argv[0];
 	basename = strrchr(argv[0], '/');
@@ -608,19 +619,17 @@ int main(int argc, char *argv[])
 	}
 #endif
 
-#ifdef HAVE_SERVICEMOUNT
 	/*
 	 * Now that we know the desired filesystem type, see if we can find
 	 * a socket service implementing that, if we haven't selected any weird
 	 * options that would prevent that.
 	 */
 	if (!pass_fuse_fd && !(setuid_name && setuid_name[0])) {
-		int ret = try_service_main(argv[0], type, source, mountpoint,
-					   options);
+		ret = try_service_main(argv[0], type, source, mountpoint,
+				       options);
 		if (ret != MOUNT_SERVICE_FALLBACK_NEEDED)
-			return ret;
+			goto out;
 	}
-#endif
 
 	add_arg(&command, type);
 	if (source)
@@ -631,17 +640,18 @@ int main(int argc, char *argv[])
 		add_arg(&command, options);
 	}
 
+	execl("/bin/sh", "/bin/sh", "-c", command, NULL);
+	fprintf(stderr, "%s: failed to execute /bin/sh: %s\n", progname,
+		strerror(errno));
+	ret = 1;
+
+out:
+	if (pass_fuse_fd)
+		close(fuse_fd);
 	free(options);
 	free(dev_fd_mountpoint);
 	free(dup_source);
 	free(setuid_name);
-
-	execl("/bin/sh", "/bin/sh", "-c", command, NULL);
-	fprintf(stderr, "%s: failed to execute /bin/sh: %s\n", progname,
-		strerror(errno));
-	
-	if (pass_fuse_fd)
-		close(fuse_fd);
 	free(command);
-	return 1;
+	return ret;
 }

-- 
2.53.0

