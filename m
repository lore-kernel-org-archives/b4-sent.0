From: Jianguo Bao <roidinev@gmail.com>
Date: Sun, 17 Sep 2023 23:35:20 +0800
Subject: [PATCH v2] mm/writeback: Update filemap_dirty_folio() comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230917-trycontrib1-v2-1-66ae0ce8f7c3@gmail.com>
X-B4-Tracking: v=1; b=H4sIALccB2UC/23MSwrDIBSF4a2EO67FR2i0o+6jZBCNJhcaLSrSE
 Nx7bcYd/gfOd0CyEW2Ce3dAtAUTBt+CXzow6+QXS3BuDZxyQRUbSI67CT5H1IwYLZ2TPR1Ub6A
 93tE6/Jzac2y9Ysoh7ide2G/97xRGGJk15zdBtZRCPZZtwtfVhA3GWusXa+9gg6YAAAA=
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-fsdevel@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Jianguo Bao <roidinev@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694964922; l=1148;
 i=roidinev@gmail.com; s=20230906; h=from:subject:message-id;
 bh=kvb09bksQ5sDwvuV+cJThLuKQhUb8lsRZC/HV07PBuA=;
 b=pT3oC5Q0lddFp2DM/hBD+Fq9TCIcs3SzJbQFAfGaMlUBjHTsRg9GZIcMdfhc8li3B5CQpTro4
 2R2UWQTOF6zAb78eiB8QQHFdw3Lq1xUrhUcHYxnvIzzKlC8kIBo99Ky
X-Developer-Key: i=roidinev@gmail.com; a=ed25519;
 pk=Itb2tVLere2RkCXs1smCQpxuXvWY0XesWo353ZMHfxs=
X-Endpoint-Received: by B4 Relay for roidinev@gmail.com/20230906 with auth_id=82
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change to use new address space operation dirty_folio

Signed-off-by: Jianguo Bao <roidinev@gmail.com>
---
Changes in v2:
- #1: Update author name.
- Link to v1: https://lore.kernel.org/r/20230917-trycontrib1-v1-1-db22630b8839@gmail.com
---
 mm/page-writeback.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/page-writeback.c b/mm/page-writeback.c
index b8d3d7040a50..001adbb4a180 100644
--- a/mm/page-writeback.c
+++ b/mm/page-writeback.c
@@ -2679,7 +2679,7 @@ void __folio_mark_dirty(struct folio *folio, struct address_space *mapping,
  * @folio: Folio to be marked as dirty.
  *
  * Filesystems which do not use buffer heads should call this function
- * from their set_page_dirty address space operation.  It ignores the
+ * from their dirty_folio address space operation.  It ignores the
  * contents of folio_get_private(), so if the filesystem marks individual
  * blocks as dirty, the filesystem should handle that itself.
  *

---
base-commit: f0b0d403eabbe135d8dbb40ad5e41018947d336c
change-id: 20230917-trycontrib1-cb8ff840794c

Best regards,
-- 
Jianguo Bao <roidinev@gmail.com>

