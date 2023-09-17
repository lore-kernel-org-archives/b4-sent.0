From: Jianguo Bau <roidinev@gmail.com>
Date: Sun, 17 Sep 2023 23:04:01 +0800
Subject: [PATCH] mm/writeback: Update filemap_dirty_folio() comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230917-trycontrib1-v1-1-db22630b8839@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGAVB2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDS0Nz3ZKiyuT8vJKizCRD3eQki7Q0CxMDc0uTZCWgjoKi1LTMCrBp0bG
 1tQBsnUXdXQAAAA==
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-fsdevel@vger.kernel.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, Jianguo Bau <roidinev@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1694963054; l=1010;
 i=roidinev@gmail.com; s=20230906; h=from:subject:message-id;
 bh=e7I1qPIXQ/mVKNWlcvVD0erRN97KbQ0kdRdeC2hZk4g=;
 b=trGc0zHM0wysIWlSONy9j7FLdZmOah1N9MQVJhlsORkyZ2GnQ+Mgw6Lap9SZve9f8nwMvXPJP
 P5bgnzAkVtXD7zJ5iOftev7XsBu/uEPEdtsdQjHwlVLI1U6JyeYe8uR
X-Developer-Key: i=roidinev@gmail.com; a=ed25519;
 pk=Itb2tVLere2RkCXs1smCQpxuXvWY0XesWo353ZMHfxs=
X-Endpoint-Received: by B4 Relay for roidinev@gmail.com/20230906 with auth_id=82
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change to use new address space operation dirty_folio

Signed-off-by: Jianguo Bau <roidinev@gmail.com>
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
Jianguo Bau <roidinev@gmail.com>

