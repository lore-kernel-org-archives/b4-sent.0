From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 04:38:20 -0500
Subject: [PATCH] orangefs: keep the readdir entry size 64-bit in
 fill_from_part()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-50d2bd59-v1-1-ce332969b4a2@proton.me>
X-B4-Tracking: v=1; b=H4sIAAsONWoC/x3MMQqAMAxA0atIZgNprEq9ijhYGzWLSgsiFO9uc
 XzD/xmSRJUEQ5Uhyq1Jz6PA1BUs+3xsghqKgYk76oxDbzFourClwD60DsmtwtyT9Y2Bkl1RVn3
 +5Ti97wcDJit8YgAAAA==
To: Mike Marshall <hubcap@omnibond.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devel@lists.orangefs.org, Martin Brandenburg <martin@omnibond.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781861899; l=2502;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=RJ8UcS4zpbSFRnrWNSWSdbFKTQ2rtT8iK4yUjj8cqng=;
 b=Vdm6WMjY5JkW7U1XmXeabtMn+i+ZG/DE8OgOh6bSSj+l2snqflHnXtFDsDObEVebkLyoOG92g
 n6C2/ZaUyTzBi5xnEKayytXhj+zr3GYPBd+327c36A5l2woGi+KRL8U
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fill_from_part() computes the size of a directory entry in size_t but
stores it in a __u32. An entry length near U32_MAX wraps it to a small
value, bypasses the bounds check, and is then used to index the entry,
reading far past the directory part -- an out-of-bounds read that oopses
the kernel.

Compute the size as a u64 so it cannot truncate; the bounds check then
rejects the entry. The trailer is supplied by the userspace client.

Fixes: 480e3e532e31 ("orangefs: support very large directories")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced with an in-kernel module that runs the fill_from_part() loop over
a crafted trailer; the only difference between arms is the size width:

  A (__u32, len 0xfffffffb): page-fault oops at fill_from_part+0x126
    (KASAN shadow load for s[*len], ~4 GiB out).
  B (u64, this patch): the bounds check rejects the entry, no OOB.
  C (small len): unchanged, entry emitted.

Same result under userspace ASan. Tested on a KASAN build at v7.1-rc7.

checkpatch keeps "sizeof *len" to match the rest of the function.

Severity depends on the trust boundary on the userspace client: a remote or
compromised server driving the length is a remote DoS; a trusted client
makes it a local robustness fix. No write, no info leak.
---
 fs/orangefs/dir.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/fs/orangefs/dir.c b/fs/orangefs/dir.c
index 6e2ebc8b9867..115b2c2f5269 100644
--- a/fs/orangefs/dir.c
+++ b/fs/orangefs/dir.c
@@ -191,7 +191,8 @@ static int fill_from_part(struct orangefs_dir_part *part,
 {
 	const int offset = sizeof(struct orangefs_readdir_response_s);
 	struct orangefs_khandle *khandle;
-	__u32 *len, padlen;
+	__u32 *len;
+	u64 padlen;
 	loff_t i;
 	char *s;
 	i = ctx->pos & ~PART_MASK;
@@ -215,8 +216,8 @@ static int fill_from_part(struct orangefs_dir_part *part,
 		 * len is the size of the string itself.  padlen is the
 		 * total size of the encoded string.
 		 */
-		padlen = (sizeof *len + *len + 1) +
-		    (8 - (sizeof *len + *len + 1)%8)%8;
+		padlen = (u64)sizeof *len + *len + 1;
+		padlen += (8 - padlen % 8) % 8;
 		if (part->len < i + padlen + sizeof *khandle)
 			goto next;
 		s = (void *)part + offset + i + sizeof *len;

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260619-b4-disp-50d2bd59-09fe22704b31

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

