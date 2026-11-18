From: Noam Cohen <noam@noam.me>
Date: Wed, 18 Nov 2026 23:04:37 +0000
Subject: [PATCH] ls-tree: do not quote %(path) with -z
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-ls-tree-format-z-verbatim-path-v1-1-718987241861@noam.me>
X-B4-Tracking: v=1; b=H4sIAAQv/moC/yXNTQrCQAxA4auUrA2YinXwKuJipiY2Yn9IpkUsv
 bujLr/Neys4m7LDuVrBeFHXcSigXQVtF4c7o96Kod7XDREFfDpmY0YZrY8Z37iwpZi1xynmDuV
 4CofUkEgQKJHJWPT1G1yuf/ucHtzmbxW27QNoc4/aggAAAA==
X-Change-ID: 20261118-ls-tree-format-z-verbatim-path-f5783b61ff8f
To: git@vger.kernel.org
Cc: Junio C Hamano <gitster@pobox.com>, Teng Long <dyroneteng@gmail.com>, 
 =?utf-8?q?=C3=86var_Arnfj=C3=B6r=C3=B0_Bjarmason?= <avarab@gmail.com>, 
 =?utf-8?q?Ren=C3=A9_Scharfe?= <l.s.r@web.de>, Noam Cohen <noam@noam.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795043135; l=1980;
 i=noam@noam.me; s=20261118; h=from:subject:message-id;
 bh=/gS8cB9hoApkoumXcC9pvUxzrBcAfscqlgx+E/AqFio=;
 b=T+uWUJSMwZRIQ1pVZ2Y7ycU/uL2NxTqfXpExeGeVWi+nxVin6uiqV3h9IRh/VQ1zMxMJrRtYt
 xVyxvddV6xZC+ZkoWmdFmx8/iu9A4w+fQvGFw69v0oKxrEiXzoiKyjJ
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
 builtin/ls-tree.c         | 5 ++++-
 t/t3104-ls-tree-format.sh | 9 ++++++++-
 2 files changed, 12 insertions(+), 2 deletions(-)

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
index a1b2069a25..016c0fd0ff 100755
--- a/t/t3104-ls-tree-format.sh
+++ b/t/t3104-ls-tree-format.sh
@@ -12,7 +12,8 @@ test_expect_success 'ls-tree --format usage' '
 '
 
 test_expect_success 'setup' '
-	setup_basic_ls_tree_data
+	setup_basic_ls_tree_data &&
+	test_commit נעם
 '
 
 test_ls_tree_format () {
@@ -76,4 +77,10 @@ test_ls_tree_format \
 	"--full-tree" \
 	"--full-tree"
 
+test_expect_success 'ls-tree --format with -z does not quote paths' '
+	printf "blob נעם.t\0" >expect &&
+	git ls-tree -z --format="%(objecttype) %(path)" HEAD נעם.t >actual &&
+	test_cmp expect actual
+'
+
 test_done

---
base-commit: 03b41523c576f26ad34085378717a0c1b287470f
change-id: 20261118-ls-tree-format-z-verbatim-path-f5783b61ff8f

