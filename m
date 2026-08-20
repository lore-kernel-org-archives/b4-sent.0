From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Thu, 20 Aug 2026 10:25:48 +0800
Subject: [PATCH 5.10.y] f2fs: fix UAF issue in f2fs_merge_page_bio()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-origin-linux-5-10-y-v1-1-4c86e98a104d@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKtlhmoC/x2MSQqAMAwAv1JyNtIUXL8iHlyiBqSVFsUi/t3i3
 OYw80BgLxygVQ94viSIs0koUzBtg10ZZU4ORptS19Sg87KKxV3seWOBpDFiWfEyJGhsDKTy8Lz
 I/V87KHLSeYT+fT9ncmqIbQAAAA==
X-Change-ID: 20260819-origin-linux-5-10-y-67efaaaa1b92
To: stable@vger.kernel.org
Cc: jianxin.pan@amlogic.com, tuan.zhang@amlogic.com, 
 Chao Yu <chao@kernel.org>, JY <JY.Ho@mediatek.com>, 
 Jaegeuk Kim <jaegeuk@kernel.org>, Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787192748; l=3662;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=ycKKCfZIH7vZZ4DmcpPqP7+GTaVW2wSQs1qnLBxA2jM=;
 b=I+bkkrJXKZjsK+v9d4LrPWDUCbfMrQrXJCADVDa/1gzX39NPntd6TAvyrxBynpB4ecUTut571
 lZqTb08I8aMB/sUzC4ZXfSbs3p5lppvUJ0OFbsFsf3qZ3gej+HcyNpW
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chao Yu <chao@kernel.org>

commit edf7e9040fc52c922db947f9c6c36f07377c52ea upstream.

As JY reported in bugzilla [1],

Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
pc : [0xffffffe51d249484] f2fs_is_cp_guaranteed+0x70/0x98
lr : [0xffffffe51d24adbc] f2fs_merge_page_bio+0x520/0x6d4
CPU: 3 UID: 0 PID: 6790 Comm: kworker/u16:3 Tainted: P    B   W  OE      6.12.30-android16-5-maybe-dirty-4k #1 5f7701c9cbf727d1eebe77c89bbbeb3371e895e5
Tainted: [P]=PROPRIETARY_MODULE, [B]=BAD_PAGE, [W]=WARN, [O]=OOT_MODULE, [E]=UNSIGNED_MODULE
Workqueue: writeback wb_workfn (flush-254:49)
Call trace:
 f2fs_is_cp_guaranteed+0x70/0x98
 f2fs_inplace_write_data+0x174/0x2f4
 f2fs_do_write_data_page+0x214/0x81c
 f2fs_write_single_data_page+0x28c/0x764
 f2fs_write_data_pages+0x78c/0xce4
 do_writepages+0xe8/0x2fc
 __writeback_single_inode+0x4c/0x4b4
 writeback_sb_inodes+0x314/0x540
 __writeback_inodes_wb+0xa4/0xf4
 wb_writeback+0x160/0x448
 wb_workfn+0x2f0/0x5dc
 process_scheduled_works+0x1c8/0x458
 worker_thread+0x334/0x3f0
 kthread+0x118/0x1ac
 ret_from_fork+0x10/0x20

[1] https://bugzilla.kernel.org/show_bug.cgi?id=220575

The panic was caused by UAF issue w/ below race condition:

kworker
- writepages
 - f2fs_write_cache_pages
  - f2fs_write_single_data_page
   - f2fs_do_write_data_page
    - f2fs_inplace_write_data
     - f2fs_merge_page_bio
      - add_inu_page
      : cache page #1 into bio & cache bio in
        io->bio_list
  - f2fs_write_single_data_page
   - f2fs_do_write_data_page
    - f2fs_inplace_write_data
     - f2fs_merge_page_bio
      - add_inu_page
      : cache page #2 into bio which is linked
        in io->bio_list
						write
						- f2fs_write_begin
						: write page #1
						 - f2fs_folio_wait_writeback
						  - f2fs_submit_merged_ipu_write
						   - f2fs_submit_write_bio
						   : submit bio which inclues page #1 and #2

						software IRQ
						- f2fs_write_end_io
						 - fscrypt_free_bounce_page
						 : freed bounced page which belongs to page #2
      - inc_page_count( , WB_DATA_TYPE(data_folio), false)
      : data_folio points to fio->encrypted_page
        the bounced page can be freed before
        accessing it in f2fs_is_cp_guarantee()

It can reproduce w/ below testcase:
Run below script in shell #1:
for ((i=1;i>0;i++)) do xfs_io -f /mnt/f2fs/enc/file \
-c "pwrite 0 32k" -c "fdatasync"

Run below script in shell #2:
for ((i=1;i>0;i++)) do xfs_io -f /mnt/f2fs/enc/file \
-c "pwrite 0 32k" -c "fdatasync"

So, in f2fs_merge_page_bio(), let's avoid using fio->encrypted_page after
commit page into internal ipu cache.

Fixes: 0b20fcec8651 ("f2fs: cache global IPU bio")
Reported-by: JY <JY.Ho@mediatek.com>
Signed-off-by: Chao Yu <chao@kernel.org>
Signed-off-by: Jaegeuk Kim <jaegeuk@kernel.org>
Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 fs/f2fs/data.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/f2fs/data.c b/fs/f2fs/data.c
index 945cb6145dbb098351378368654d8fa9573b7507..2933b32032e790950ecb51b6f65e3765e5a49e17 100644
--- a/fs/f2fs/data.c
+++ b/fs/f2fs/data.c
@@ -968,7 +968,7 @@ int f2fs_merge_page_bio(struct f2fs_io_info *fio)
 	if (fio->io_wbc)
 		wbc_account_cgroup_owner(fio->io_wbc, fio->page, PAGE_SIZE);
 
-	inc_page_count(fio->sbi, WB_DATA_TYPE(page));
+	inc_page_count(fio->sbi, WB_DATA_TYPE(fio->page));
 
 	*fio->last_block = fio->new_blkaddr;
 	*fio->bio = bio;

---
base-commit: acccef89f184a697fee1c96a1dc9cccbba36937b
change-id: 20260819-origin-linux-5-10-y-67efaaaa1b92

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

