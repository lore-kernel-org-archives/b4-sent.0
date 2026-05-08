From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:11 +0200
Subject: [PATCH 08/10] fuse_daemonize_early_start: Disallow daemonization
 when already active.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-8-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1075; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=tESQ5ySLyP1XllHdf502CtmW7LSgAeb26aOrfK5xI9Q=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca4LKj7sYKhisdPpi4PJaybL1Ccs/BMPWF363Kn5h
 7u7ivdnRykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEykaQ4jw+87DHX6ntJzbHQ+
 JLL/7e/9lfHsspSNyLM/svPLF9wJcmBkeMpbVd7wpUZSmSXTxjuy9qL9hJT5NXvMc2+zL33mdqW
 fGQA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A coding error could run fuse_daemonize_early_start() two times
and so far the code was not handling/failing that.

Also do not set "active" when it actually does not do daemonization.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/fuse_daemonize.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/lib/fuse_daemonize.c b/lib/fuse_daemonize.c
index c9a91748..8afe4b0d 100644
--- a/lib/fuse_daemonize.c
+++ b/lib/fuse_daemonize.c
@@ -211,18 +211,22 @@ int fuse_daemonize_early_start(unsigned int flags)
 	struct fuse_daemonize *dm = &daemonize;
 	int err = 0;
 
+	if (dm->active)
+		return -EALREADY;
+
 	dm->flags = flags;
 	dm->signal_pipe_wr = -1;
 	dm->death_pipe_rd = -1;
 	dm->stop_pipe_rd = -1;
 	dm->stop_pipe_wr = -1;
-	dm->active = true;
 
 	if (!(flags & FUSE_DAEMONIZE_NO_CHDIR))
 		(void)chdir("/");
 
-	if (!(flags & FUSE_DAEMONIZE_NO_BACKGROUND))
+	if (!(flags & FUSE_DAEMONIZE_NO_BACKGROUND)) {
+		dm->active = true;
 		err = do_daemonize(dm);
+	}
 
 	return err;
 }

-- 
2.53.0

