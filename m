From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:13 +0200
Subject: [PATCH 10/10] highlevel: Switch fuse_main_real_versioned() to
 fuse_daemonize_early()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-10-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>, Miklos Szeredi <miklos@szeredi.hu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2145; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=CwL4o77lSnyZfSeFpGCE3rBWhucH/pM1dNHMqvfex3g=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca6/ctAj08ajPL1mZlFw6pb7s+we1jKWhhYquz/1n
 JnRdf1qRykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEzkgAjDX6Fm+S0i3UYbr08I
 9b++s2Sbz/uSe9Mm7HEvXNDrmffxzBVGhi3V8+bo+nvsO3TUs+L0wQP1//Z6vKtYdtaUrYRl0aO
 InYwA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For high level we can switch directly in that function to the new daemonize
API. Additionally we need to check if the daemon has already acticated
daemonization to avoid warning messages.

Suggested-by: Miklos Szeredi <miklos@szeredi.hu>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/helper.c | 30 +++++++++++++++++++-----------
 1 file changed, 19 insertions(+), 11 deletions(-)

diff --git a/lib/helper.c b/lib/helper.c
index 4d7c2b7f..15de3fbf 100644
--- a/lib/helper.c
+++ b/lib/helper.c
@@ -260,6 +260,7 @@ int fuse_main_real_versioned(int argc, char *argv[],
 	struct fuse_cmdline_opts opts;
 	int res;
 	struct fuse_loop_config *loop_config = NULL;
+	bool self_daemonize = false;
 
 	if (fuse_parse_cmdline(&args, &opts) != 0)
 		return 1;
@@ -289,6 +290,21 @@ int fuse_main_real_versioned(int argc, char *argv[],
 		goto out1;
 	}
 
+	/* The application might have already started daemonization itself */
+	if (!fuse_daemonize_early_is_active()) {
+		int daemonize_early_flags = 0;
+
+		if (opts.foreground)
+			daemonize_early_flags |= FUSE_DAEMONIZE_NO_BACKGROUND;
+
+		self_daemonize = true;
+		res = fuse_daemonize_early_start(daemonize_early_flags);
+		if (res != 0) {
+			fuse_log(FUSE_LOG_ERR, "fuse: daemonize_early_start failed\n");
+			goto out1;
+		}
+	}
+
 	struct fuse *_fuse_new_31(struct fuse_args *args,
 			       const struct fuse_operations *op, size_t op_size,
 			       struct libfuse_version *version,
@@ -305,22 +321,14 @@ int fuse_main_real_versioned(int argc, char *argv[],
 		goto out2;
 	}
 
-	/*
-	 * fuse_daemonize() already checks and fails then, but we need to
-	 * handle it gracefully here, as this is done libfuse internal
-	 * and caller didn't ask to daemonize with old API.
-	 */
-	if (!fuse_daemonize_early_is_active()) {
-		if (fuse_daemonize(opts.foreground) != 0) {
-			res = 5;
-			goto out3;
-		}
-	}
 	if (fuse_set_signal_handlers(se) != 0) {
 		res = 6;
 		goto out3;
 	}
 
+	if (self_daemonize)
+		fuse_daemonize_early_success();
+
 	if (opts.singlethread)
 		res = fuse_loop(fuse);
 	else {

-- 
2.53.0

