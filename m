From: Chen Linxuan <me@black-desk.cn>
Date: Wed, 13 May 2026 16:08:18 +0800
Subject: [PATCH v4 2/2] config: add "worktree" and "worktree/i" includeIf
 conditions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-includeif-worktree-v4-2-f8e6212d1fba@black-desk.cn>
References: <20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn>
In-Reply-To: <20260513-includeif-worktree-v4-0-f8e6212d1fba@black-desk.cn>
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Patrick Steinhardt <ps@pks.im>, 
 Chen Linxuan <me@black-desk.cn>, Phillip Wood <phillip.wood@dunelm.org.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=9954; i=me@black-desk.cn;
 h=from:subject:message-id; bh=4asP6lVcMdembpDz0JAZxnc8dwJgedXOJ0hGYnBPjHs=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqBDGVNw+ilw8cz7JKooibnW45EppV2HFylgF/R
 yQI8WyZaMiJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCagQxlQAKCRB2HuYUOZmu
 i4RgEADBcPwq7RcOE/nnlqORfXY/gjd+Y2bEcqADc6cK1e2oRqEKaAAqVm9miLCzKIbn8uLsydv
 BIAfxmjaAHSo6PdVGCyBUG+UnUwHeloa/5P1DMc1wzqoDTBJszqmr7ApcRBdoODky561rWFYWmL
 v9O1bR4331SqEWguMDoMf1V3u1Zcg2krR3BmZ9GK3fmQBH7aorp3uOCWTCKsYpCpubsCXyK4BTx
 ITLZpQVRvn4Uq9Oq0r5TBhHO6c5CLLfPC0Sn2f2Fq27BBalddmgTe+gd7LtVPjUonyssrVMb4Bf
 G2KNQbBbEgEFUlgw7ZdPIRuq2khO4C16aL1zlDKCKZ+maphDJRPk/Z0+yD6tfoNPw3NPLiLAO5M
 2cmdrpstSiJRWYHeSk9iThhNZivDrRxivNahH5DsVsZPZuPJwwgsEzvWkONFMV5m/lh2G526ItO
 kmeepXjOBafbVZPEtsLhwCmRDLJy0oGzFa6tDq3rdTutVFuKx/LwOb+9NF9axbs37vrGtNxG5Tk
 vd7AAX18760HNbt/baZNYVzbrUY6wxd8XbnYKY+RTyQxzpK9vT/aVlAUKPMtiNH0aAN34ckcmos
 UHLfz4X6qFL4wpqusr+Egc8VanggGhyeBoPEMQj0Ix9Hdo5ctie5XsIUNRXIKI1dMoZr3K5yf2/
 TYcc/o8a8WBWUjg==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The includeIf mechanism already supports matching on the .git
directory path (gitdir) and the currently checked out branch
(onbranch).  But in multi-worktree setups the .git directory of a
linked worktree points into the main repository's .git/worktrees/
area, which makes gitdir patterns cumbersome when one wants to
include config based on the working tree's checkout path instead.

Introduce two new condition keywords:

  - worktree:<pattern> matches the realpath of the current worktree's
    working directory (i.e. repo_get_work_tree()) against a glob
    pattern.  This is the path returned by git rev-parse
    --show-toplevel.

  - worktree/i:<pattern> is the case-insensitive variant.

The implementation reuses the include_by_path() helper introduced in
the previous commit, passing the worktree path in place of the
gitdir.  The condition never matches in bare repositories (where
there is no worktree) or during early config reading (where no
repository is available).

Add documentation describing the new conditions, including a comparison
with extensions.worktreeConfig.  Add tests covering bare repositories,
multiple worktrees, symlinked worktree paths, case-insensitive matching,
early config reading, and non-repository scenarios.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 Documentation/config.adoc |  48 ++++++++++++++++++++
 config.c                  |   6 +++
 t/t1305-config-include.sh | 113 ++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 167 insertions(+)

diff --git a/Documentation/config.adoc b/Documentation/config.adoc
index 62eebe7c5450..6299b1e3a019 100644
--- a/Documentation/config.adoc
+++ b/Documentation/config.adoc
@@ -146,6 +146,46 @@ refer to linkgit:gitignore[5] for details. For convenience:
 	This is the same as `gitdir` except that matching is done
 	case-insensitively (e.g. on case-insensitive file systems)
 
+`worktree`::
+	The data that follows the keyword `worktree` and a colon is used as a
+	glob pattern. If the working directory of the current worktree matches
+	the pattern, the include condition is met.
++
+The worktree location is the path where files are checked out (as returned
+by `git rev-parse --show-toplevel`). This is different from `gitdir`, which
+matches the `.git` directory path. In a linked worktree, the worktree path
+is the directory where that worktree's files are located, not the main
+repository's `.git` directory.
++
+The pattern uses the same glob syntax as `gitdir` (including `~/`, `./`,
+`**/`, and trailing-`/` prefix matching). This condition will never match
+in a bare repository (which has no worktree).
++
+This is useful when you want to apply configuration based on where the
+working tree is located on the filesystem. For example, a contributor who
+works on the same project both personally and as an employee can use
+different `user.name` and `user.email` values depending on which directory
+the worktree is checked out under:
++
+----
+[includeIf "worktree:/home/user/work/"]
+    path = ~/.config/git/work.inc
+[includeIf "worktree:/home/user/personal/"]
+    path = ~/.config/git/personal.inc
+----
++
+While `extensions.worktreeConfig` (see linkgit:git-worktree[1]) also supports
+per-worktree configuration, it stores the config inside each repository's
+`.git/config.worktree` file and requires running `git config --worktree`
+inside each worktree individually. In contrast, `includeIf "worktree:..."`
+can be set once in a global or system-level configuration file (e.g.
+`~/.config/git/config`) and applies to all repositories at once based on
+their worktree location.
+
+`worktree/i`::
+	This is the same as `worktree` except that matching is done
+	case-insensitively (e.g. on case-insensitive file systems)
+
 `onbranch`::
 	The data that follows the keyword `onbranch` and a colon is taken to be a
 	pattern with standard globbing wildcards and two additional
@@ -244,6 +284,14 @@ Example
 [includeIf "gitdir:~/to/group/"]
 	path = /path/to/foo.inc
 
+; include if the worktree is at /path/to/project-build
+[includeIf "worktree:/path/to/project-build"]
+	path = build-config.inc
+
+; include for all worktrees inside /path/to/group
+[includeIf "worktree:/path/to/group/"]
+	path = group-config.inc
+
 ; relative paths are always relative to the including
 ; file (if the condition is true); their location is not
 ; affected by the condition
diff --git a/config.c b/config.c
index 7d5dae0e8450..6d0c2d0725e4 100644
--- a/config.c
+++ b/config.c
@@ -400,6 +400,12 @@ static int include_condition_is_true(const struct key_value_info *kvi,
 		return include_by_path(kvi, opts->git_dir, cond, cond_len, 0);
 	else if (skip_prefix_mem(cond, cond_len, "gitdir/i:", &cond, &cond_len))
 		return include_by_path(kvi, opts->git_dir, cond, cond_len, 1);
+	else if (skip_prefix_mem(cond, cond_len, "worktree:", &cond, &cond_len))
+		return include_by_path(kvi, inc->repo ? repo_get_work_tree(inc->repo) : NULL,
+				       cond, cond_len, 0);
+	else if (skip_prefix_mem(cond, cond_len, "worktree/i:", &cond, &cond_len))
+		return include_by_path(kvi, inc->repo ? repo_get_work_tree(inc->repo) : NULL,
+				       cond, cond_len, 1);
 	else if (skip_prefix_mem(cond, cond_len, "onbranch:", &cond, &cond_len))
 		return include_by_branch(inc, cond, cond_len);
 	else if (skip_prefix_mem(cond, cond_len, "hasconfig:remote.*.url:", &cond,
diff --git a/t/t1305-config-include.sh b/t/t1305-config-include.sh
index 6e51f892f320..07b6fb649cd2 100755
--- a/t/t1305-config-include.sh
+++ b/t/t1305-config-include.sh
@@ -396,4 +396,117 @@ test_expect_success 'onbranch without repository but explicit nonexistent Git di
 	test_must_fail nongit git --git-dir=nonexistent config get foo.bar
 '
 
+# worktree: conditional include tests
+
+test_expect_success 'conditional include, worktree bare repo' '
+	git init --bare wt-bare &&
+	(
+		cd wt-bare &&
+		echo "[includeIf \"worktree:/\"]path=bar-bare" >>config &&
+		echo "[test]wtbare=1" >bar-bare &&
+		test_must_fail git config test.wtbare
+	)
+'
+
+test_expect_success 'conditional include, worktree multiple worktrees' '
+	git init wt-multi &&
+	(
+		cd wt-multi &&
+		test_commit initial &&
+		git worktree add -b linked-branch ../wt-linked HEAD &&
+		git worktree add -b prefix-branch ../wt-prefix/linked HEAD
+	) &&
+	wt_main="$(cd wt-multi && pwd)" &&
+	wt_linked="$(cd wt-linked && pwd)" &&
+	wt_prefix_parent="$(cd wt-prefix && pwd)" &&
+	cat >>wt-multi/.git/config <<-EOF &&
+	[includeIf "worktree:$wt_main"]
+		path = main-config
+	[includeIf "worktree:$wt_linked"]
+		path = linked-config
+	[includeIf "worktree:$wt_prefix_parent/"]
+		path = prefix-config
+	EOF
+	echo "[test]mainvar=main" >wt-multi/.git/main-config &&
+	echo "[test]linkedvar=linked" >wt-multi/.git/linked-config &&
+	echo "[test]prefixvar=prefix" >wt-multi/.git/prefix-config &&
+	echo main >expect &&
+	git -C wt-multi config test.mainvar >actual &&
+	test_cmp expect actual &&
+	test_must_fail git -C wt-multi config test.linkedvar &&
+	test_must_fail git -C wt-multi config test.prefixvar &&
+	echo linked >expect &&
+	git -C wt-linked config test.linkedvar >actual &&
+	test_cmp expect actual &&
+	test_must_fail git -C wt-linked config test.mainvar &&
+	test_must_fail git -C wt-linked config test.prefixvar &&
+	echo prefix >expect &&
+	git -C wt-prefix/linked config test.prefixvar >actual &&
+	test_cmp expect actual &&
+	test_must_fail git -C wt-prefix/linked config test.mainvar &&
+	test_must_fail git -C wt-prefix/linked config test.linkedvar
+'
+
+test_expect_success SYMLINKS 'conditional include, worktree resolves symlinks' '
+	mkdir real-wt &&
+	ln -s real-wt link-wt &&
+	git init link-wt/repo &&
+	(
+		cd link-wt/repo &&
+		# repo->worktree resolves symlinks, so use real path in pattern
+		echo "[includeIf \"worktree:**/real-wt/repo\"]path=bar-link" >>.git/config &&
+		echo "[test]wtlink=2" >.git/bar-link &&
+		echo 2 >expect &&
+		git config test.wtlink >actual &&
+		test_cmp expect actual
+	)
+'
+
+test_expect_success 'conditional include, worktree, icase' '
+	git init wt-icase &&
+	(
+		cd wt-icase &&
+		test_commit initial &&
+		wt_path="$(pwd)" &&
+		wt_upper=$(echo "$wt_path" | tr a-z A-Z) &&
+		echo "[includeIf \"worktree/i:$wt_upper\"]path=icase-inc" >>.git/config &&
+		echo "[test]wticase=1" >.git/icase-inc &&
+		echo 1 >expect &&
+		git config test.wticase >actual &&
+		test_cmp expect actual
+	)
+'
+
+# The "worktree" condition cannot match during early config reading
+# because the repository object is not yet fully initialized and
+# repo_get_work_tree() returns NULL.
+test_expect_success 'conditional include, worktree does not match in early config' '
+	git init wt-early &&
+	(
+		cd wt-early &&
+		test_commit initial &&
+		wt_path="$(pwd)" &&
+		echo "[includeIf \"worktree:$wt_path\"]path=early-inc" >>.git/config &&
+		echo "[test]wtearly=1" >.git/early-inc &&
+		test-tool config read_early_config test.wtearly >actual &&
+		test_must_be_empty actual
+	)
+'
+
+test_expect_success 'conditional include, worktree without repository' '
+	test_when_finished "rm -f .gitconfig config.inc" &&
+	git config set -f .gitconfig "includeIf.worktree:/.path" config.inc &&
+	git config set -f config.inc foo.bar baz &&
+	git config get foo.bar &&
+	test_must_fail nongit git config get foo.bar
+'
+
+test_expect_success 'conditional include, worktree without repository but explicit nonexistent Git directory' '
+	test_when_finished "rm -f .gitconfig config.inc" &&
+	git config set -f .gitconfig "includeIf.worktree:/.path" config.inc &&
+	git config set -f config.inc foo.bar baz &&
+	git config get foo.bar &&
+	test_must_fail nongit git --git-dir=nonexistent config get foo.bar
+'
+
 test_done

-- 
2.53.0

