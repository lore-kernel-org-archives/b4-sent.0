From: Chen Linxuan <me@black-desk.cn>
Date: Fri, 03 Apr 2026 15:02:29 +0800
Subject: [PATCH v3 2/2] config: add "worktree" and "worktree/i" includeIf
 conditions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-includeif-worktree-v3-2-109ce5782b03@black-desk.cn>
References: <20260403-includeif-worktree-v3-0-109ce5782b03@black-desk.cn>
In-Reply-To: <20260403-includeif-worktree-v3-0-109ce5782b03@black-desk.cn>
To: git@vger.kernel.org
Cc: Kristoffer Haugsbakk <kristofferhaugsbakk@fastmail.com>, 
 Junio C Hamano <gitster@pobox.com>, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=8364; i=me@black-desk.cn;
 h=from:subject:message-id; bh=LLXBGDMHkoNLp+x6l2p49wWLtXSr6y7KaoLztUeAlSU=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpz2YhBH7usWRnMiT82jdplAhZ1mzzxNfCdeCft
 9mYm/gKfK6JAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCac9mIQAKCRB2HuYUOZmu
 iyggEADUOXV8GQBYZM48Jp2ax5uBI3wNTk4tQxdfHhF87BWvBxT2xBY8MzeuzukYoJyLujSM3qw
 DDhgEhyFDPcCgh0k9qv2GETYM6hH6tdDtIUkAM0GWQmOtLYPPb4mYU1eRbiZ0kBUsJL4rXv2/NR
 pI0gPAbvoWpp/L+hD+JMDqoMeEcMggFlFiK0QbMT5coD5ZBonIUzl/JI+srSuQPxpXKWSjUyvno
 D0/xoLaGZOxDeftZWXWO5O3YPuFnujTMlsaB32llWdxtAOQy0vcw6XqTGyGALz/5XhL/dWaLZaD
 WyyAt4U2S2aRdTkpb5E/QVqzMmTPZXcg+iCvU8JN2oGlGJemfGXJBmZfLbYp9i2MtjZMg5zuCPI
 GcCWzqn27OFmAgw9Ui+gtebYtvR7yW0z15QjlOs2UvPCDKbKcCLBZndyC4h722YuzASo+DTEHB7
 oED4jlkW3s3N+EEgClKDgzyU5mavw06vrdzQQdUxp+v2lmemTqTYKBxc4IWO3yOClNDhP927Lna
 WYZH73LA3rib7ivAZcAeTt/sadr8/cPGGFxwTm9oNhHSjCkPgysMZrL0Q5QwDQcUQIkkNPvU9I1
 sRKYXK8szfxh9ZtgnAG28ZvS3pQCae4DNgf3P293dIjZWd4yUVdby+Su6BB6xLt6NKlH3TlNjXO
 OlcHXnC8u7fbwNg==
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

Add documentation describing the new conditions and their supported
pattern features (glob wildcards, **/ and /**, ~ expansion, ./
relative paths, and trailing-/ prefix matching).  Add tests covering
bare repositories, multiple worktrees, and symlinked worktree paths.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 Documentation/config.adoc | 50 +++++++++++++++++++++++++++++++++++
 config.c                  |  6 +++++
 t/t1305-config-include.sh | 66 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 122 insertions(+)

diff --git a/Documentation/config.adoc b/Documentation/config.adoc
index 62eebe7c5450..a4f3ec905098 100644
--- a/Documentation/config.adoc
+++ b/Documentation/config.adoc
@@ -146,6 +146,48 @@ refer to linkgit:gitignore[5] for details. For convenience:
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
+The pattern can contain standard globbing wildcards and two additional
+ones, `**/` and `/**`, that can match multiple path components. Please
+refer to linkgit:gitignore[5] for details. For convenience:
+
+ * If the pattern starts with `~/`, `~` will be substituted with the
+   content of the environment variable `HOME`.
+
+ * If the pattern starts with `./`, it is replaced with the directory
+   containing the current config file.
+
+ * If the pattern does not start with either `~/`, `./` or `/`, `**/`
+   will be automatically prepended. For example, the pattern `foo/bar`
+   becomes `**/foo/bar` and would match `/any/path/to/foo/bar`.
+
+ * If the pattern ends with `/`, `**` will be automatically added. For
+   example, the pattern `foo/` becomes `foo/**`. In other words, it
+   matches "foo" and everything inside, recursively.
++
+This condition will never match in a bare repository (which has no worktree).
++
+This is useful when you need to use different `user.name`, `user.email`, or
+GPG keys in different worktrees of the same repository. While
+`extensions.worktreeConfig` also allows per-worktree configuration, it
+requires changes inside each repository. This condition can be set in the
+user's global configuration file (e.g. `~/.config/git/config`) and applies
+to multiple repositories at once.
+
+`worktree/i`::
+	This is the same as `worktree` except that matching is done
+	case-insensitively (e.g. on case-insensitive file systems)
+
 `onbranch`::
 	The data that follows the keyword `onbranch` and a colon is taken to be a
 	pattern with standard globbing wildcards and two additional
@@ -244,6 +286,14 @@ Example
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
index 6e51f892f320..8a5ba4b884d3 100755
--- a/t/t1305-config-include.sh
+++ b/t/t1305-config-include.sh
@@ -396,4 +396,70 @@ test_expect_success 'onbranch without repository but explicit nonexistent Git di
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
 test_done

-- 
2.53.0

