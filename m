From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:22:13 +0000
Subject: [PATCH 5.10.y] binfmt_misc: restore write access before closing
 files opened by open_exec()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-binfmt-510-v1-1-c62790b381f0@certik.com>
X-B4-Tracking: v=1; b=H4sIAJQhCWsC/1WNwQ7CIBBEf6XZs1sBi1p/xXgoZWvXKBi2Gk3Tf
 xf05HFeZt7MIJSYBA7VDImeLBxDDnpVQT924UzIPmcwymy1NjuUaNFxGG4TWq1w8M76trF702w
 gj+6JBn59hUewtVb1G04/Lg93oX4qttJ0nRC61IV+LEgo+CnGKxa+/n+BZfkA78i26qkAAAA=
X-Change-ID: 20261127-so5-binfmt-510-fdb5d9458243
To: stable@vger.kernel.org
Cc: Zilin Guan <zilin@seu.edu.cn>, Christian Brauner <brauner@kernel.org>, 
 linux-fsdevel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795760532; l=2237;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=WGqX07O3Yi7vqeSiFE0eOykUyKkDkZfXWYalnmxLXzM=;
 b=WXem5htlu0I1lz4Nrw5iKOXToGaWW7MuGffZBYGS7Q5dm/kTDOemaNJ+BtprgQxvAdkwRksYn
 wofqhZAox0tD5Atsd+7yEfOYo4xBxt8E4lRIKo9YEL3o2mxbVRv3eGZ
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zilin Guan <zilin@seu.edu.cn>

commit 90f601b497d76f40fa66795c3ecf625b6aced9fd upstream.

bm_register_write() opens an executable file using open_exec(), which
internally calls do_open_execat() and denies write access on the file to
avoid modification while it is being executed.

However, when an error occurs, bm_register_write() closes the file using
filp_close() directly. This does not restore the write permission, which
may cause subsequent write operations on the same file to fail.

Fix this by calling exe_file_allow_write_access() before filp_close() to
restore the write permission properly.

Fixes: e7850f4d844e ("binfmt_misc: fix possible deadlock in bm_register_write")
Signed-off-by: Zilin Guan <zilin@seu.edu.cn>
Link: https://patch.msgid.link/20251105022923.1813587-1-zilin@seu.edu.cn
Signed-off-by: Christian Brauner <brauner@kernel.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
5.15.y and newer already have this fix.

Tested on v5.10.275:
- x86_64 allmodconfig W=1 build of fs/binfmt_misc.o, base vs patched,
  no new warnings
- under QEMU/KVM: an F-flag registration with a non-executable or
  missing interpreter is rejected and the interpreter can be opened
  for writing afterwards, and a normal F-flag handler registers and
  removes cleanly. I didn't reach the error exit after open_exec().

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

fs/binfmt_misc.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
---
 fs/binfmt_misc.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/binfmt_misc.c b/fs/binfmt_misc.c
index ab14522dcd5b..ce6b5ab4bb84 100644
--- a/fs/binfmt_misc.c
+++ b/fs/binfmt_misc.c
@@ -827,8 +827,10 @@ static ssize_t bm_register_write(struct file *file, const char __user *buffer,
 	inode_unlock(d_inode(root));
 
 	if (err) {
-		if (f)
+		if (f) {
+			exe_file_allow_write_access(f);
 			filp_close(f, NULL);
+		}
 		kfree(e);
 		return err;
 	}

---
base-commit: 99112ea818e35b606397c84fbc05e6fadb6ea162
change-id: 20261127-so5-binfmt-510-fdb5d9458243

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

