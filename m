From: =?utf-8?q?Aykut_C=C4=B1nc=C4=B1k?= <aykutcincik@ogr.eskisehir.edu.tr>
Date: Mon, 23 Nov 2026 21:15:01 +0300
Subject: [PATCH] ext4: undo the splice when ext4_splice_branch() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261123-ext4-splice-unsplice-v1-1-d291b741d15a@ogr.eskisehir.edu.tr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y3M0Q5EMBCF4VeRudZES5B9FdmLdgxGpKSDSMS76
 1p357s4/wlCgUngk5wQaGfh2UfoNAEcrO9JcRsNJjOl1iZXdKyFkmViJLX5d1S1zW2LrjboIF6
 XQB0fT7b5/i2bGwnXXwuu6wYXwdFleAAAAA==
X-Change-ID: 20261123-ext4-splice-unsplice-78a3adcb82cb
To: Theodore Ts'o <tytso@mit.edu>, 
 Andreas Dilger <adilger.kernel@dilger.ca>
Cc: Jan Kara <jack@suse.cz>, Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, linux-ext4@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?Aykut_C=C4=B1nc=C4=B1k?= <aykutcincik@ogr.eskisehir.edu.tr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795457701; l=2094;
 i=aykutcincik@ogr.eskisehir.edu.tr; s=20261121; h=from:subject:message-id;
 bh=Ls4C+dOUY3TCmbcSSyBWCu5aT7wRmuBH47WNxUck0+g=;
 b=OFJbPSfHX2f9wrqb18yNB7lNY7h+rGZD3Mu739L7AigYtB4io6L/8uULPlHKIZE0wWIeWpVON
 cSPhkJ2DarrAn51ImuhxUY4U0LaOhRcHSt0/eqneOZ+qDWCCNzl1621
X-Developer-Key: i=aykutcincik@ogr.eskisehir.edu.tr; a=ed25519;
 pk=0VzUGJI+NLEekrIgYW4SWfh5kCTg8XsSWzEwmTagNes=
X-Endpoint-Received: by B4 Relay for aykutcincik@ogr.eskisehir.edu.tr/20261121 with auth_id=1593
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If ext4_handle_dirty_metadata() or ext4_mark_inode_dirty() fails,
ext4_splice_branch() frees the new blocks but leaves the pointers to
them in place.  A later write then reuses the freed blocks, which can
silently overwrite another file's data.

Clear the pointers before freeing the blocks.

Found and fixed with the help of Claude Code (Claude Opus).

Fixes: ac27a0ec112a ("[PATCH] ext4: initial copy of files from ext3")
Cc: stable@vger.kernel.org
Signed-off-by: Aykut Cıncık <aykutcincik@ogr.eskisehir.edu.tr>
---
Tested in QEMU by making each of the two calls fail with the dm "error"
target.  Without the fix all 12 runs showed corruption (another file
overwritten, or a double free); with it all 12 were clean, with KASAN
and lockdep enabled.

Tested on top of [1]; the two patches apply in either order.

[1] https://patch.msgid.link/20261121-ext4-ind-discard-pa-v1-1-ee92928f7797@ogr.eskisehir.edu.tr
---
 fs/ext4/indirect.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/fs/ext4/indirect.c b/fs/ext4/indirect.c
index a495080df710..764f01057aca 100644
--- a/fs/ext4/indirect.c
+++ b/fs/ext4/indirect.c
@@ -471,18 +471,21 @@ static int ext4_splice_branch(handle_t *handle,
 		BUFFER_TRACE(where->bh, "call ext4_handle_dirty_metadata");
 		err = ext4_handle_dirty_metadata(handle, ar->inode, where->bh);
 		if (err)
-			goto err_out;
+			goto err_unsplice;
 	} else {
 		/*
 		 * OK, we spliced it into the inode itself on a direct block.
 		 */
 		err = ext4_mark_inode_dirty(handle, ar->inode);
 		if (unlikely(err))
-			goto err_out;
+			goto err_unsplice;
 		ext4_debug("splicing direct\n");
 	}
 	return err;
 
+err_unsplice:
+	/* Do not leave the tree pointing at the blocks freed below. */
+	memset(where->p, 0, sizeof(*where->p) * (num == 0 ? ar->len : 1));
 err_out:
 	for (i = 1; i <= num; i++) {
 		/*

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261123-ext4-splice-unsplice-78a3adcb82cb

Best regards,
--  
Aykut Cıncık <aykutcincik@ogr.eskisehir.edu.tr>

