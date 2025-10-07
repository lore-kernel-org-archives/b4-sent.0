From: Dmitry Safonov <dima@arista.com>
Date: Tue, 07 Oct 2025 04:46:47 +0100
Subject: [PATCH v2] gen_init_cpio: Ignore fsync() returning EINVAL on pipes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-gen_init_cpio-pipe-v2-1-b098ab94b58a@arista.com>
X-B4-Tracking: v=1; b=H4sIACaN5GgC/32OQQqDMBBFryJZN60Jmtiueo8iMppRB2oSEgkt4
 t0bPUCXb+C9PxuLGAgjexQbC5gokrMZ5KVgwwx2Qk4mM5OlrEVZaj6h7cjS2g2eHPfkkddgGj0
 qoaAqWRZ9wJE+Z/TVZu4hIu8D2GE+UqsLCd4m3haIK4bDmCnm6/f8IonD+zuYBBfc6EYqXZnqL
 tUTQi7AdXALa/d9/wGYg9IN1wAAAA==
X-Change-ID: 20251007-gen_init_cpio-pipe-5ad87f616a40
To: Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>, David Disseldorp <ddiss@suse.de>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nicolas Schier <nsc@kernel.org>, Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759808819; l=1432;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=pi6nAKJ620AnZApjddteEQX/ECee5WVBVllxGZBH+N8=;
 b=YzLgLfDoTx79sz7zGwGkOOFxyKp5dQ37Mq0qJ7q4IcdONwpPsrJ3tDd6zfJiEY37oA6O77kqI
 IuyCcC/DpAvBcyUYl18XUycPJas2PA6hmWCfh1F3i2+wZ8fUsHwSLgj
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reproducer:
echo | ./usr/gen_init_cpio /dev/stdin > /dev/null

fsync() on a pipe fd returns -EINVAL, which makes gen_init_cpio fail.
Ignore -EINVAL from fsync().

Fixes: ae18b94099b0 ("gen_init_cpio: support -o <output_file> parameter")
Cc: David Disseldorp <ddiss@suse.de>
Cc: Nicolas Schier <nsc@kernel.org>
Signed-off-by: Dmitry Safonov <dima@arista.com>
Reviewed-by: David Disseldorp <ddiss@suse.de>
---
Changes in v2:
- Instead of isfdtype() just ignore -EINVAL from fsync() (Suggested by David)
- Add minimal reproducer and shrink the patch description (David)
- Link to v1: https://lore.kernel.org/r/20251007-gen_init_cpio-pipe-v1-1-d782674d4926@arista.com
---
 usr/gen_init_cpio.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/usr/gen_init_cpio.c b/usr/gen_init_cpio.c
index 75e9561ba31392e12536e76a918245a8ea07f9b8..b7296edc6626fb0cf7c709082797d1e6a7376d6e 100644
--- a/usr/gen_init_cpio.c
+++ b/usr/gen_init_cpio.c
@@ -112,7 +112,10 @@ static int cpio_trailer(void)
 	    push_pad(padlen(offset, 512)) < 0)
 		return -1;
 
-	return fsync(outfd);
+	if (fsync(outfd) < 0 && errno != EINVAL)
+		return -1;
+
+	return 0;
 }
 
 static int cpio_mkslink(const char *name, const char *target,

---
base-commit: c746c3b5169831d7fb032a1051d8b45592ae8d78
change-id: 20251007-gen_init_cpio-pipe-5ad87f616a40

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

