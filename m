From: Dmitry Safonov <dima@arista.com>
Date: Tue, 07 Oct 2025 00:55:03 +0100
Subject: [PATCH RFC] gen_init_cpio: Do fsync() only on regular files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-gen_init_cpio-pipe-v1-1-d782674d4926@arista.com>
X-B4-Tracking: v=1; b=H4sIANZW5GgC/x2MQQrCMBAAv1L2bDAtthWvgg/wKlK2ybZd0CTsh
 iKU/t3ocQZmNlASJoVLtYHQysoxFKgPFbgFw0yGfWFobNPW1vZmpjBw4Dy4xNEkTmRa9Od+6uo
 OTxZKmIQm/vynD7jfrvAsckQlMwoGt/x+OcqKL6/HN2omgX3/AvKrGOqLAAAA
X-Change-ID: 20251007-gen_init_cpio-pipe-5ad87f616a40
To: Nathan Chancellor <nathan@kernel.org>, 
 Nicolas Schier <nicolas.schier@linux.dev>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Disseldorp <ddiss@suse.de>, Nicolas Schier <nsc@kernel.org>, 
 Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759794918; l=2046;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=NnRRrg2oTnEc3cpkMddM+o06vZ45lyz3lI5ZtwOioE0=;
 b=7CUFMg8F4JYq/oh73XYptU6UhBaoMFT2saK+WgptF9bn89/p2Jz73kAcWmLlqtLDWFWSp+86n
 8IbocTtKPRfASAcG9f1dQSa2/W8H563HPQG9RF55RUqUP7GGkE1+tDn
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here at Arista gen_init_cpio is used in testing in order to create
an initramfs for specific tests. Most notably, there is a test that does
essentially a fork-bomb in kdump/panic kernel, replacing build-time
generated init script: instead of doing makedumpfile, it does call
shell tests.

In comparison to usr/Makefile, which creates an intermediate .cpio file,
the Makefile that generates initrd for tests is a one-liner:
> file lib/kdump ${src_dir}/oom-crashkernel 0644 0 0 | usr/gen_init_cpio /dev/stdin | xz -z -c -e -Ccrc32 > ${target_dir}/oom-crashkernel.initrd

As fsync() on a pipe fd returns -EINVAL, that stopped working.
Check that outfd is a regular file descriptor before calling fsync().

Sending this as RFC as these are local tests, rather than upstream ones,
unfortunately. Yet, the fix is trivial and increases correctness of
gen_init_cpio (and maybe saves some time for another person debugging
it). A workaround to use temporary cpio file is also trivial, so not
insisting on merging.

Fixes: ae18b94099b0 ("gen_init_cpio: support -o <output_file> parameter")
Cc: David Disseldorp <ddiss@suse.de>
Cc: Nicolas Schier <nsc@kernel.org>
Signed-off-by: Dmitry Safonov <dima@arista.com>
---
 usr/gen_init_cpio.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/usr/gen_init_cpio.c b/usr/gen_init_cpio.c
index 75e9561ba31392e12536e76a918245a8ea07f9b8..845e2d92f0e56b02ba5fc12ecd243ce99c53f552 100644
--- a/usr/gen_init_cpio.c
+++ b/usr/gen_init_cpio.c
@@ -6,6 +6,7 @@
 #include <stdbool.h>
 #include <sys/types.h>
 #include <sys/stat.h>
+#include <sys/socket.h>
 #include <string.h>
 #include <unistd.h>
 #include <time.h>
@@ -112,6 +113,9 @@ static int cpio_trailer(void)
 	    push_pad(padlen(offset, 512)) < 0)
 		return -1;
 
+	if (!isfdtype(outfd, S_IFREG))
+		return 0;
+
 	return fsync(outfd);
 }
 

---
base-commit: c746c3b5169831d7fb032a1051d8b45592ae8d78
change-id: 20251007-gen_init_cpio-pipe-5ad87f616a40

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

