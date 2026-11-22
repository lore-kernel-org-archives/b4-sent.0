From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 12:46:23 +0800
Subject: [PATCH v2] erofs: validate fsoffset alignment and bound page reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-01-erofs-fsoffset-oob-v2-9c629f3ad714-v2-1-2cfb14e36120@pm.me>
X-B4-Tracking: v=1; b=H4sIAJ5zAmsC/yWNywrCMBBFf0WydjCZDGnqr4iLPCY2Io0ktSil/
 26ry3O4nLuIxjVzE+fDIirPueUyboDHgwiDG28MOW4sUKJRChE8gVTAtaQGqZWUGk9QiocZoQ8
 G+6Rd7BRB8Nqx1F2QNogt96yc8vt3dbn+ub38ncO09/eFd43BVzeGYVeVH+4DuzwFIiUpaUMYX
 YdSGZKEBjWT1Wi1cZxitCzW9QuEh/V20gAAAA==
X-Change-ID: 20261122-b4-01-erofs-fsoffset-oob-v2-9c629f3ad714-cb3ae037c08c
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>
Cc: Yue Hu <zbestahu@gmail.com>, Jingbo Xu <jefflexu@163.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <hongbohbli@tencent.com>, 
 Chunhai Guo <guochunhai@vivo.com>, Sheng Yong <shengyong@oppo.com>, 
 Wang Shuai <wangshuai@vivo.com>, linux-erofs@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322797; l=7178;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=Wvl+4siWCTHC5VLaWnvqO2sRLCn+iDgqK8uK0hXOfC8=;
 b=/nf+CJBS+fU27OaAersTWTnqJ8v1KBQ51nisN8qdUoJWZiXmbE5xvy2CtsTCSWvxkHvpW+v5K
 49/2XXmC6j6D840PoK8YWrYHPV95HfNIIVC9Nm8CWkeGJrCMrp6/jNa
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

erofs_fc_parse_param() stores an arbitrary 64-bit fsoffset= mount
option into sbi->dif0.fsoff without checking alignment, and
erofs_fc_fill_super() calls erofs_read_superblock() before checking
whether fsoffset is aligned to sb->s_blocksize.

In block-device mode, erofs_init_metabuf() sets buf->off to
sbi->dif0.fsoff, and erofs_bread() maps a single PAGE_SIZE page via
kmap_local_page() and returns buf->base + ((buf->off + offset) &
~PAGE_MASK).  erofs_read_superblock() calls erofs_read_metabuf(&buf,
sb, 0, false) and adds EROFS_SUPER_OFFSET (1024) to the returned
pointer.  When (fsoffset & ~PAGE_MASK) + 1024 + sizeof(*dsb) exceeds
PAGE_SIZE (including a valid 1024-byte-aligned fsoffset=3072 on a
1 KiB-block image, or an unaligned fsoffset=4095), dsb points past
the end of the mapped page.  On a 1 KiB-block EROFS image mounted
at fsoffset=3072, Generic KASAN reports:

  BUG: KASAN: use-after-free in erofs_fc_fill_super+0x2b04/0x36c0
  Read of size 4 at addr ffff88800f8c1000 by task test_erofs_fsof/102
  ...
  erofs_fc_fill_super
  get_tree_bdev_flags
  erofs_fc_get_tree
  vfs_get_tree
  fc_mount
  path_mount
  __x64_sys_mount

The KASAN classification reflects that the adjacent physical page was
free; the source-level operation is an out-of-page read at offset
0x1000 past the mapped folio page.  Two related out-of-page reads
occur on the same path: erofs_superblock_csum_verify() checksums up
to (1 << blkszbits) - 1032 bytes past dsb->checksum before fsoffset
alignment is checked (reading up to 2048 bytes past the page for a
4 KiB-block image at fsoffset=2048), and erofs_read_metadata() bounds
each memcpy() chunk by sb->s_blocksize - erofs_blkoff(sb, *offset)
without accounting for buf->off (reading past the mapped page during
z_erofs_parse_cfgs() even for a valid block-aligned fsoffset=2048).

Mounting EROFS on a block device requires CAP_SYS_ADMIN in the
initial user namespace.  A relevant boundary is a privileged image
mounter or container runtime passing a caller-influenced fsoffset=
option or mounting an EROFS image embedded at a sub-page block
offset.

Reject fsoffset values that are not 512-byte aligned in
erofs_fc_parse_param(), read the superblock via
erofs_read_metabuf(&buf, sb, EROFS_SUPER_OFFSET, false), verify
fsoffset alignment against (1UL << sbi->blkszbits) in
erofs_read_superblock() before erofs_superblock_csum_verify(), pass
dsb directly to erofs_superblock_csum_verify(), and clamp each copy
in erofs_read_metadata() by PAGE_SIZE - offset_in_page(buf->off +
*offset).  With this change, a valid 1 KiB-block image at
fsoffset=3072 and a valid 2 KiB-block compressed-config image at
fsoffset=2048 mount cleanly without KASAN reports, while misaligned
fsoffset=2048 (4 KiB blocks) and fsoffset=4095 are rejected with
-EINVAL before any checksum or out-of-page access.  Z3 SMT checking
confirms all three out-of-page conditions are unreachable for any
valid block size and offset after the fix.  A test case and full
validation logs are available on request.

The vulnerable code is present in upstream mainline v7.4-rc3.
Runtime verification and fix validation were performed in an x86-64
QEMU/KVM guest running v7.4-rc3 with Generic KASAN, UBSAN, and
lockdep.

Fixes: c36ec00d7f67 ("erofs: add 'fsoffset' mount option to specify filesystem offset")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
Changes in v2:
- Resend via B4 Relay because the original email gained extra blank lines.
- No code changes.
- Link to v1: https://lore.kernel.org/r/20261122030055.8408-1-fadouse@pm.me
---
 fs/erofs/super.c | 28 ++++++++++++++++------------
 1 file changed, 16 insertions(+), 12 deletions(-)

diff --git a/fs/erofs/super.c b/fs/erofs/super.c
index e92a7fa90ae..66ba9dbd8ff 100644
--- a/fs/erofs/super.c
+++ b/fs/erofs/super.c
@@ -38,9 +38,9 @@ void _erofs_printk(struct super_block *sb, const char *fmt, ...)
 	va_end(args);
 }
 
-static int erofs_superblock_csum_verify(struct super_block *sb, void *sbdata)
+static int erofs_superblock_csum_verify(struct super_block *sb,
+					struct erofs_super_block *dsb)
 {
-	struct erofs_super_block *dsb = sbdata + EROFS_SUPER_OFFSET;
 	u32 len = 1 << EROFS_SB(sb)->blkszbits, crc;
 
 	if (len > EROFS_SUPER_OFFSET)
@@ -109,7 +109,7 @@ void *erofs_read_metadata(struct super_block *sb, struct erofs_buf *buf,
 	*lengthp = len;
 
 	for (i = 0; i < len; i += cnt) {
-		cnt = min_t(int, sb->s_blocksize - erofs_blkoff(sb, *offset),
+		cnt = min_t(int, PAGE_SIZE - offset_in_page(buf->off + *offset),
 			    len - i);
 		ptr = erofs_bread(buf, *offset, true);
 		if (IS_ERR(ptr)) {
@@ -268,16 +268,14 @@ static int erofs_read_superblock(struct super_block *sb)
 	struct erofs_sb_info *sbi = EROFS_SB(sb);
 	struct erofs_buf buf = __EROFS_BUF_INITIALIZER;
 	struct erofs_super_block *dsb;
-	void *data;
 	int ret;
 
-	data = erofs_read_metabuf(&buf, sb, 0, false);
-	if (IS_ERR(data)) {
+	dsb = erofs_read_metabuf(&buf, sb, EROFS_SUPER_OFFSET, false);
+	if (IS_ERR(dsb)) {
 		erofs_err(sb, "cannot read erofs superblock");
-		return PTR_ERR(data);
+		return PTR_ERR(dsb);
 	}
 
-	dsb = (struct erofs_super_block *)(data + EROFS_SUPER_OFFSET);
 	ret = -EINVAL;
 	if (le32_to_cpu(dsb->magic) != EROFS_SUPER_MAGIC_V1) {
 		erofs_err(sb, "cannot find valid erofs superblock");
@@ -289,6 +287,11 @@ static int erofs_read_superblock(struct super_block *sb)
 		erofs_err(sb, "blkszbits %u isn't supported", sbi->blkszbits);
 		goto out;
 	}
+	if (sbi->dif0.fsoff & ((1UL << sbi->blkszbits) - 1)) {
+		erofs_err(sb, "fsoffset %llu is not aligned to block size %lu",
+			  sbi->dif0.fsoff, 1UL << sbi->blkszbits);
+		goto out;
+	}
 	if (dsb->dirblkbits) {
 		erofs_err(sb, "dirblkbits %u isn't supported", dsb->dirblkbits);
 		goto out;
@@ -296,7 +299,7 @@ static int erofs_read_superblock(struct super_block *sb)
 
 	sbi->feature_compat = le32_to_cpu(dsb->feature_compat);
 	if (erofs_sb_has_sb_chksum(sbi)) {
-		ret = erofs_superblock_csum_verify(sb, data);
+		ret = erofs_superblock_csum_verify(sb, dsb);
 		if (ret)
 			goto out;
 	}
@@ -569,6 +572,10 @@ static int erofs_fc_parse_param(struct fs_context *fc,
 			clear_opt(&sbi->opt, DIRECT_IO);
 		break;
 	case Opt_fsoffset:
+		if (result.uint_64 & (SECTOR_SIZE - 1))
+			return invalfc(fc,
+				       "fsoffset %llu is not 512-byte aligned",
+				       result.uint_64);
 		sbi->dif0.fsoff = result.uint_64;
 		break;
 	case Opt_inode_share:
@@ -758,9 +765,6 @@ static int erofs_fc_fill_super(struct super_block *sb, struct fs_context *fc)
 			return -EINVAL;
 		}
 	}
-	if (sbi->dif0.fsoff & (sb->s_blocksize - 1))
-		return invalfc(fc, "fsoffset %llu is not aligned to block size %lu",
-			       sbi->dif0.fsoff, sb->s_blocksize);
 
 	if (test_opt(&sbi->opt, DAX_ALWAYS) && sbi->blkszbits != PAGE_SHIFT) {
 		erofs_info(sb, "unsupported blocksize for DAX");

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-01-erofs-fsoffset-oob-v2-9c629f3ad714-cb3ae037c08c

Best regards,
--  
YanXin Li <fadouse@pm.me>

