From: Noam Cohen <noam@noam.me>
Date: Thu, 19 Nov 2026 03:43:01 +0000
Subject: [PATCH v2] ls-tree: do not quote %(path) with -z
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-ls-tree-format-z-verbatim-path-v2-1-c014e4e4c96f@noam.me>
X-B4-Tracking: v=1; b=H4sIAERw/moC/42OQQ6CMBBFr2Jm7RinKlRX3sOwKDiVGkvJtDYq4
 e4CXsDlS17++wNEFscRTqsBhLOLLnQTqPUKmtZ0N0Z3nRjUVhVEpPERMQkz2iDeJPxgZqlNch5
 7k1q0h1Lv6oKs1RamkV7YutcSuFQ/js/6zk2aV2ejdTEFeS8PMs3e37FMSFiSPupS7UkXdO6C8
 RvPUI3j+AXhR0br3AAAAA==
X-Change-ID: 20261118-ls-tree-format-z-verbatim-path-f5783b61ff8f
In-Reply-To: <20261118-ls-tree-format-z-verbatim-path-v1-1-718987241861@noam.me>
References: <20261118-ls-tree-format-z-verbatim-path-v1-1-718987241861@noam.me>
To: git@vger.kernel.org
Cc: Junio C Hamano <gitster@pobox.com>, Teng Long <dyroneteng@gmail.com>, 
 =?utf-8?q?=C3=86var_Arnfj=C3=B6r=C3=B0_Bjarmason?= <avarab@gmail.com>, 
 =?utf-8?q?Ren=C3=A9_Scharfe?= <l.s.r@web.de>, Noam Cohen <noam@noam.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795059791; l=2205;
 i=noam@noam.me; s=20261118; h=from:subject:message-id;
 bh=vgoVj7DmaNqL+zpYiTvi4MOrtN+qceluz1+GNCR8MPM=;
 b=LEI5IdnifZQZ2djQax4CVk2oD9+Hn/nrk5SKW2mpYdaH9Sk/r8l409Z919/CxEaPB+3J8WJj1
 PWktBhqQ0HHCHrlZdd1H966agWs6wOb6X8yxy3BuekPJQWHxMMC6RwN
X-Developer-Key: i=noam@noam.me; a=ed25519;
 pk=qyNqXh2nrM20rNZXIQMjH3jLUPgL/RaLrmNnO0YOpp4=
X-Endpoint-Received: by B4 Relay for noam@noam.me/20261118 with auth_id=1563
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With -z, "git ls-tree" is documented to output the filename verbatim,
but since 455923e0a1 (ls-tree: introduce "--format" option,
2022-03-23) the %(path) placeholder of a custom --format is always
C-quoted.

Output it verbatim when -z is given, like "git ls-files --format"
already does.

Signed-off-by: Noam Cohen <noam@noam.me>
---
This makes "ls-tree -z --format" match "ls-files -z --format", which
already outputs %(path) verbatim.
---
Changes in v2:
- Use a path with a double quote, built with "git mktree", so the test
  stays within US-ASCII and does not depend on the filesystem.
- Force core.quotePath=true in the test.
- Link to v1: https://patch.msgid.link/20261118-ls-tree-format-z-verbatim-path-v1-1-718987241861@noam.me
---
 builtin/ls-tree.c         | 5 ++++-
 t/t3104-ls-tree-format.sh | 9 +++++++++
 2 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/builtin/ls-tree.c b/builtin/ls-tree.c
index 46edaffc2e..d25bbffcdd 100644
--- a/builtin/ls-tree.c
+++ b/builtin/ls-tree.c
@@ -130,7 +130,10 @@ static int show_tree_fmt(const struct object_id *oid, struct strbuf *base,
 
 			strbuf_addstr(base, pathname);
 			name = relative_path(base->buf, prefix, &sbuf);
-			quote_c_style(name, &sb, NULL, 0);
+			if (options->null_termination)
+				strbuf_addstr(&sb, name);
+			else
+				quote_c_style(name, &sb, NULL, 0);
 			strbuf_setlen(base, baselen);
 			strbuf_release(&sbuf);
 		} else
diff --git a/t/t3104-ls-tree-format.sh b/t/t3104-ls-tree-format.sh
index a1b2069a25..0df216909b 100755
--- a/t/t3104-ls-tree-format.sh
+++ b/t/t3104-ls-tree-format.sh
@@ -76,4 +76,13 @@ test_ls_tree_format \
 	"--full-tree" \
 	"--full-tree"
 
+test_expect_success 'ls-tree --format with -z does not quote paths' '
+	blob=$(git rev-parse HEAD:top-file.t) &&
+	tree=$(printf "100644 blob $blob\tdouble\"quote\n" | git mktree) &&
+	printf "blob double\"quote\0" >expect &&
+	git -c core.quotePath=true ls-tree -z \
+		--format="%(objecttype) %(path)" $tree >actual &&
+	test_cmp expect actual
+'
+
 test_done

---
base-commit: 03b41523c576f26ad34085378717a0c1b287470f
change-id: 20261118-ls-tree-format-z-verbatim-path-f5783b61ff8f

