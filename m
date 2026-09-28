From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 16:01:03 +0200
Subject: [PATCH 1/3] crypto: caam/qi2 - algorithm priority be a parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-caam-qi2-priority-v1-1-e4a8e5f01dbc@free.fr>
References: <20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr>
In-Reply-To: <20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr>
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, 
 Sahil Malhotra <sahil.malhotra@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Gaurav Jain <gaurav.jain@nxp.com>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604073; l=2919;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=FoDedHHY6DKLXx6MwRuYNgLGVMx6qX1+U5vA+e03fhk=;
 b=yzcvSTiMigoIq1oKq70QRFIIrgwFLOTSdfY/dVXJysopYds6mUgsm96EyWu1P6gkd0rEiRBpx
 b2/vlf0DyEXCRNSI/o+8YvU9kMrlm7/MZVj8x9SEN5qmkanO8sqTSe9
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpaa2_caam registers every skcipher, aead and ahash at a fixed priority
of 2000.

It is above the ARMv8 Crypto Extensions (200 to 300), so on any DPAA2 SoC,
every in-kernel user of AES, SHA or GCM moves from the CPU to the SEC,
whatever the request size.

Whether the SEC should be the default or only be reached by driver name
depends on the system, and there is no way to choose/tune it.

Add a priority parameter
  dpaa2_caam.priority=
on the command line

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/crypto/caam/caamalg_qi2.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/drivers/crypto/caam/caamalg_qi2.c b/drivers/crypto/caam/caamalg_qi2.c
index 6b47bcc16a50..dbb84a6996a2 100644
--- a/drivers/crypto/caam/caamalg_qi2.c
+++ b/drivers/crypto/caam/caamalg_qi2.c
@@ -28,6 +28,13 @@
 
 #define CAAM_CRA_PRIORITY	2000
 
+static unsigned int priority;
+module_param(priority, uint, 0444);
+MODULE_PARM_DESC(priority,
+		 "Crypto API priority of the algorithms (0: default, 2000)");
+
+static int cra_priority = CAAM_CRA_PRIORITY;
+
 /* max key is sum of AES_MAX_KEY_SIZE, max split key size */
 #define CAAM_MAX_KEY_SIZE	(AES_MAX_KEY_SIZE + CTR_RFC3686_NONCE_SIZE + \
 				 SHA512_DIGEST_SIZE * 2)
@@ -3014,7 +3021,7 @@ static void caam_skcipher_alg_init(struct caam_skcipher_alg *t_alg)
 	struct skcipher_alg *alg = &t_alg->skcipher;
 
 	alg->base.cra_module = THIS_MODULE;
-	alg->base.cra_priority = CAAM_CRA_PRIORITY;
+	alg->base.cra_priority = cra_priority;
 	alg->base.cra_ctxsize = sizeof(struct caam_ctx) + crypto_dma_padding();
 	alg->base.cra_flags |= (CRYPTO_ALG_ASYNC | CRYPTO_ALG_ALLOCATES_MEMORY |
 			      CRYPTO_ALG_KERN_DRIVER_ONLY);
@@ -3028,7 +3035,7 @@ static void caam_aead_alg_init(struct caam_aead_alg *t_alg)
 	struct aead_alg *alg = &t_alg->aead;
 
 	alg->base.cra_module = THIS_MODULE;
-	alg->base.cra_priority = CAAM_CRA_PRIORITY;
+	alg->base.cra_priority = cra_priority;
 	alg->base.cra_ctxsize = sizeof(struct caam_ctx) + crypto_dma_padding();
 	alg->base.cra_flags = CRYPTO_ALG_ASYNC | CRYPTO_ALG_ALLOCATES_MEMORY |
 			      CRYPTO_ALG_KERN_DRIVER_ONLY;
@@ -4659,7 +4666,7 @@ static struct caam_hash_alg *caam_hash_alloc(struct device *dev,
 	alg->cra_init = caam_hash_cra_init;
 	alg->cra_exit = caam_hash_cra_exit;
 	alg->cra_ctxsize = sizeof(struct caam_hash_ctx) + crypto_dma_padding();
-	alg->cra_priority = CAAM_CRA_PRIORITY;
+	alg->cra_priority = cra_priority;
 	alg->cra_blocksize = template->blocksize;
 	alg->cra_alignmask = 0;
 	alg->cra_flags = CRYPTO_ALG_ASYNC | CRYPTO_ALG_ALLOCATES_MEMORY;
@@ -5208,6 +5215,9 @@ static int dpaa2_caam_probe(struct fsl_mc_device *dpseci_dev)
 
 	caam_imx = false;
 
+	if (priority)
+		cra_priority = priority;
+
 	dev = &dpseci_dev->dev;
 
 	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);

-- 
2.43.0

