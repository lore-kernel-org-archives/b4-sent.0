From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 01:52:15 -0500
Subject: [PATCH v2] crypto: virtio - bound the akcipher result length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-3a2c09a8-v2-1-d1a809281db4@proton.me>
X-B4-Tracking: v=1; b=H4sIAJ7bOGoC/x3MQQqAIBBA0avErBuQsaS6SrQwHWs2FgoRiHdPW
 r7F/wUyJ+EMS1cg8SNZrthAfQfutPFgFN8MpMgoQ4T7gF7yjdqSU7OdcLS7Ys06ONLQsjtxkPd
 frlutH7isHnxiAAAA
To: "Michael S. Tsirkin" <mst@redhat.com>, 
 Gonglei <arei.gonglei@huawei.com>, Jason Wang <jasowang@redhat.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>
Cc: linux-kernel@vger.kernel.org, virtualization@lists.linux.dev, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 linux-crypto@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782111134; l=2094;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=/OPWzrjXfFujjZLqunAHnLbL2LVmSG6t3fb7rk8J+BI=;
 b=oq9Ln5r7vfpEZgRRYFw+5fqFQ0KvggRq+d57Orp3STFjRptIBmAxk6A/ugfhFiKcn7hU+9kf7
 YQk10pUNBgHDnVNuvNgQLg/4jqgbJ/WUb1uX8sPb1ndr5xJFBtVYxUC
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
v2: Fix the Subject line, mangled in v1 - an over-long subject was wrapped
    and its trailing word leaked into the commit body. No functional change.

Link to v1: https://lore.kernel.org/all/20260620-b4-disp-27caeeac-v1-1-956e8f9c4f01@proton.me/
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
change-id: 20260622-b4-disp-3a2c09a8-5ab0e3e3fc23

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

