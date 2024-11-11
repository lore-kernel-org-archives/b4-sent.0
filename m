From: Janne Grunau <j@jannau.net>
Date: Mon, 11 Nov 2024 07:56:31 +0100
Subject: [PATCH v3 1/4] lmb: Do not use global LMB variable in _lmb_free()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-io_lmb_apple_dart_iommu-v3-1-32c05da51d72@jannau.net>
References: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
In-Reply-To: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
To: Tom Rini <trini@konsulko.com>, Mark Kettenis <kettenis@openbsd.org>, 
 Sughosh Ganu <sughosh.ganu@linaro.org>, Simon Glass <sjg@chromium.org>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1134; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=yY4POAUicULzkGYsRkw8yQkAbaMmPJp0vghM49loTh4=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnTDVWtK7hyRqviw/51nRvxam8CvhyaYTl0po6f2j2f/i
 0dbBXntO0pZGMS4GGTFFFmStF92MKyuUYypfRAGM4eVCWQIAxenAEzkvTjD/1Dtd1rnHwrNnSng
 53goTFrVLv6k7parbYJ/nbfoXZ6m85/hr8TKuIW3Vt0+UnfxsrPcnjPcibGrvrLcnmVevavLqLl
 oKRcA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It will be re-used with a lmb list pointer as argument for IOVA
allocations in the apple_dart iommu driver.

Reviewed-by: Tom Rini <trini@konsulko.com>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/lmb.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/lib/lmb.c b/lib/lmb.c
index 8b306e4de8e1fe35c44d0b4b73424cdb007905b4..cc2554dfa947182806c37b31da292becc1c868a1 100644
--- a/lib/lmb.c
+++ b/lib/lmb.c
@@ -492,10 +492,10 @@ long lmb_add(phys_addr_t base, phys_size_t size)
 	return lmb_map_update_notify(base, size, MAP_OP_ADD, LMB_NONE);
 }
 
-static long _lmb_free(phys_addr_t base, phys_size_t size)
+static long _lmb_free(struct alist *lmb_rgn_lst, phys_addr_t base,
+		      phys_size_t size)
 {
 	struct lmb_region *rgn;
-	struct alist *lmb_rgn_lst = &lmb.used_mem;
 	phys_addr_t rgnbegin, rgnend;
 	phys_addr_t end = base + size - 1;
 	int i;
@@ -558,7 +558,7 @@ long lmb_free_flags(phys_addr_t base, phys_size_t size,
 {
 	long ret;
 
-	ret = _lmb_free(base, size);
+	ret = _lmb_free(&lmb.used_mem, base, size);
 	if (ret < 0)
 		return ret;
 

-- 
2.47.0

