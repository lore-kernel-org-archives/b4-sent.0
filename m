From: Chen Linxuan <me@black-desk.cn>
Date: Wed, 01 Apr 2026 15:33:43 +0800
Subject: [PATCH 3/3] t1305: add tests for includeIf "worktree"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-includeif-worktree-v1-3-906db69f2c79@black-desk.cn>
References: <20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn>
In-Reply-To: <20260401-includeif-worktree-v1-0-906db69f2c79@black-desk.cn>
To: git@vger.kernel.org
Cc: Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3334; i=me@black-desk.cn;
 h=from:subject:message-id; bh=vkzlFuHSi6641zT6zd8IknfSDTILs3Ce3ujOUx+yxws=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpzMp4LF6zNfSELniObOUo61h0uTs6lgwU9WsUA
 SN9DlT14cCJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaczKeAAKCRB2HuYUOZmu
 i71rEADo0J4hDiOpqElLkPvo9EN4IQi3vBA9NpGxpKr9EE9YXLFxx4NcOszva1sRBDL/DiajjLm
 8SkirT2I9hlJ6phrtP7jGWlZA25zaqGKBEbX+wgY57j0095mVFTiDQqalp4esTPxSi2wGxlQocJ
 r/iOHsCn+FX5EvBDFn2Z8Ur60XWcuDeOT/MujzBoRhYc6RCa8PAt4N6ZLgOiKtM9ae7Dl0ETH36
 3uJ6MmMXf+2CNoxw9q4HRs2g1WI65tYcr4MFpVIu8Sh8nWfF4IZDn8BitI59DHp3Wxap50EhZs4
 TLvW8GbkD9hLtfL5zROUjBBF6WRW5IdYww/Qv5Sy+fymlZlR5fADu1SvQBhkuf3nQY3MN4A0vZm
 eGN58Fh6JALTf8Xv8bDR2C8rkAuXDxa6fSprDZtABpu768lY3cGHa1y69GsoWm4ucZabJZe8AQA
 A1spAIHdX7NnLiwbkAHiXniVLqdOVzP6Y7K9Ew9qquYEAeFbgsuiKxn6TTjer6qjR9y/SkGi9bh
 DVdcQMLtKW0F4ALfSzI46A6uC7Z0m80/8rZaS5ZQKURhZPYBVJsteXzUHbzkHpd+Ww1MLu9bS53
 8JN+0meLGkK5P83R5qjL3RMLLpwDF1M0cYv1C1gIAI96/cjMSbSMxkHdErOFNM8YpjKefqRHP6X
 0Au4n5LgfXH7WdA==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover the following scenarios unique to the "worktree" condition
(path matching features such as glob, tilde, icase are already
exercised by the gitdir tests):

  - bare repository (condition must not match)
  - multiple worktrees: main and linked worktrees each match their
    own path-based condition while sharing a single config file;
    a third linked worktree verifies directory-prefix matching with
    a trailing slash
  - symlinked worktree: the path is resolved before matching
---
 t/t1305-config-include.sh | 66 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 66 insertions(+)

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

