From: Chen Linxuan <me@black-desk.cn>
Date: Wed, 01 Apr 2026 15:33:41 +0800
Subject: [PATCH 1/3] config: add "worktree" and "worktree/i" includeIf
 conditions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-includeif-worktree-v1-1-906db69f2c79@black-desk.cn>
References: <20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn>
In-Reply-To: <20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn>
To: git@vger.kernel.org
Cc: Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3883; i=me@black-desk.cn;
 h=from:subject:message-id; bh=kaFWC9wBISxy3RLvDFRPmLRUew78/tUn1vwIu1C4hEE=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpzMp2cM8+vn625kfXIE5OFKG5xG4i7TPRZMpb/
 8gZRajr3cmJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaczKdgAKCRB2HuYUOZmu
 izLGEAC0x0WK+uNP7crQXgXKc2J5U3/xnp63EJ4GG4TWSHuQq393pmxJ02ig6ORksuRXFUuNrG8
 DQsi4Sb00PCMpu/tZp5hpqZQioHg89JvKxPuo9a8CKW5AlT2w/Kw1lfJgFAhIqnsf7L8wsihD7z
 IbdPQqfcgqzQXjEjBn2+E8nnjggD8sAVnQhAwtRM3L0w3WA8HbCuSx0pq+UqPaVCDJLSYtN5G6M
 7mizHM+ZiFUMjW35WFc5rcJcTKY64e8xSAlHI5q0FSvx3sfDbsrFJfYAtlhAyAXsU6kMamTp2iF
 4M2v0dz+x+YLUiBtFoeitWb+ZOaaaEKJV9tQ41H7mOT8xWB1mDLSKeQzDpEDTX+OmcseSO9grFH
 ni3gWNwtkygmQQ44KVBW5AaaPSwrNL5R0ceTtBlXGsvcu/mmOstB1/VdIJbRyA9BBJ6wmtfhJOh
 VJIoFgkeBfKbViDMXcQRtQAJcZoXT7h9sGzmY2rub9DxnvUyzRFYI0H7p/VbcVPIxrUA2JcOd4Y
 qM8KupbYQgjTzvHi/jGw5gmMFrXLK6sdQBsOtzsxHHhwW/Hu3VbI4at1uqto6UhYrs9uzNg899J
 V17OEOFNEC8HQC9q4AZGv3mDqGD+s3KJCOv1/gByZz2fh5mbMXxTPsetzwJuCrgdldryJMaKYUd
 BQq1Vqh19qFJetw==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `includeIf` mechanism already supports matching on the `.git`
directory path (`gitdir`) and the currently checked out branch
(`onbranch`).  But in multi-worktree setups the `.git` directory of a
linked worktree points into the main repository's `.git/worktrees/`
area, which makes `gitdir` patterns cumbersome when one wants to
include config based on the working tree's checkout path instead.

Introduce two new condition keywords:

  - `worktree:<pattern>` matches the realpath of the current worktree's
    working directory (i.e. `repo_get_work_tree()`) against a glob
    pattern.  This is the path returned by `git rev-parse
    --show-toplevel`.

  - `worktree/i:<pattern>` is the case-insensitive variant.

The implementation follows the same structure as `include_by_gitdir()`:
the worktree path is resolved via `strbuf_realpath()`, the condition
pattern is prepared with `prepare_include_condition_pattern()` (which
handles `~` expansion, `./` relative paths, `**/` prefix insertion and
trailing-`/` expansion), and matching is done with `wildmatch()`.  A
second attempt using `strbuf_add_absolute_path()` is performed to
handle symlinked paths.

The condition never matches in bare repositories (where there is no
worktree) or during early config reading (where no repository is
available).
---
 config.c | 25 ++++++++++++++-----------
 1 file changed, 14 insertions(+), 11 deletions(-)

diff --git a/config.c b/config.c
index 156f2a24fa00..6d0c2d0725e4 100644
--- a/config.c
+++ b/config.c
@@ -235,23 +235,20 @@ static int prepare_include_condition_pattern(const struct key_value_info *kvi,
 	return 0;
 }
 
-static int include_by_gitdir(const struct key_value_info *kvi,
-			     const struct config_options *opts,
-			     const char *cond, size_t cond_len, int icase)
+static int include_by_path(const struct key_value_info *kvi,
+			   const char *path,
+			   const char *cond, size_t cond_len, int icase)
 {
 	struct strbuf text = STRBUF_INIT;
 	struct strbuf pattern = STRBUF_INIT;
 	size_t prefix;
 	int ret = 0;
-	const char *git_dir;
 	int already_tried_absolute = 0;
 
-	if (opts->git_dir)
-		git_dir = opts->git_dir;
-	else
+	if (!path)
 		goto done;
 
-	strbuf_realpath(&text, git_dir, 1);
+	strbuf_realpath(&text, path, 1);
 	strbuf_add(&pattern, cond, cond_len);
 	ret = prepare_include_condition_pattern(kvi, &pattern, &prefix);
 	if (ret < 0)
@@ -284,7 +281,7 @@ static int include_by_gitdir(const struct key_value_info *kvi,
 		 * which'll do the right thing
 		 */
 		strbuf_reset(&text);
-		strbuf_add_absolute_path(&text, git_dir);
+		strbuf_add_absolute_path(&text, path);
 		already_tried_absolute = 1;
 		goto again;
 	}
@@ -400,9 +397,15 @@ static int include_condition_is_true(const struct key_value_info *kvi,
 	const struct config_options *opts = inc->opts;
 
 	if (skip_prefix_mem(cond, cond_len, "gitdir:", &cond, &cond_len))
-		return include_by_gitdir(kvi, opts, cond, cond_len, 0);
+		return include_by_path(kvi, opts->git_dir, cond, cond_len, 0);
 	else if (skip_prefix_mem(cond, cond_len, "gitdir/i:", &cond, &cond_len))
-		return include_by_gitdir(kvi, opts, cond, cond_len, 1);
+		return include_by_path(kvi, opts->git_dir, cond, cond_len, 1);
+	else if (skip_prefix_mem(cond, cond_len, "worktree:", &cond, &cond_len))
+		return include_by_path(kvi, inc->repo ? repo_get_work_tree(inc->repo) : NULL,
+				       cond, cond_len, 0);
+	else if (skip_prefix_mem(cond, cond_len, "worktree/i:", &cond, &cond_len))
+		return include_by_path(kvi, inc->repo ? repo_get_work_tree(inc->repo) : NULL,
+				       cond, cond_len, 1);
 	else if (skip_prefix_mem(cond, cond_len, "onbranch:", &cond, &cond_len))
 		return include_by_branch(inc, cond, cond_len);
 	else if (skip_prefix_mem(cond, cond_len, "hasconfig:remote.*.url:", &cond,

-- 
2.53.0

