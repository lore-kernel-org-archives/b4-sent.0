From: Giorgi Tchankvetadze <giorgitchankvetadze1997@gmail.com>
Date: Tue, 02 Jun 2026 15:32:45 +0400
Subject: [PATCH v2] mm: mm_init: use div64_ul() instead of do_div()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-mm-div64-cleanup-v1-1-bf5d67d89d93@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAMAzAviI9W6hFd/Ar4mG4qgU3x4ZDEP/u8
 BhC8kCWpJJhbB5IUjTrGSp0bQPLbsMmqK4yMLEhQ4zeo9NielwOseGKOJB11dLKzkLNYpJV738
 5QWGY3/cD8nlNO2YAAAA=
X-Change-ID: 20260602-mm-div64-cleanup-50ad2020f2da
To: Mike Rapoport <rppt@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Giorgi Tchankvetadze <giorgitchankvetadze1997@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780399980; l=1366;
 i=giorgitchankvetadze1997@gmail.com; s=20260602; h=from:subject:message-id;
 bh=J2B8gGLDwptZpFtucevPEHSpg8qUokxrjp8b+S4c/dY=;
 b=IHwk3v2WYj8xDPtjn66FVDPMkmX2ieJh93XUEOtNj8TQxXIWSL2vr6Zkn7vrk4523G/Hpp2WF
 FwFTOOWtAp3CXDFOFZchH3Tof7Jyj1gdbiBJe9KWcPfbUA9GJuHOlOL
X-Developer-Key: i=giorgitchankvetadze1997@gmail.com; a=ed25519;
 pk=D0cYZsZ7i5cTf2kRt6N7un+iLfmUPM7OwMURPmVnmEI=
X-Endpoint-Received: by B4 Relay for giorgitchankvetadze1997@gmail.com/20260602 with auth_id=804
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes Coccinelle/coccicheck warning reported by do_div.cocci.

Compared to do_div(), div64_ul() does not implicitly cast the divisor and
does not unnecessarily calculate the remainder.

There are no functional changes. The benefit is purely a semantic cleanup
that better communicates the intent of the division and resolves the
static analysis warning.

Signed-off-by: Giorgi Tchankvetadze <giorgitchankvetadze1997@gmail.com>
---
v2:
- Add changelog text explaining that the change is a semantic cleanup
  with no functional impact, as requested by Mike Rapoport.
---
 mm/mm_init.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/mm/mm_init.c b/mm/mm_init.c
index f9f8e1af921cda91d812cffdad2f1a0698cfd6ac..4e0909a721d227b097653ed6aaa019960a7c3383 100644
--- a/mm/mm_init.c
+++ b/mm/mm_init.c
@@ -2412,7 +2412,7 @@ void *__init alloc_large_system_hash(const char *tablename,
 	/* limit allocation size to 1/16 total memory by default */
 	if (max == 0) {
 		max = ((unsigned long long)nr_all_pages << PAGE_SHIFT) >> 4;
-		do_div(max, bucketsize);
+		max = div64_ul(max, bucketsize);
 	}
 	max = min(max, 0x80000000ULL);
 

---
base-commit: 6f3ed7fec72fc8979b2a8c7219c0a9fcfc8d07b5
change-id: 20260602-mm-div64-cleanup-50ad2020f2da

Best regards,
-- 
Giorgi Tchankvetadze <giorgitchankvetadze1997@gmail.com>

