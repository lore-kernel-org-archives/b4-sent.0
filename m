From: Dominique Martinet <asmadeus@codewreck.org>
Date: Wed, 22 Oct 2025 07:09:57 +0900
Subject: [PATCH] fs/9p: don't use cached metadata in revalidate for
 cache=mmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251022-mmap-regression-v1-1-980365ee524e@codewreck.org>
X-B4-Tracking: v=1; b=H4sIALQE+GgC/x2MQQqAIBBFryKzTlCxFl0lWkiONgtNRohAvHvW8
 vHffw0qMmGFVTRgvKnSlQfoScBxuhxRkh8MRplZK2NkSq5IxshYP1cGFazyY7OLh/EqjIGev7j
 tvb8F6eibYQAAAA==
X-Change-ID: 20251022-mmap-regression-f0f40d51046d
To: Song Liu <song@kernel.org>, Andrii Nakryiko <andrii.nakryiko@gmail.com>, 
 Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>, 
 Tingmao Wang <m@maowtm.org>, Alexei Starovoitov <ast@kernel.org>
Cc: linux-kernel@vger.kernel.org, v9fs@lists.linux.dev, bpf@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=3352;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=8U+bVWiUxykgXibHegqG5mO5sNY1PawdwUE7RKEEVBk=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBo+AS5EQJpnOD9lVhx8INJrvPAzWuAa4BAmWa0L
 wUP5lB9mkeJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaPgEuQAKCRCrTpvsapjm
 cGyND/9j8uDuBNg3l93/NCpqQWdWjeMkPuaYEIlTz00a0mCP54AnDbbaHQQHeWg/Z+WHhIFkTCN
 IoH/1Zl5ku/UEbg3wjx6EicDxlL0Ocav1HYdIG4Wd3TnkZLmJ15mB896XSh4VUxL2aqzhdf1vzl
 5TVDMGsrveXJX9s+gY08iFOtltpegOJ07J01tFeIUlOd1k5J/AnRIGd6gl5JRJCm6EtGLc/m81w
 xZG4Q3ByYjqySviFBo9KqGPLvdKbpeBYSdcHOb2OKoJCuTohGg2ALdksvfQhflPxwV93p4ky30a
 RXptszZVc3lDeLx+fATTWXAp6LFgkNwUsMBnP0FfBltXkko/qblVv0f5jfCdv4JwGK/2qCqT/mA
 lihhGkrkyJ38ttDGU1Uw9ZLix80UhXmhCONL08aqr0CjY5z2i/unSwJEvBlJfjnFaVJ+bD0kbX1
 dnrtdCLrjTv9K9iT9dFwdNZjIl5wKP+zr7CZeGvlRFQLsNgSG/GDIdd6BaRgZXZK9T6PY4mihZj
 GHY4PGt+o+DfWKEi/XLuxcGgjNlXan8UBnH9W7MIqqeUvNKQIcZxpnulseHktuTFInBElzUiGZl
 TptoO9SWgR4TaDpEaRvtaxulhg8tijguOub3t5G5TB8pJWRkhRrKVpc/PD5PHaXMZaom+bBbOqz
 qTFMDNOj8T92FvA==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cache=mmap is a mode that doesn't cache metadata, but still has
writeback cache.
In commit 290434474c33 ("fs/9p: Refresh metadata in d_revalidate
for uncached mode too") we considered metadata cache to be enough to
not look at the server, but in writeback cache too looking at the server
size would make the vfs consider the file has been truncated before the
data has been flushed out, making the following repro fail (nothing is
ever read back, the resulting file ends up with no data written)

---
I was suspecting cache=mmap when I saw vmtest used that, and it's
confirmed with Song's reproducer...
This makes the repro work, would one of you be able to confirm this?
Once confirmed I'll send this to Linus directly

Thanks again and sorry for lack of cache=mmap tests :/

Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

char buf[4096];

int main(int argc, char *argv[])
{
        int ret, i;
        int fdw, fdr;

        if (argc < 2)
                return 1;

        fdw = openat(AT_FDCWD, argv[1], O_RDWR|O_CREAT|O_EXCL|O_CLOEXEC, 0600);
        if (fdw < 0) {
                fprintf(stderr, "cannot open fdw\n");
                return 1;
        }
        write(fdw, buf, sizeof(buf));

        fdr = openat(AT_FDCWD, argv[1], O_RDONLY|O_CLOEXEC);

        if (fdr < 0) {
                fprintf(stderr, "cannot open fdr\n");
                close(fdw);
                return 1;
        }

        for (i = 0; i < 10; i++) {
                ret = read(fdr, buf, sizeof(buf));
                fprintf(stderr, "i: %d, read returns %d\n", i, ret);
        }

        close(fdr);
        close(fdw);
        return 0;
}
---

Reported-by: Song Liu <song@kernel.org>
Link: https://lkml.kernel.org/r/CAHzjS_u_SYdt5=2gYO_dxzMKXzGMt-TfdE_ueowg-Hq5tRCAiw@mail.gmail.com
Reported-by: Andrii Nakryiko <andrii.nakryiko@gmail.com>
Link: https://lore.kernel.org/bpf/CAEf4BzZbCE4tLoDZyUf_aASpgAGFj75QMfSXX4a4dLYixnOiLg@mail.gmail.com/
Fixes: 290434474c33 ("fs/9p: Refresh metadata in d_revalidate for uncached mode too")
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 fs/9p/vfs_dentry.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/fs/9p/vfs_dentry.c b/fs/9p/vfs_dentry.c
index f3248a3e54023489054337bf98e87a1d7b1fbafc..2f3654bf6275ffa802dc25b9a84bd61a62d5723c 100644
--- a/fs/9p/vfs_dentry.c
+++ b/fs/9p/vfs_dentry.c
@@ -78,7 +78,11 @@ static int __v9fs_lookup_revalidate(struct dentry *dentry, unsigned int flags)
 	v9inode = V9FS_I(inode);
 	struct v9fs_session_info *v9ses = v9fs_inode2v9ses(inode);
 
-	cached = v9ses->cache & (CACHE_META | CACHE_LOOSE);
+	/* We also don't want to refresh attr here in writeback cache mode,
+	 * otherwise a write that hasn't been propagated to server would
+	 * incorrectly get the old size back and truncate the file before
+	 * the write happens */
+	cached = v9ses->cache & (CACHE_META | CACHE_WRITEBACK | CACHE_LOOSE);
 
 	if (!cached || v9inode->cache_validity & V9FS_INO_INVALID_ATTR) {
 		int retval;

---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251022-mmap-regression-f0f40d51046d

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

