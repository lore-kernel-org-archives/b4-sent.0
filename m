From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sat, 12 Sep 2026 01:11:14 -0700
Subject: [PATCH] crypto: af_alg/hash: Report errors that discard hash state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-afalg-b4-send-20260912-v1-1-c6cf966d3f1a@gmail.com>
X-B4-Tracking: v=1; b=H4sIACEJpWoC/z2MQQrCMBBFr1Jm7UASaqFeRVzMpJM2IlEyVoTSu
 5vY6vI9/n8LqOQoCqdmgSyvqPGeCthDA36iNArGoTA44zrTW4cU6DYit6iSBvzrzvVi2hAMHy2
 U8yNLiO9v+HzZWGe+in/WWl0wqSBnSn6qau9W+YvCun4A8eM/HKAAAAA=
X-Change-ID: 20260912-afalg-b4-send-20260912-629e04ff0b51
To: "David S. Miller" <davem@davemloft.net>, 
 Herbert Xu <herbert@gondor.apana.org.au>
Cc: David Howells <dhowells@redhat.com>, Paolo Abeni <pabeni@redhat.com>, 
 linux-kernel@vger.kernel.org, linux-crypto@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789200677; l=1532;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=UF6Le/jUVT/fxnhJHG6G7FxL9hFdSTl92xjIHL6gpDk=;
 b=uf6R7cz671hAJYDC58+wvlpj5pkJe6Xs9n1KM/a+eJopY7h8DSPxJLdsqFekaSixNU/zxy323
 E4hEbOZj1jeCXZBK8fLkhBvgsdInnhReOqjyka5gwHuC7ih44pvcFnS
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hash_sendmsg() processes large requests in several batches.  If a later
batch fails, the common error path calls hash_free_result() and clears
ctx->more.  The next operation therefore starts a new hash request.

The function nevertheless returns the number of bytes processed by earlier
batches.  With failslab, a 262144-byte SHA-1 send without MSG_MORE returns
262128 when the result allocation fails.  A digest read then returns the
digest of an empty input.  Retrying the last 16 bytes instead returns the
digest of only those 16 bytes.

Return the error whenever the request state is discarded.  This also
restores the error-first behavior used before the request batching code was
reworked.

Fixes: c662b043cdca ("crypto: af_alg/hash: Support MSG_SPLICE_PAGES")
Cc: stable@vger.kernel.org
Assisted-by: Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 crypto/algif_hash.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/crypto/algif_hash.c b/crypto/algif_hash.c
index 6e8b5fb82a7f1..7c1910c370ad6 100644
--- a/crypto/algif_hash.c
+++ b/crypto/algif_hash.c
@@ -184,7 +184,7 @@ static int hash_sendmsg(struct socket *sock, struct msghdr *msg,
 	err = 0;
 unlock:
 	release_sock(sk);
-	return copied ?: err;
+	return err ?: copied;
 
 unlock_free:
 	af_alg_free_sg(&ctx->sgl);

---
base-commit: 5225b8eec4c9bb21aecff6295fab6346a3c3738e
change-id: 20260912-afalg-b4-send-20260912-629e04ff0b51

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

