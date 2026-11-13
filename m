From: Yusuke Hayashi <yusuke8h@gmail.com>
Date: Fri, 13 Nov 2026 02:17:58 +0000
Subject: [PATCH] http-backend: drop strbuf pre-sizing from get_info_packs()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-http-backend-drop-strbuf-presizing-v1-1-7d66aae03b22@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFVz9moC/x2NQQqDMBAAvyJ7dsGkNVC/Ih5istGlEMNuWkrFv
 zf0OAzMnKAkTApTd4LQm5WP3MD0HYTd542QY2Owg3XGmBvutRZcfXhSjhjlKKhV1lfCIqT85by
 hS/eHG0cbh+ChhZpJ/PlP5uW6fvQRAf90AAAA
X-Change-ID: 20261113-http-backend-drop-strbuf-presizing-6f496552d0ca
To: git@vger.kernel.org
Cc: Jeff King <peff@peff.net>, Patrick Steinhardt <ps@pks.im>, 
 Yusuke Hayashi <yusuke8h@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794536279; l=1829;
 i=yusuke8h@gmail.com; s=20261112; h=from:subject:message-id;
 bh=5KrviimACYCG/AtywYjQYyiJqUKbPCUrIZKRQmnamtg=;
 b=D3J0G++wLzAy04umBnll0qIcK2NDo5/yHuVWk+w9P6DUazpps6P4rjVsX5eaUVq2uZ7a0ZEHA
 eYlER5VJU+8BV9bGOrGbqmA9/CJBhg9/8of9feIhCauFAnrAEYTyRjd
X-Developer-Key: i=yusuke8h@gmail.com; a=ed25519;
 pk=7SzYbbTWl4u1a0gmKeMxAqo7g7F1K7tnWWGWQ+LnNNs=
X-Endpoint-Received: by B4 Relay for yusuke8h@gmail.com/20261112 with auth_id=1495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_info_packs() iterates over all packs in the repository to count
local packs, calls `strbuf_grow(&buf, cnt * 53 + 2)`, and then iterates
over the packs a second time to format each entry with `strbuf_addf()`.

This pre-sizing dates back to 2f4038ab33 (Git-aware CGI to provide dumb
HTTP transport, 2009-10-30) and is no longer worth keeping: `53` assumes
the length of a SHA-1 "P pack-<hex>.pack\n" line (under-counting the
77-byte lines in SHA-256 repositories), `cnt * 53 + 2` uses unchecked
arithmetic, and `strbuf_addf()` / `strbuf_addch()` already grow the
buffer automatically without needing an extra pass over the pack list.
Similar pre-sizing was recently removed in a9ce8526dc (pretty: drop
strbuf pre-sizing from add_rfc2047(), 2026-05-12).

Drop `cnt`, the counting loop, and the `strbuf_grow()` call.

Signed-off-by: Yusuke Hayashi <yusuke8h@gmail.com>
---
Inspired by https://lore.kernel.org/git/20260513185408.GA147423@coredump.intra.peff.net/
---
 http-backend.c | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/http-backend.c b/http-backend.c
index c7566b1d12..da9516a4c1 100644
--- a/http-backend.c
+++ b/http-backend.c
@@ -612,15 +612,8 @@ static void get_info_packs(struct strbuf *hdr, char *arg UNUSED)
 	size_t objdirlen = strlen(repo_get_object_directory(the_repository));
 	struct strbuf buf = STRBUF_INIT;
 	struct packed_git *p;
-	size_t cnt = 0;
 
 	select_getanyfile(hdr);
-	repo_for_each_pack(the_repository, p) {
-		if (p->pack_local)
-			cnt++;
-	}
-
-	strbuf_grow(&buf, cnt * 53 + 2);
 	repo_for_each_pack(the_repository, p) {
 		if (p->pack_local)
 			strbuf_addf(&buf, "P %s\n", p->pack_name + objdirlen + 6);

---
base-commit: 9354c5f04055932909b660a237905b360cba195a
change-id: 20261113-http-backend-drop-strbuf-presizing-6f496552d0ca

