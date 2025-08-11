From: Dominique Martinet <asmadeus@codewreck.org>
Date: Tue, 12 Aug 2025 06:28:01 +0900
Subject: [PATCH v2 1/2] iov_iter: iterate_folioq: fix handling of offset >=
 folio size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250812-iot_iter_folio-v2-1-f99423309478@codewreck.org>
References: <20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org>
In-Reply-To: <20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org>
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Christian Brauner <brauner@kernel.org>, David Howells <dhowells@redhat.com>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Maximilian Bosch <maximilian@mbosch.me>, Ryan Lahfa <ryan@lahfa.xyz>, 
 Christian Theune <ct@flyingcircus.io>, Arnout Engelen <arnout@bzzt.net>, 
 linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Dominique Martinet <asmadeus@codewreck.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=2705;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=3BbpsQC1gAY33hqHbW6Vvzvllp5rOUEkHQ1XHsiSrr8=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBommB10IN5egx+Rr8UloHGfJcqXTMA8D0uoVhkF
 e1c6hRMWz6JAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJpgdQAKCRCrTpvsapjm
 cMHPEACEFnAwm1R1HodQQdkzlwTFQ0MGKBvJAeqjwOiixo9963tY8KbCdqavltbusRuAQCRxR7t
 CWweWhzyqDJz0RIinEgkliq4HsEq9QG4CuzHGR1uPTUL2/wB7ZnQeAjBdyRfJPtZadoF35etC+e
 TyW73BUxYYr+gS8PN9Tr71Hf5bFsg3hXOSIeg+o5wthn1vQYbW9LVhGs878pOqSSeoUdUbr1xTD
 Ng0A+tTGvRp4BSPbcIucPBcPJT3nSkNEvoeDN+ol37BhVQZJEUrvh33jy+DOLTRBKUynysZIAzP
 m+DbjdGS05D/Slb+WXlA0TRfaLmpUV7+y0odcRLI7cLv+Qu7XLwsxhTXpcsWZ8LqnTq09AIPj3N
 PBpVGO/r1ItRRFLA8MTv04/pbwP68j+I1a2NuMqHeq+Ohm+P0Uvv7pj4z37FmolaNhcZe3huzgH
 034yobtZnIMzmAjQmspsFbKbAACHa+Ix+rWx3GKi1LEPo2vsV50q80Mf9PD8qfhNAgUUNteVxPB
 2EziFjTgVy1eNobf4zu9EdPhQuU80KzpwRABysmq3FT43ZjwGhsh4UUIzcHS8rFIMcZE6LOuL/J
 GAfdXuWnmRW/lFuLqJSI31r8+x1xezz8m4yvBJB2H13ol0c/QtjIZFzSTBmAcJsrYoO0bXUZqJp
 sp+Qn7+lV3IFD/w==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's apparently possible to get an iov advanced all the way up to the
end of the current page we're looking at, e.g.

(gdb) p *iter
$24 = {iter_type = 4 '\004', nofault = false, data_source = false, iov_offset = 4096, {__ubuf_iovec = {
      iov_base = 0xffff88800f5bc000, iov_len = 655}, {{__iov = 0xffff88800f5bc000, kvec = 0xffff88800f5bc000,
        bvec = 0xffff88800f5bc000, folioq = 0xffff88800f5bc000, xarray = 0xffff88800f5bc000,
        ubuf = 0xffff88800f5bc000}, count = 655}}, {nr_segs = 2, folioq_slot = 2 '\002', xarray_start = 2}}

Where iov_offset is 4k with 4k-sized folios

This should have been because we're only in the 2nd slot and there's
another one after this, but iterate_folioq should not try to map a
folio that skips the whole size, and more importantly part here does
not end up zero (because 'PAGE_SIZE - skip % PAGE_SIZE' ends up
PAGE_SIZE and not zero..), so skip forward to the "advance to next
folio" code

Reported-by: Maximilian Bosch <maximilian@mbosch.me>
Reported-by: Ryan Lahfa <ryan@lahfa.xyz>
Reported-by: Christian Theune <ct@flyingcircus.io>
Reported-by: Arnout Engelen <arnout@bzzt.net>
Link: https://lkml.kernel.org/r/D4LHHUNLG79Y.12PI0X6BEHRHW@mbosch.me/
Fixes: db0aa2e9566f ("mm: Define struct folio_queue and ITER_FOLIOQ to handle a sequence of folios")
Cc: stable@vger.kernel.org # v6.12+
Acked-by: David Howells <dhowells@redhat.com>
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 include/linux/iov_iter.h | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/include/linux/iov_iter.h b/include/linux/iov_iter.h
index c4aa58032faf874ee5b29bd37f9e23c479741bef..a77ff9c7e4b21eacd166adb506b79e7ddd723aa1 100644
--- a/include/linux/iov_iter.h
+++ b/include/linux/iov_iter.h
@@ -160,7 +160,7 @@ size_t iterate_folioq(struct iov_iter *iter, size_t len, void *priv, void *priv2
 
 	do {
 		struct folio *folio = folioq_folio(folioq, slot);
-		size_t part, remain, consumed;
+		size_t part, remain = 0, consumed;
 		size_t fsize;
 		void *base;
 
@@ -168,6 +168,8 @@ size_t iterate_folioq(struct iov_iter *iter, size_t len, void *priv, void *priv2
 			break;
 
 		fsize = folioq_folio_size(folioq, slot);
+		if (skip >= fsize)
+			goto next;
 		base = kmap_local_folio(folio, skip);
 		part = umin(len, PAGE_SIZE - skip % PAGE_SIZE);
 		remain = step(base, progress, part, priv, priv2);
@@ -177,6 +179,7 @@ size_t iterate_folioq(struct iov_iter *iter, size_t len, void *priv, void *priv2
 		progress += consumed;
 		skip += consumed;
 		if (skip >= fsize) {
+next:
 			skip = 0;
 			slot++;
 			if (slot == folioq_nr_slots(folioq) && folioq->next) {

-- 
2.50.1

