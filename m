From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 01:05:57 +0100
Subject: [PATCH] mm/vmalloc: warn only once when vmalloc detect invalid gfp
 flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-only-one-vmalloc-v1-1-29f8eacb4605@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAGS4G2kC/x2MQQqAIBAAvxJ7TmilKPtKdDDdasE0FKKQ/p50G
 ZjDTIZEkSnBWGWIdHHi4ItgXYHZtd9IsC0OspEdIg4iePcUkLgO7VwwYhmsUn3Tdr1CKNkZaeX
 7X07z+37nDonqYgAAAA==
X-Change-ID: 20251118-only-one-vmalloc-b8d997045791
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>, 
 "Vishal Moola (Oracle)" <vishal.moola@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1266; i=david@ixit.cz;
 h=from:subject:message-id; bh=+3LV6m3PqRpzFWM6pdP/J/h+Ov5Mmi3IXlzFVsT12F0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpG7hnPrb694PSAtJVrUC41ulsIGwk2mg7uisJn
 XnAjQL2gKSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRu4ZwAKCRBgAj/E00kg
 cqr2D/9RDSNedfot2LwKkIjnQ1JC5RtS0l4ZwgScYSeT8uLysnaMH8XbHHvgZ2HrEvIvSi1DmYN
 +lRq3yAQDBbAZGPheBtnhq0KR4Tq1vUMg+VUiTjjESM3aPuNZDVTzHSmdFrKNBCq21Rmsa1zCWa
 BXBoMKH/u10LIAn5cYYim3gMZYeTPL9lSsAbIkrnIkWFQnsZ8Gg7xm+3j4EldkLpWYwR2m+NL38
 jsUBtlCxTukzD030BYcXChxL5vTSUa5jYxeZm9l4h5RP8/6C159fE9EJjSI3KVjVRHO8/9P5o/P
 /yRU/gvp90rpTY6iRdMaFhsYcOxJXeCMXvyTJ6tGKLH4b0rP+VicjBzf6rzXEFKAelUEX6VxY3K
 7qQ0a4KdV7Z7SFOsShotfcZpgH8HWKX5dJxe3wK40Fue+1WzmLfo2gXpf73pLk6/xGjDnodbLem
 Hl9s9W3jnlpbKr7fMbcfW2GSDhK+okv4u84GPYIIK5IMPBDxACjYgouhFxS3SFm8yZDTdF2QtBd
 +DsTlLuL7DaVQlhsYr8vuBxKhyTEkll3U4FTSznfMqaHNqnKBHHgJIecFWfPDoCtaLUPTSPkQ75
 bF4b45mzh/e5Xge43nUsHoJ8JQB/r9KIXXnjsKGLZCy1IGgwbmBS7AAa0XIcMGddxIXT++TFqu1
 ToK0FBKpdHKOnfA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without WARN_ONCE, the logs get spammed immediately after the boot,
on devices as OnePlus 6T (Snapdragon 845).

Fixes: 7179b2256315 ("mm/vmalloc: warn on invalid vmalloc gfp flags")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
I'm not 100% sure this is the right solution, but having WARN_ONCE or
rate limited warnings here helps a lot on devices as OnePlus 6 (sdm845).

Please let me know what you think.
---
 mm/vmalloc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/mm/vmalloc.c b/mm/vmalloc.c
index 49e0b68768d73..2a3ee17093d6e 100644
--- a/mm/vmalloc.c
+++ b/mm/vmalloc.c
@@ -3934,8 +3934,8 @@ static gfp_t vmalloc_fix_flags(gfp_t flags)
 	gfp_t invalid_mask = flags & ~GFP_VMALLOC_SUPPORTED;
 
 	flags &= GFP_VMALLOC_SUPPORTED;
-	WARN(1, "Unexpected gfp: %#x (%pGg). Fixing up to gfp: %#x (%pGg). Fix your code!\n",
-			invalid_mask, &invalid_mask, flags, &flags);
+	WARN_ONCE(1, "Unexpected gfp: %#x (%pGg). Fixing up to gfp: %#x (%pGg). Fix your code!\n"
+		  invalid_mask, &invalid_mask, flags, &flags);
 	return flags;
 }
 

---
base-commit: 0c1c7a6a83feaf2cf182c52983ffe330ffb50280
change-id: 20251118-only-one-vmalloc-b8d997045791

Best regards,
-- 
David Heidelberg <david@ixit.cz>

