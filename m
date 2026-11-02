From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Mon, 02 Nov 2026 12:56:25 +0000
Subject: [PATCH] fuse: ignore FUSE_ATTR_DAX unless a dax backing is
 possible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-fuse-attr-dax-v1-1-36f7b859b034@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHiI6GoC/x3MTQqAIBBA4avErBvwD4OuEi1Ex5qNhVYE4t2Tl
 t/ivQqFMlOBeaiQ6eHCR+qQ4wB+d2kj5NANSigrpVAY70LoritjcC96qe0UrNcmGujNmSny+/+
 WtbUPrInlzF8AAAA=
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Miklos Szeredi <mszeredi@redhat.com>, fuse-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793624184; l=3369;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=m4kc2zrIGru9miJ8HcufOYYEsonQia+fldC1h5teqrA=;
 b=FUjn2InbGAOhJkic3l8cIBqSwFOfOIPtATzqgu8Nf6MdMv9gjJW02YiPtIvwEBnXee7S0p3l3
 Sei5/UYz88zCfquXH7GRgA++ev+vPoczULuaOIg/0P2hPf7AAmJ0Jo9
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fuse_init_inode() trusts FUSE_ATTR_DAX from any server: it sets S_DAX and
switches the mapping to fuse_dax_aops, which has no ->read_folio and no
->readahead.  The open path only refuses such an inode without
FOPEN_PASSTHROUGH through an IS_DAX() check in fuse_file_io_open().

With CONFIG_FS_DAX=n, S_DAX is 0, so IS_DAX() is always false and that
check compiles away.  The file is opened for normal cached I/O on a
mapping without ->read_folio, and the first read() calls a NULL
function pointer from read_pages():

  Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
  pc : 0x0
  lr : read_pages+0x5b4/0x830
   page_cache_ra_order
   page_cache_sync_ra
   filemap_get_pages
   filemap_read
   generic_file_read_iter
   fuse_file_read_iter

Any server can do this, including an unprivileged one mounted through
fusermount3 or in a user namespace: answer LOOKUP of a regular file with
FUSE_ATTR_DAX set and a normal OPEN.  mmap() of the file reaches the same
NULL ->read_folio through filemap_fault().

As the commit adding it says, FUSE_ATTR_DAX is only meant to be used
with FUSE_PASSTHROUGH_V2 and a dax device backing, which needs FS_DAX.
Only honour it in that case.

Fixes: 2fbe4586cff3 ("fuse: add support for opening dax device as backing")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Found by reviewing the v7.4-rc1 fs/fuse changes with an LLM-based
assistant, following up on the Sashiko review of the dax backing series
that pointed out the missing ->read_folio; the IS_DAX() check added for
it does not cover CONFIG_FS_DAX=n.

Tested on arm64 QEMU, v7.4-rc1 with CONFIG_FS_DAX=n and KASAN, with a
FUSE server running as uid 65534 in a user namespace that replies
INIT with no flags, LOOKUP with FUSE_ATTR_DAX and a plain OPEN:
before, read() oopses as above; after, the read returns the file data
and unmount is clean.  The FUSE_ATTR_DAX=0 control is unchanged.

This also keeps an unprivileged server from getting S_DAX on
CONFIG_FS_DAX=y kernels without FUSE_PASSTHROUGH_V2, which is where
"fuse: refuse FUSE_NOTIFY_STORE for DAX inodes" (sent 2026-10-31)
applies; that patch is still useful for servers that do negotiate
FUSE_PASSTHROUGH_V2.
---
 fs/fuse/inode.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/fs/fuse/inode.c b/fs/fuse/inode.c
index 1341b681d0ed..7195e4d0852c 100644
--- a/fs/fuse/inode.c
+++ b/fs/fuse/inode.c
@@ -418,7 +418,14 @@ static void fuse_init_inode(struct inode *inode, struct fuse_attr *attr,
 		fuse_init_common(inode);
 		fuse_init_file_inode(inode, attr->flags);
 
-		if ((attr->flags & FUSE_ATTR_DAX) && !fuse_inode_vdax(inode)) {
+		/*
+		 * FUSE_ATTR_DAX is only meaningful for a dax device backing,
+		 * which needs FS_DAX and FUSE_PASSTHROUGH_V2.  Without FS_DAX
+		 * S_DAX is 0 and the inode would be left with fuse_dax_aops
+		 * on the page cache I/O paths.
+		 */
+		if (IS_ENABLED(CONFIG_FS_DAX) && fc->backing_id_64 &&
+		    (attr->flags & FUSE_ATTR_DAX) && !fuse_inode_vdax(inode)) {
 			inode->i_flags |= S_DAX;
 			inode->i_data.a_ops = &fuse_dax_aops;
 		}

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261102-fuse-attr-dax-c1367d6c34f4

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

