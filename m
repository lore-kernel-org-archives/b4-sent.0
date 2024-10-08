From: Caleb White <cdwhite3@pm.me>
Date: Mon, 07 Oct 2024 22:12:32 -0500
Subject: [PATCH v3 3/3] worktree: add test for path handling in linked
 worktrees
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241007-wt_relative_paths-v3-3-622cf18c45eb@pm.me>
References: <20241007-wt_relative_paths-v3-0-622cf18c45eb@pm.me>
In-Reply-To: <20241007-wt_relative_paths-v3-0-622cf18c45eb@pm.me>
To: git@vger.kernel.org
Cc: Caleb White <cdwhite3@pm.me>, Eric Sunshine <sunshine@sunshineco.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1555; i=cdwhite3@pm.me;
 h=from:subject:message-id; bh=jVeMwSXz6V0Ws/FxdC9tKiKw+TrVE9J7E72QZFqsvs8=;
 b=owGbwMvMwCVmxF73kO8jewrjabUkhnSWxVp7CgqDDsxcWDfJavOX6bI1CQfvX1375p7Rgsv8n
 //+P9y2sKOUhUGMi0FWTJHlzdbvBeqpjzO4P5TPhpnDygQyhIGLUwAmsv0Bw/942frqfb9W5nnc
 cHkdsMZsfc26KIeVX3a85/+uKTZ1s/hTRoY/rX0N29qWnVn8ckXpFgnB4weSzi1WWj+PYWn4r2+
 CUz14AQ==
X-Developer-Key: i=cdwhite3@pm.me; a=openpgp;
 fpr=99981A649E1CA829A335E77493EDE5A0C788BC38
X-Endpoint-Received: by B4 Relay for cdwhite3@pm.me/default with auth_id=237
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A failure scenario reported in an earlier patch series[1] that several
`git worktree` subcommands failed or misbehaved when invoked from within
linked worktrees that used relative paths.

This adds a test that executes a `worktree prune` command inside both an
internally and an externally linked worktree and asserts that the other
worktree was not pruned.

[1]: https://lore.kernel.org/git/CAPig+cQXFy=xPVpoSq6Wq0pxMRCjS=WbkgdO+3LySPX=q0nPCw@mail.gmail.com/

Reported-by: Eric Sunshine <sunshine@sunshineco.com>
Signed-off-by: Caleb White <cdwhite3@pm.me>
---
 t/t2401-worktree-prune.sh | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/t/t2401-worktree-prune.sh b/t/t2401-worktree-prune.sh
index 71aa9bcd620f8a504fe628a2d7332d8b47fd4701..976d048e3efc74be9cd909ce76d552b3944d2e10 100755
--- a/t/t2401-worktree-prune.sh
+++ b/t/t2401-worktree-prune.sh
@@ -120,4 +120,23 @@ test_expect_success 'prune duplicate (main/linked)' '
 	! test -d .git/worktrees/wt
 '
 
+test_expect_success 'not prune proper worktrees when run inside linked worktree' '
+	test_when_finished rm -rf repo wt_ext &&
+	git init repo &&
+	(
+	    cd repo &&
+	    echo content >file &&
+	    git add file &&
+	    git commit -m msg &&
+	    git worktree add ../wt_ext &&
+	    git worktree add wt_int &&
+	    cd wt_int &&
+	    git worktree prune -v >out &&
+	    test_must_be_empty out &&
+	    cd ../../wt_ext &&
+	    git worktree prune -v >out &&
+	    test_must_be_empty out
+	)
+'
+
 test_done

-- 
2.46.2

