From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 04:41:48 +0000
Subject: [PATCH] crypto: rockchip - Drop the runtime PM reference on DMA
 mapping errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-rk-crypto-v1-1-8fb89152fac0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIsVBWsC/yXM0QpAMBSA4VfRubayMcqryMVsB4dCZ4jk3Q2XX
 /39F3hkQg9ldAHjTp7mKUDGEdjeTB0KcsGgEpVLqTLBo7B8Luss0sLlThstU51A6BfGlo7vVdW
 //dYMaNd3APf9APANq8JtAAAA
X-Change-ID: 20261124-rk-crypto-37d6d5a51350
To: clabbe@baylibre.com, heiko@sntech.de, herbert@gondor.apana.org.au, 
 davem@davemloft.net
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-crypto@vger.kernel.org, linux-rockchip@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495308; l=1418;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=AgEW09Ja4be96HPfEZUyJHdtDhjRWUkcTv5e5vEm5VU=;
 b=z5SJG0ZYe/0QvbJ44vYq6t5KtYtYvnZ9FR9nBfe/4VDMot38yUW1Cah2mRq2R8ewl7/tCBvxf
 cFFlOCDNGk/CYbT9LKvmoQdE78WSY+9SQ7MYp4Mj+tExK4ZTiGIahjC
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

rk_cipher_run() takes a runtime PM reference with
pm_runtime_resume_and_get() at the start of every request. The normal
exit path drops it again at the theend label.

If dma_map_sg() fails, the function jumps to theend_sgs or theend_iv
and returns the error without calling pm_runtime_put_autosuspend().
Each such request leaves one usage count behind, so the device can no
longer runtime suspend.

Drop the reference on this error path too.

Found with a static analysis tool and checked by hand.

Fixes: 9dcd71c863a6 ("crypto: rockchip - Add support for RK3399")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 (W=1). I don't have the hardware.
---
 drivers/crypto/rockchip/rk3288_crypto_skcipher.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/crypto/rockchip/rk3288_crypto_skcipher.c b/drivers/crypto/rockchip/rk3288_crypto_skcipher.c
index e80f9148c012..3f285175a194 100644
--- a/drivers/crypto/rockchip/rk3288_crypto_skcipher.c
+++ b/drivers/crypto/rockchip/rk3288_crypto_skcipher.c
@@ -427,6 +427,7 @@ static int rk_cipher_run(struct crypto_engine *engine, void *async_req)
 		dma_unmap_sg(rkc->dev, sgd, 1, DMA_FROM_DEVICE);
 	}
 theend_iv:
+	pm_runtime_put_autosuspend(rkc->dev);
 	return err;
 }
 



