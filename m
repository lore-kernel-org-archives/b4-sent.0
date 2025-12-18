From: Bagas Sanjaya <bagasdotme@gmail.com>
Date: Thu, 18 Dec 2025 12:05:00 +0700
Subject: [PATCH] VFS: fix dentry_create() kernel-doc comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-dentry-inline-v1-1-0107f4cd8246@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHuLQ2kC/x3MQQqAIBBG4avErBNUMqqrRAvJvxqIKTSiiO6et
 PwW7z2UEBmJuuKhiJMTb5JhyoLGxcsMxSGbrLbOWNOoADnirVhWFqhKt2YCPOrGUW72iImv/9c
 P7/sByOB+w18AAAA=
X-Change-ID: 20251218-dentry-inline-4091feeae685
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Benjamin Coddington <bcodding@hammerspace.com>, 
 Jeff Layton <jlayton@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stephen Rothwell <sfr@canb.auug.org.au>, 
 Bagas Sanjaya <bagasdotme@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1989; i=bagasdotme@gmail.com;
 s=Zp7juWIhw0R1; h=from:subject:message-id;
 bh=gykyE4n1Bru42E0/IbBcoXj6P5uhnSGs7sDFNl0/sD8=;
 b=owGbwMvMwCX2bWenZ2ig32LG02pJDJnO3V0TTlS8uK4rEGv08MW3ue6Mz/WDfZZb7ZvJsJ97s
 3DxkkbLjlIWBjEuBlkxRZZJiXxNp3cZiVxoX+sIM4eVCWQIAxenAExkkTbDP92SKhWfjef6iy8a
 RzxVttaQ3KAzcebhMn73NZL6WrPf1jMy9CXrttxPKT0f/k1hicKsrHXGGsr8nDsyz/9ZsStdzPc
 BKwA=
X-Developer-Key: i=bagasdotme@gmail.com; a=openpgp;
 fpr=701B806FDCA5D3A58FFB8F7D7C276C64A5E44A1D
X-Endpoint-Received: by B4 Relay for bagasdotme@gmail.com/Zp7juWIhw0R1 with auth_id=581
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sphinx reports htmldocs warnings:

Documentation/filesystems/api-summary:56: fs/namei.c:4952: WARNING: Inline emphasis start-string without end-string. [docutils]
Documentation/filesystems/api-summary:56: fs/namei.c:4942: ERROR: Unknown target name: "o". [docutils]

Fix them by escaping trailing underscore and wildcard.

Fixes: 977de00dfcf87e ("VFS: move dentry_create() from fs/open.c to fs/namei.c")
Reported-by: Stephen Rothwell <sfr@canb.auug.org.au>
Closes: https://lore.kernel.org/linux-next/20251216115252.709078e8@canb.auug.org.au/
Signed-off-by: Bagas Sanjaya <bagasdotme@gmail.com>
---
Sphinx reports htmldocs warnings:

Documentation/filesystems/api-summary:56: fs/namei.c:4952: WARNING: Inline emphasis start-string without end-string. [docutils]
Documentation/filesystems/api-summary:56: fs/namei.c:4942: ERROR: Unknown target name: "o". [docutils]

Fix them by escaping trailing underscore and wildcard.
---
 fs/namei.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/fs/namei.c b/fs/namei.c
index aefb21bc0944e3..d575d671b4f960 100644
--- a/fs/namei.c
+++ b/fs/namei.c
@@ -4939,7 +4939,7 @@ EXPORT_SYMBOL(start_creating_user_path);
 /**
  * dentry_create - Create and open a file
  * @path: path to create
- * @flags: O_ flags
+ * @flags: O\_ flags
  * @mode: mode bits for new file
  * @cred: credentials to use
  *
@@ -4950,7 +4950,7 @@ EXPORT_SYMBOL(start_creating_user_path);
  * the new file is to be created. The parent directory and the
  * negative dentry must reside on the same filesystem instance.
  *
- * On success, returns a "struct file *". Otherwise a ERR_PTR
+ * On success, returns a "struct file \*". Otherwise a ERR_PTR
  * is returned.
  */
 struct file *dentry_create(struct path *path, int flags, umode_t mode,

---
base-commit: 981be27a72d163610e8e1c342373930bae80ac99
change-id: 20251218-dentry-inline-4091feeae685

Best regards,
-- 
Bagas Sanjaya <bagasdotme@gmail.com>

