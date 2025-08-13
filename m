From: Dominique Martinet <asmadeus@codewreck.org>
Date: Wed, 13 Aug 2025 15:04:56 +0900
Subject: [PATCH v3 2/2] iov_iter: iov_folioq_get_pages: don't leave empty
 slot behind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250813-iot_iter_folio-v3-2-a0ffad2b665a@codewreck.org>
References: <20250813-iot_iter_folio-v3-0-a0ffad2b665a@codewreck.org>
In-Reply-To: <20250813-iot_iter_folio-v3-0-a0ffad2b665a@codewreck.org>
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Christian Brauner <brauner@kernel.org>, David Howells <dhowells@redhat.com>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Maximilian Bosch <maximilian@mbosch.me>, Ryan Lahfa <ryan@lahfa.xyz>, 
 Christian Theune <ct@flyingcircus.io>, Arnout Engelen <arnout@bzzt.net>, 
 linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=1129;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=hWtTUCvGG0PvbE6UasHSB7hwyWcYL54anMdr7Xzd+hY=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBonCsS8DBTLsHW8XBOAEFJt6+XqEbzlCN7ATJz5
 Z0/42O1PsmJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJwrEgAKCRCrTpvsapjm
 cB0zEACWziYzUV7u3M9j8x4M7D0PqLTmDhsm+2LNpUdUGwVgEYqYBL80OMm9OztuncWP112oyQP
 0nmA+62qaQDsmL38BAg/PVV2TAz8dgghGiVojmD6ZEyatETk9VubTS4YstNToWX4cLbLKxpvY8w
 BMsIfW6IpwSBhJJifmj/+WQx2trAMD9ir13yPnvU6IUMdebf7Fsl5G4Ser1Vy5V+ViqOkrBgPpU
 uAhi6DKdn6PUaLaZzro/nT3ysBMZjXL3Lw2Mvrt7dRPhSyM3ZCsBazHMRAnUVNjPAJIHMwzCbWH
 Q/Vt0gYuNbuf4jrdwVu4lkQfkIVE0W3PgyJVba+dFE0M+oOavlZ3xLp95r/rLLzDEMH/EIyZRJY
 PK05FQN/I8q2pmNuNpRd6KAd8u0nfcpZ/aDnnE3+CM7K3u9/9tL/zhq4LpLHeF5MBqIt+/iQljn
 h5l+hzwpSJHG28KiwuV6oXWyFhuwMKrAA9OTxICwwKEPRHxWUpthkrXBWDP2kObujVhpUZjDnsc
 eKjXZoznHbqdhmT2VUrxb3wvKAXBmRfqXVKxXix8v9FHziA1ZuGYyhB5eMk8M72Z/ChMXxGpPuS
 6slhyOnhff3Xmv0ydjbZ2ngePhFFWsiBQ/Q5sH/84aqe+o9299b+6scTEQSfjhpKwjqRPISafgY
 rh9QyztOL/OFUDA==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After advancing into a folioq it makes more sense to point to the next
slot than at the end of the current slot.
This should not be needed for correctness, but this also happens to
"fix" the 9p bug with iterate_folioq() not copying properly.

Acked-by: David Howells <dhowells@redhat.com>
Tested-by: Arnout Engelen <arnout@bzzt.net>
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 lib/iov_iter.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/lib/iov_iter.c b/lib/iov_iter.c
index f9193f952f49945297479483755d68a34c6d4ffe..65c05134ab934e1e0bf5d010fff22983bfe9c680 100644
--- a/lib/iov_iter.c
+++ b/lib/iov_iter.c
@@ -1032,9 +1032,6 @@ static ssize_t iter_folioq_get_pages(struct iov_iter *iter,
 			maxpages--;
 		}
 
-		if (maxpages == 0 || extracted >= maxsize)
-			break;
-
 		if (iov_offset >= fsize) {
 			iov_offset = 0;
 			slot++;
@@ -1043,6 +1040,9 @@ static ssize_t iter_folioq_get_pages(struct iov_iter *iter,
 				slot = 0;
 			}
 		}
+
+		if (maxpages == 0 || extracted >= maxsize)
+			break;
 	}
 
 	iter->count = count;

-- 
2.50.1

