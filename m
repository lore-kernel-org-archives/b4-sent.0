From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 14 Aug 2024 01:12:13 +0800
Subject: [PATCH] mm: vmalloc: add optimization hint on page existence check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-fix_vmap_unlikely-v1-1-cd7954775f12@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOyTu2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDC0MT3bTMiviy3MSC+NK8nMzs1JxKXSNLc+MUo+QkSwOTJCWgvoKiVKA
 isJnRsbW1AH/FfypjAAAA
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>, Christoph Hellwig <hch@infradead.org>, 
 Hariom Panthi <hariom1.p@samsung.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1127;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=aKT10OS/EIu/f+l3Yr9+KAyeKsqSPbtIB3kaInDaHw8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmu5Pu3nSA77waXX7mNuwFc+0VAxl78qImyULQr
 uXa9ljONeOJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZruT7gAKCRCwMePKe/7Z
 bnjMD/4xPtGTC99xAoo1V0wlI+UMEiaSAmgH/aqfr4Mzmt+XgAIRz5yHddKDAq2Dbc22YEH3Y3Z
 UqKupngslY6Y4qlv6Ufozw2o7NmTI8dojgtLPIbPfBslKNQW28V7qqLCEN01tsYQm2SFFDq7Jo1
 wG1WyGkMyMrflLEKVTONBBCelhFpyZq2cRmwqmVb6+wsm3oA47ueQFRupufsjM6UnpUWMJX0G7h
 Q+CG+Be/JuRiu7YwkIl8H1HgSYzcQz6Djk+l6YUUSgeM72nFkLfoYqh29EXJI4FGiOFdvdMl8NB
 1XSDmkAxh4Ab3IeUg7fMkBqloVUWAGRUpOIslIV+INdzgzmsFldHmjK3eaXw/lY1JCqBOYHc8PE
 ytCf6MopH/QfvvkIc4zcczvG3cRCOHLOVm3EnUt48JyqOLYM7mI1yl5WKpTNxKe0gF0SK56jjgZ
 ign8iHfC5yeenD0FA7kqOoh7laVOHS4B4jDDU1LsNCaU/LuFwsUkG1+WC4IuPpTkVutPi2fYjBL
 pstgO1VJ08V2U46aue7dv+yB/PAcWMwgM98SYKp+poQ9T/umAl0FetGEkuRJcb8dMkN3jYRgV81
 YzdiC71umtNVsSis9HZBH5+U2p9PlC/VkWi1jTNLcS4IIRKskEkuFwbJ1CMrh7FAZ161XOblLx3
 5Ry2VNwZwvx5eaA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In commit 21e516b913c1 ("mm: vmalloc: dump page owner info if page is
already mapped"), a BUG_ON macro was changed into an if statement, where
the compiler optimization hint introduced in the BUG_ON macro was removed
along with this change. This patch adds back the hint.

Fixes: 21e516b913c1 ("mm: vmalloc: dump page owner info if page is already mapped")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 mm/vmalloc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 6b783baf12a1..5d031fc83f04 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -105,7 +105,7 @@ static int vmap_pte_range(pmd_t *pmd, unsigned long addr, unsigned long end,
 	if (!pte)
 		return -ENOMEM;
 	do {
-		if (!pte_none(ptep_get(pte))) {
+		if (unlikely(!pte_none(ptep_get(pte)))) {
 			if (pfn_valid(pfn)) {
 				page = pfn_to_page(pfn);
 				dump_page(page, "remapping already mapped page");

---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240814-fix_vmap_unlikely-2973d2cb904b

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

