From: =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
Date: Thu, 05 Nov 2026 16:23:41 +0300
Subject: [PATCH] fuse: don't pass a NULL inode to fuse_inode_backing() on
 release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261105-fuse-cuse-release-v1-1-8be1eec02c66@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQpAQBRFf0VvbcpMIX5FFmNcPAnNQ0r+3WBzb
 2dxzkUCzxAqo4s8DhZe5gA6jsgNdu6huA1MJjGZ1kmqul2g3DseE2z4tsmL1NqsgHEUvNWj4/N
 rVvXPsjcj3PaG6L4fffXB23UAAAA=
X-Change-ID: 20261105-fuse-cuse-release-db795aa69e2c
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Orkun_Emin_Sar=C4=B1?= <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885020; l=1699;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=XgrvzfoNZJLMVh7JOSKQ9IdZU0PRskqYDZqGT15zz/w=;
 b=gbs3HQ72yYDqlKX7DMo75dpKLuTDfDO1J+2qiHIr4nDluBHTjdmRWaPOpizu0jKzK2XzTYiTa
 hkzztqUCQO0BkXO/ll2ZyKLdsCNX0p2Lh5bKH5Zwkjb/pdDG0p9SDZG
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cuse_release() and the error path of fuse_create_open() call
fuse_prepare_release() with a NULL fuse_inode. Since commit bbe2d73a8231
("fuse: don't assume ff->passthrough is set for FOPEN_PASSTHROUGH"),
fuse_prepare_release() calls fuse_inode_backing(fi) whenever the open
reply had FOPEN_PASSTHROUGH set, not only when ff->passthrough was set
up. A CUSE server that sets FOPEN_PASSTHROUGH thus makes the kernel
dereference a NULL pointer when the device is closed.

Pass a NULL backing when there is no inode. fuse_passthrough_release()
only prints it.

Found with AI-assisted code review (Claude Code).

Fixes: bbe2d73a8231 ("fuse: don't assume ff->passthrough is set for FOPEN_PASSTHROUGH")
Signed-off-by: Orkun Emin Sarı <sariorkunemin@gmail.com>
---
No reproducer was run and the fix is not runtime-tested. Build-tested
with LLVM=1 W=1 and FUSE_FS, CUSE and FUSE_PASSTHROUGH enabled.
---
 fs/fuse/file.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/fuse/file.c b/fs/fuse/file.c
index d5e1cb53d8..36144fdd69 100644
--- a/fs/fuse/file.c
+++ b/fs/fuse/file.c
@@ -320,7 +320,7 @@ static void fuse_prepare_release(struct fuse_inode *fi, struct fuse_file *ff,
 	struct fuse_release_args *ra = &ff->args->release_args;
 
 	if (fuse_is_passthrough(ff))
-		fuse_passthrough_release(ff, fuse_inode_backing(fi));
+		fuse_passthrough_release(ff, fi ? fuse_inode_backing(fi) : NULL);
 
 	/* Inode is NULL on error path of fuse_create_open() */
 	if (likely(fi)) {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-fuse-cuse-release-db795aa69e2c

Best regards,
--  
Orkun Emin Sarı <sariorkunemin@gmail.com>

