From: Michael Lowman <michael.d.lowman@gmail.com>
Date: Thu, 22 Oct 2026 15:10:26 +0200
Subject: [PATCH] SUNRPC: avoid possible page reuse from
 svcauth_gss_wrap_integ()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-integ-page-reuse-v1-1-fbe571857d4f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMBCE4VeRPRvYpNgWX0U8xDi120OUrEpBf
 HejHj+G+TdSJIFSXWyUsIrKGDNsWVD4+jjASJ9Njt3Tsn0ZiTMGM/m8JCwKwz1XD7w7Dt5Rvk0
 JH/lfyaa9rUv3Q5jPDu37ARxRp2p0AAAA
X-Change-ID: 20261017-integ-page-reuse-0d053e8b0ca2
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-nfs@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Michael Lowman <michael.d.lowman@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2485;
 i=michael.d.lowman@gmail.com; h=from:subject:message-id;
 bh=J5FcyzJj5w1NI+B2kzsCRu8psxQMF7yI9ZjgbLBQU78=;
 b=owEBiQF2/pANAwAKAbhUyZi0A3mzAcsmYgBq2gtMggRxlwYUWnxU0m3X2axlVUp3BHI1AbrpI
 CcRqyeIECWJAU8EAAEKADkWIQR42JpeMFqVv37vF7e4VMmYtAN5swUCatoLTBscbWljaGFlbC5k
 Lmxvd21hbkBnbWFpbC5jb20ACgkQuFTJmLQDebPbwwgAqbu3jYLWuD/72zzMOa2jnbH02bFL5v2
 x5MGr66dgVYycOiwAqRtQ40b7GIctSGkOQsQlDTPxbpNMbvd0YpRrWE1/mgVSeG7eF+93WUmqYH
 lNT8PRqcoR2hcnWAKTEA0mdEhPgVDrB/zUPV2qBn6wHN81SyXukJyWF/EdJxSYKVBZ0pnOOT0ht
 tl8z/laCrVntlhgebqoG7aZK/OoLOzYuRfcMJlfJtDgl4aGEu0SRs1oB5YtZHj0c5RjfutDwSeA
 draF82Tm0QhuLM58HX9+u3bMzhV6F4nfzr/9+zsGoWqgMEnrLqaJ6n6mIjA9s3I2/We4sqlnw82
 2Gpamr6wdzQ==
X-Developer-Key: i=michael.d.lowman@gmail.com; a=openpgp;
 fpr=6E281440251F4A47DCA99700FD4D12FE546354BA
X-Endpoint-Received: by B4 Relay for michael.d.lowman@gmail.com/default with auth_id=1283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 7702378ac4d4 ("SUNRPC: Convert svcauth_gss_wrap_integ() to
use xdr_stream()") and its parent changed from calculating the
integrity checksum in-place in an unused part of the response buffer
to calculating in a scratch buffer and appending it to the response
stream. While the unused part of the response buffer happened to
always end on the first page, the append always occurs on the last.

If less than 32 bytes remain before the page boundary, some or all
of the checksum will be written to the next page. But since the xdr
functions do not update the response's page accounting, the page
will be immediately available for reuse. Data from another request
will overwrite the portion of the checksum on the new page.

Avoid this by marking the page as used when needed.

Signed-off-by: Michael Lowman <michael.d.lowman@gmail.com>
Fixes: 7702378ac4d4 ("SUNRPC: Convert svcauth_gss_wrap_integ() to use xdr_stream()")
---
When running several reads in parallel from an NFSv4 mount using
sec=krb5i, I find that the checksum is often invalid; of ten 64k
reads of ten different files launched in parallel, usually eight fail.
I observed that this did not occur when using sec=krb5p, and that
part of the checksum appeared to be overwritten with valid data
from other packets. After building with the attached change, I
no longer experience read failures.
---
 net/sunrpc/auth_gss/svcauth_gss.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/net/sunrpc/auth_gss/svcauth_gss.c b/net/sunrpc/auth_gss/svcauth_gss.c
index 43839e805531..4219cfb2e88a 100644
--- a/net/sunrpc/auth_gss/svcauth_gss.c
+++ b/net/sunrpc/auth_gss/svcauth_gss.c
@@ -1835,6 +1835,17 @@ static int svcauth_gss_wrap_integ(struct svc_rqst *rqstp)
 		goto wrap_failed;
 	xdr_commit_encode(xdr);
 
+	/**
+	 * While the data protocol normally accounts for pages
+	 * used in the encode of the operation, the checksum is
+	 * written by the above xdr_stream_encode_opaque and can therefore
+	 * end up in the next page.
+	 * Update the request's bookkeeping to avoid reusing the page for the
+	 * next request while it's still referenced by this one.
+	 */
+	if (xdr->page_ptr + 1 > rqstp->rq_next_page)
+		rqstp->rq_next_page = xdr->page_ptr + 1;
+
 out:
 	return 0;
 

---
base-commit: eafb6de800781f0a1be5cdd98d150620041d8b27
change-id: 20261017-integ-page-reuse-0d053e8b0ca2

Best regards,
--  
Michael Lowman <michael.d.lowman@gmail.com>

