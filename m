From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 21:44:21 -0500
Subject: [PATCH] crypto: virtio - bound the device-reported akcipher result
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-27caeeac-v1-1-956e8f9c4f01@proton.me>
X-B4-Tracking: v=1; b=H4sIAARQN2oC/x3MPQqAMAxA4atIZgM1aKteRRz6k2oWlRZEKN7d4
 vgN7xXInIQzzE2BxLdkOY+Krm3A7/bYGCVUAynSSpNC12OQfCEZb5mtx8GNTptJUwwBanYljvL
 8y2V93w+3juuhYgAAAA==
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 Jason Wang <jasowang@redhat.com>, "Michael S. Tsirkin" <mst@redhat.com>, 
 Gonglei <arei.gonglei@huawei.com>
Cc: virtualization@lists.linux.dev, Xuan Zhuo <xuanzhuo@linux.alibaba.com>, 
 linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782009860; l=1847;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=K5bqL5COT6HbKY+VbfoFkNOHOfOlTVi0faKIoOEwSgo=;
 b=BDix6qItkKUTJhCborvwgWf3bRJovdNnpvoxyhH7JiTwBa1C8J+VIIlIv5YFTHks9mN5rLhSz
 Ph+K3Bc3rkkDNBygB4QMIKrummLos5aw43vCFA+9v3iHmDDaUHHOj1Z
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

length

virtio_crypto_dataq_akcipher_callback() sets the result length from the
device-reported response length without bounding it to the destination
buffer, which was allocated for the original request length.
sg_copy_from_buffer() then reads that many bytes from the destination
buffer; a backend reporting a larger length over-reads adjacent kernel
heap into the caller's scatterlist (an out-of-bounds read).

Clamp the reported length to the originally requested destination length.
A conforming device reports no more than that, so valid results are
unaffected.

Fixes: a36bd0ad9fbf ("virtio-crypto: adjust dst_len at ops callback")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/crypto/virtio/virtio_crypto_akcipher_algs.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/crypto/virtio/virtio_crypto_akcipher_algs.c b/drivers/crypto/virtio/virtio_crypto_akcipher_algs.c
index d8d452cac391..64ea141f018c 100644
--- a/drivers/crypto/virtio/virtio_crypto_akcipher_algs.c
+++ b/drivers/crypto/virtio/virtio_crypto_akcipher_algs.c
@@ -88,7 +88,8 @@ static void virtio_crypto_dataq_akcipher_callback(struct virtio_crypto_request *
 	}
 
 	/* actual length may be less than dst buffer */
-	akcipher_req->dst_len = len - sizeof(vc_req->status);
+	akcipher_req->dst_len = min_t(unsigned int, len - sizeof(vc_req->status),
+				      akcipher_req->dst_len);
 	sg_copy_from_buffer(akcipher_req->dst, sg_nents(akcipher_req->dst),
 			    vc_akcipher_req->dst_buf, akcipher_req->dst_len);
 	virtio_crypto_akcipher_finalize_req(vc_akcipher_req, akcipher_req, error);

---
base-commit: 1a3746ccbb0a97bed3c06ccde6b880013b1dddc1
change-id: 20260620-b4-disp-27caeeac-5b8b67962fdd

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

