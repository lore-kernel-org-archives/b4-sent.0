From: Yusuke Hayashi <yusuke8h@gmail.com>
Date: Sun, 15 Nov 2026 09:58:47 +0000
Subject: [PATCH v2] http-backend: drop strbuf pre-sizing from
 get_info_packs()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-http-backend-drop-strbuf-presizing-v2-1-b7ffe1be4482@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFaC+WoC/5WNQQ6CMBBFr0Jm7RhapEZX3MOwKO0AE6UlbSUq4
 e5WbuDy/Z+8t0KkwBThWqwQaOHI3mWQhwLMqN1AyDYzyFIqIUSFY0ozdtrcyVm0wc8YU+iePc6
 BIn/YDaj600XVtbSl0ZBF+en5tUdubeaRY/LhvTcX8Vv/0i8CBZ6tUlpTWXVSNsOk+XE0foJ22
 7YvtyAeK9QAAAA=
X-Change-ID: 20261113-http-backend-drop-strbuf-presizing-6f496552d0ca
In-Reply-To: <20261113-http-backend-drop-strbuf-presizing-v1-1-7d66aae03b22@gmail.com>
References: <20261113-http-backend-drop-strbuf-presizing-v1-1-7d66aae03b22@gmail.com>
To: git@vger.kernel.org
Cc: Jeff King <peff@peff.net>, Patrick Steinhardt <ps@pks.im>, 
 Yusuke Hayashi <yusuke8h@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794736726; l=5207;
 i=yusuke8h@gmail.com; s=20261112; h=from:subject:message-id;
 bh=e2BiSJ1Xm65mUA9mqSKfRdN+Wp4cJ7+YuQE0Bl8GYYY=;
 b=b7eJZ1tD6VbV3NqpA/g2zdMd//Mah18ylx2Qh9QZrzRFTHl2mb5Va1AgWs079DSYdlrLUhsTQ
 uv7S2cVvlsEBpP9vO0TspOUF3tv2lOwzGEoTotS7rDLrNMKa3qrSpPn
X-Developer-Key: i=yusuke8h@gmail.com; a=ed25519;
 pk=7SzYbbTWl4u1a0gmKeMxAqo7g7F1K7tnWWGWQ+LnNNs=
X-Endpoint-Received: by B4 Relay for yusuke8h@gmail.com/20261112 with auth_id=1495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`get_info_packs()` iterates over all packs in the repository to count
local packs, calls `strbuf_grow(&buf, cnt * 53 + 2)`, and then iterates
over the packs a second time to format each entry with `strbuf_addf()`.
This pre-sizing dates back to 2f4038ab33 (Git-aware CGI to provide dumb
HTTP transport, 2009-10-30): `53` assumes the length of a SHA-1
"P pack-<hex>.pack\n" line (under-counting the 77-byte lines in SHA-256
repositories), and `cnt * 53 + 2` uses unchecked arithmetic.

Rather than fixing the size calculation with `the_hash_algo->hexsz` and
`st_mult()` / `st_add()`, drop the pre-sizing altogether.
`get_info_packs()` is a one-shot CGI handler for dumb HTTP
`/objects/info/packs` requests that formats a single response and exits.
A typical repository only has a few dozen packs (a few kilobytes of
output), and even with thousands of packs `strbuf`'s geometric growth
only performs a couple dozen reallocations. That cost is negligible next
to CGI startup, scanning `objects/pack` to populate the pack list, and
writing the HTTP response, whereas computing `cnt` up front requires an
extra pass over the pack list.

Drop `cnt`, the counting loop, and the `strbuf_grow()` call, and let
`strbuf_addf()` and `strbuf_addch()` grow the buffer as needed.

Signed-off-by: Yusuke Hayashi <yusuke8h@gmail.com>
---
Inspired by https://lore.kernel.org/git/20260513185408.GA147423@coredump.intra.peff.net/
---
Changes in v2:
- Rewrite the commit message to explain why skipping pre-sizing is fine
  in `get_info_packs()` specifically (one-shot CGI handler where
  `strbuf`'s geometric growth is negligible next to CGI startup, pack
  discovery, and HTTP I/O), rather than citing `a9ce8526dc` as precedent.
- No code changes.
- Link to v1: https://lore.kernel.org/git/20261113-http-backend-drop-strbuf-presizing-v1-1-7d66aae03b22@gmail.com/
---
Range-diff versus v1:

1:  9abfe3635b ! 1:  7561d02b83 http-backend: drop strbuf pre-sizing from get_info_packs()
    @@ Metadata
      ## Commit message ##
         http-backend: drop strbuf pre-sizing from get_info_packs()
     
    -    get_info_packs() iterates over all packs in the repository to count
    +    `get_info_packs()` iterates over all packs in the repository to count
         local packs, calls `strbuf_grow(&buf, cnt * 53 + 2)`, and then iterates
         over the packs a second time to format each entry with `strbuf_addf()`.
    -
         This pre-sizing dates back to 2f4038ab33 (Git-aware CGI to provide dumb
    -    HTTP transport, 2009-10-30) and is no longer worth keeping: `53` assumes
    -    the length of a SHA-1 "P pack-<hex>.pack\n" line (under-counting the
    -    77-byte lines in SHA-256 repositories), `cnt * 53 + 2` uses unchecked
    -    arithmetic, and `strbuf_addf()` / `strbuf_addch()` already grow the
    -    buffer automatically without needing an extra pass over the pack list.
    -    Similar pre-sizing was recently removed in a9ce8526dc (pretty: drop
    -    strbuf pre-sizing from add_rfc2047(), 2026-05-12).
    +    HTTP transport, 2009-10-30): `53` assumes the length of a SHA-1
    +    "P pack-<hex>.pack\n" line (under-counting the 77-byte lines in SHA-256
    +    repositories), and `cnt * 53 + 2` uses unchecked arithmetic.
    +
    +    Rather than fixing the size calculation with `the_hash_algo->hexsz` and
    +    `st_mult()` / `st_add()`, drop the pre-sizing altogether.
    +    `get_info_packs()` is a one-shot CGI handler for dumb HTTP
    +    `/objects/info/packs` requests that formats a single response and exits.
    +    A typical repository only has a few dozen packs (a few kilobytes of
    +    output), and even with thousands of packs `strbuf`'s geometric growth
    +    only performs a couple dozen reallocations. That cost is negligible next
    +    to CGI startup, scanning `objects/pack` to populate the pack list, and
    +    writing the HTTP response, whereas computing `cnt` up front requires an
    +    extra pass over the pack list.
     
    -    Drop `cnt`, the counting loop, and the `strbuf_grow()` call.
    +    Drop `cnt`, the counting loop, and the `strbuf_grow()` call, and let
    +    `strbuf_addf()` and `strbuf_addch()` grow the buffer as needed.
     
         Signed-off-by: Yusuke Hayashi <yusuke8h@gmail.com>
     
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

