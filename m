From: Dominique Martinet <asmadeus@codewreck.org>
Date: Mon, 11 Aug 2025 16:39:06 +0900
Subject: [PATCH 2/2] iov_iter: iov_folioq_get_pages: don't leave empty slot
 behind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250811-iot_iter_folio-v1-2-d9c223adf93c@codewreck.org>
References: <20250811-iot_iter_folio-v1-0-d9c223adf93c@codewreck.org>
In-Reply-To: <20250811-iot_iter_folio-v1-0-d9c223adf93c@codewreck.org>
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Christian Brauner <brauner@kernel.org>, David Howells <dhowells@redhat.com>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Maximilian Bosch <maximilian@mbosch.me>, Ryan Lahfa <ryan@lahfa.xyz>, 
 Christian Theune <ct@flyingcircus.io>, Arnout Engelen <arnout@bzzt.net>, 
 linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=1037;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=Gnweznn9Yf2tL9n/TItIqJV0L8m6ff7ta3Y3p0JUXrk=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBomZ4juLVGBQDWHE7zCanhXyXfjVv5/SO1+HqYv
 UGZFo18LJeJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJmeIwAKCRCrTpvsapjm
 cCe2D/9AMYNS6PUmG3VauQsdgyu9ikb3/E+f/a2g0lbGg83sq4XtDxWh83GsQXmHgPrlNyDUsCa
 +1cyM7QTyN8k15Pkt83L6noZ14CQIGBnT6ZWcBop0tK+qen0/+WV11y81L26gk8u0CIOoWzLZUz
 HZlLivDANjbXZnx0UipBnWncTwH4yyhcp3jVhpwEeOWqzYlkB+MF8q7sn8KTf3/sjHY6Nf+9Fxx
 fsvZ34ZcuC1GSySo+HSgCQviOwdt3HsbxKiGSTrHnvZjdDrLXECECHh3l6MsAnmZIE36dvRdZ+X
 raXvmlP3fdEIXQp3+ty0DrAswPxvcVIGK+P+TOMc1eLJ4qBhGtppcUJTkCKjP+2nrxeXTJS2IKW
 bXCV1/0hhc7aJS+ReVWbxyMtOWck0ATemIdSU2pwbL5fUcv2Uuc9wL7LFw91H2diUKm9IOQvDLB
 UH4QS3Kg7mxjZSI4MvFnbrNk9oDWAMUEEEaSWfEFNSOlZy0dcpqD27U3h680r0PnVbmh6ljktQy
 O+pCQza+b8RV70SfbHEZp87bGvNi2sc2uApzkuX2eprO7zmaKHHmXXxC6CzLfjAK5UMj4UTHLTN
 lCCM9HjJ+9QAU2GA3MC9YDRnDd9/wVsUq3eAK946tgu5OwU8wEOKSOL2pndP3s9LSCmacgmhcE6
 Gt+u8IJlxOLwKow==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After advancing into a folioq it makes more sense to point to the next
slot than at the end of the current slot.
This should not be needed for correctness, but this also happens to
"fix" the 9p bug with iterate_folioq() not copying properly.

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

