From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:37:16 +0100
Subject: [PATCH v2] mm/vmalloc: warn only once when vmalloc detect invalid
 gfp flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-only-one-vmalloc-v2-1-fe702aa68d8b@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAGtaHGkC/32NQQqDMBBFryKzbooTtJqueo/iQuNYB9JEEglay
 d2beoBuPrwP//0DAnmmAPfiAE+RAzubQV4K0HNvXyR4zAyylDUitsJZs+cgEd+9MU6LoR2Vasq
 qbhRCni2eJt5O5bPLPHNYnd/Ph4i/9o8sokAh1dRSr4fqVtYP3ni96g90KaUvfHYjVa4AAAA=
X-Change-ID: 20251118-only-one-vmalloc-b8d997045791
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>, 
 "Vishal Moola (Oracle)" <vishal.moola@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257; i=david@ixit.cz;
 h=from:subject:message-id; bh=54i1YH3FbEzkceweElaDmkfgd6gmC6hf5zbFIJvmoD0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFpuJ+ejYSTUfSbADLtP9gVRTjv696wsmMt5H
 LWLalPK7qOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxabgAKCRBgAj/E00kg
 cqaeEACisQrL/b2MB5OMb7gMPoBEJzUnsNF3Y6KJ1b8zABV832iROP4kQ71qBkGr2GUG7olBzyY
 09YY/DGfZrUcnUnAuf/lhBrqg4WXBznjJDudhxk/zLK3Zv8TYmpysA4KLJquV4sJA2mP/em3O40
 yKgJjcuwotuyV8Qe8ofP8tcxCSl2jbA/wcOC93prPbxh/0x9u2lLaj7Tm/wti6iMo7hjVZLr60Z
 4jsMUKGxJy5/wqr+5e2oN9mzZcce7bGtNw7VKQNqyxpZTFbrqmNmoYdWM5d21B5vuY70I/U9ko6
 7mhMDCTIIQeoYiQ1bTrL6hPK1aG4KeLcul2EojTGaVyGAtcYDb7E9u3bLioYJCPJbvgYH27oQHY
 8mO4dfzh1g6EO568QqW6+rBbE95s5Rr+puKLSEyI9DPjl1Ynhzw/Sn5MMXX3jWLlv+4s4wePHu0
 R8NgtmSBOYw8IrwFrbAMk+DYn+6D9pEN81st9xMi3d/f3GaHb5/bVQyh5LgfALbWzDZxWtsUvBM
 o1jIHhbwodFsYTlx6vEP9YzOozUNDf3JDR0txNSvYHqprZgmsXb30+whk4n3eVUYAqBqIcXwRWO
 UB4YC+nqOVcCmAoXMFU0JcfCaUyiMcrUA380gFqUUpMB5rs5Lnix3VDAd2saEUNW9T9N0wjilTe
 khx4navcxX8ASLA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without WARN_ONCE, the logs get spammed immediately after the boot,
on devices as OnePlus 6T (Snapdragon 845).

Fixes: 7179b2256315 ("mm/vmalloc: warn on invalid vmalloc gfp flags")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Resend as requested.
---
Changes in v2:
- Fixed accidentally removed comma.
- Link to v1: https://lore.kernel.org/r/20251118-only-one-vmalloc-v1-1-29f8eacb4605@ixit.cz
---
 mm/vmalloc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 49e0b68768d73..59a4ea8b7f91f 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3934,8 +3934,8 @@ static gfp_t vmalloc_fix_flags(gfp_t flags)
 	gfp_t invalid_mask = flags & ~GFP_VMALLOC_SUPPORTED;
 
 	flags &= GFP_VMALLOC_SUPPORTED;
-	WARN(1, "Unexpected gfp: %#x (%pGg). Fixing up to gfp: %#x (%pGg). Fix your code!\n",
-			invalid_mask, &invalid_mask, flags, &flags);
+	WARN_ONCE(1, "Unexpected gfp: %#x (%pGg). Fixing up to gfp: %#x (%pGg). Fix your code!\n",
+		  invalid_mask, &invalid_mask, flags, &flags);
 	return flags;
 }
 

---
base-commit: 0c1c7a6a83feaf2cf182c52983ffe330ffb50280
change-id: 20251118-only-one-vmalloc-b8d997045791

Best regards,
-- 
David Heidelberg <david@ixit.cz>

