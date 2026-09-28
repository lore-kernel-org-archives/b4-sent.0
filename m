From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 16:01:05 +0200
Subject: [PATCH 3/3] crypto: caam/qi2 - priority from the DTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-caam-qi2-priority-v1-3-e4a8e5f01dbc@free.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604073; l=1782;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=iq3+PxFNmYgXB61bU9JaS64+yNKmnFhKP0HR8tcxDG8=;
 b=J9qxMrWMVHlBWp4AOfdZ7RQ4U0ivmsSMx8YCLJF2ihntA1MShcyS4XdkdjDVUGWF6AEUk/7ML
 NRgRksUz4gcBgjMmJho67RJ8cmqDL6KAF4ZUgz+Z6/1/XKpkag+vVxd
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read fsl,qi2-crypto-priority from the SEC node when dpaa2_caam probes,
so the board's DTS sets the priority its algorithms register with.

The dpaa2_caam.priority parameter has precedence when it is set.
When they are not set, we keep the default behaviour.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/crypto/caam/caamalg_qi2.c | 23 +++++++++++++++++++++--
 1 file changed, 21 insertions(+), 2 deletions(-)

diff --git a/drivers/crypto/caam/caamalg_qi2.c b/drivers/crypto/caam/caamalg_qi2.c
index dbb84a6996a2..7d6a5e4ee86e 100644
--- a/drivers/crypto/caam/caamalg_qi2.c
+++ b/drivers/crypto/caam/caamalg_qi2.c
@@ -19,6 +19,7 @@
 #include <linux/dma-mapping.h>
 #include <linux/fsl/mc.h>
 #include <linux/kernel.h>
+#include <linux/of.h>
 #include <linux/string.h>
 #include <linux/string_choices.h>
 #include <soc/fsl/dpaa2-io.h>
@@ -35,6 +36,25 @@ MODULE_PARM_DESC(priority,
 
 static int cra_priority = CAAM_CRA_PRIORITY;
 
+static int dpaa2_caam_cra_priority(void)
+{
+	struct device_node *np;
+	u32 prio;
+	int err;
+
+	if (priority)
+		return priority;
+
+	np = of_find_compatible_node(NULL, NULL, "fsl,sec-v4.0");
+	if (!np)
+		return CAAM_CRA_PRIORITY;
+
+	err = of_property_read_u32(np, "fsl,qi2-crypto-priority", &prio);
+	of_node_put(np);
+
+	return err ? CAAM_CRA_PRIORITY : prio;
+}
+
 /* max key is sum of AES_MAX_KEY_SIZE, max split key size */
 #define CAAM_MAX_KEY_SIZE	(AES_MAX_KEY_SIZE + CTR_RFC3686_NONCE_SIZE + \
 				 SHA512_DIGEST_SIZE * 2)
@@ -5215,8 +5235,7 @@ static int dpaa2_caam_probe(struct fsl_mc_device *dpseci_dev)
 
 	caam_imx = false;
 
-	if (priority)
-		cra_priority = priority;
+	cra_priority = dpaa2_caam_cra_priority();
 
 	dev = &dpseci_dev->dev;
 

-- 
2.43.0

