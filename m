From: Dominique Martinet <asmadeus@codewreck.org>
Date: Tue, 12 Aug 2025 06:28:02 +0900
Subject: [PATCH v2 2/2] iov_iter: iov_folioq_get_pages: don't leave empty
 slot behind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250812-iot_iter_folio-v2-2-f99423309478@codewreck.org>
References: <20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org>
In-Reply-To: <20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org>
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
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBommB1jlBau7xcwTcqmY8qrpOsUxyecm2YZfnGb
 RD0o4qZhZmJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJpgdQAKCRCrTpvsapjm
 cEb8D/9an6eblnzeoL0M2VSMUQ7QI7IMsT4MlMEeRG5w+2Lfijjtb+z92PO1JsMMYdLjP2ecPF6
 gs7b7OLUpbc6WSRODpT713hfswV+Sc+d4AEBGNCna0Tr9caRapg8JSiC1nMvL4TmlBnHlWfRfx8
 D5X57VtMAsqkaIoY0fs5yu8Ik6W+DXU5MT1TNz4MeI4sRAJc8heC+lXwgcA+gyPJAiW0rYyJVPe
 qUwFP6iq+udqTBRqiV5BOC7RvEU0onpuxdDz/sZk9h88Tpb7S8ZeJgVfaAehBkjaTTs2E/CcMtx
 0xk1QN/JR4W/Xb9gIqB98G+YpdgpAECCH53nmNC0tGD4IzQkO7f35Jjmds6/6NSdzQ9PHmPPf54
 JOYIHEdepLhQoYj7PM5BgCn/UdVslFjYVRkBAFb+TLRMCKqTxMox3oR5dwSJuKmtSgRLAWL8sU+
 X4sZs46mogw9PuvFFxlvR6tYNeZp9qC3iXzprDYxaKYFppZxBpLVFXFFw5F5kUoR9/H5gM7jUgQ
 NRT/KRc1y7a8UkC+uWRzrd4zhT/O1LfM+hCmFOHxLPw3q4XlVoavqlZ1AJO60vLcIActCf+2z/l
 HS+ecvMMzlx+0FtND9QBIJ6e+WIOCH7XAG88mNVTBKPjAfyzYOkbZ4Mtdo3aHNquSSPjgNS/hba
 eWKqMemYBhQyNTg==
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

