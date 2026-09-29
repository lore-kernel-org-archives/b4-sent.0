From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 29 Sep 2026 22:29:04 +0200
Subject: [PATCH v2] crypto: caam/qi2 - lower the algorithm priority
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-for-upstream-caam-qi2-priority-v2-1-bf0559ebf574@free.fr>
X-B4-Tracking: v=1; b=H4sIAI8fvGoC/42NQQ6CMBBFr0Jm7Zi2KKIr72FYtGUqs5DCFImEc
 HcrJ3Dzk/cX762QSJgS3IoVhGZOHPsM5lCA72z/JOQ2MxhlKnU1NYYo+B7SJGRf6G2ekQ0OwlF
 4WvBSlUq7mlxpK8iSQSjwZw88mswdpynKsvdm/Xv/Vs8aFdLJ1nQOSrfO34MQHYNAs23bF5JcH
 UTKAAAA
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, 
 Sahil Malhotra <sahil.malhotra@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Gaurav Jain <gaurav.jain@nxp.com>
Cc: Eric Biggers <ebiggers@kernel.org>, linux-crypto@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790713748; l=1690;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=v2jbJT9sn3iczfB+b+TBO4PuJmCjQ6+uYBnlDjvWIVA=;
 b=oJ93oGUfFGXWLM3SIPI1o1aNpDaGvy2MEtcxuQjfNTM5ZgAl1XZzlfffYVvkcEzLnkVAIMBiH
 JWlG4FVetQMBDmsw/NCUXgxtFhAeIdaaD+X6QMQ22MbKz2Cupo9C1kr
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Lower the priority to 100, as done for QAT in commit
  8024774190a5 ("crypto: qat - lower priority for skcipher and aead algorithms").

The SEC stays reachable by driver name, and user space can raise its
priority through the crypto_user interface.

Suggested-by: Herbert Xu <herbert@gondor.apana.org.au>
Link: https://lore.kernel.org/r/aruvJECCDNdguMdw@gondor.apana.org.au
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
v2 lowers the priority to 100, as was done for QAT, and leaves the
choice to user space through crypto_user.
---
Changes in v2:
- Drop both the dpaa2_caam.priority module parameter and the
  fsl,qi2-crypto-priority DT property
- Lower the default priority to 100, user space adjust it with
  crypto_user (Herbert).
- No policy in the device tree (Krzysztof, Eric).
- Link to v1: https://lore.kernel.org/r/20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr
---
 drivers/crypto/caam/caamalg_qi2.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/crypto/caam/caamalg_qi2.c b/drivers/crypto/caam/caamalg_qi2.c
index 6b47bcc16a50..d3cb2bd5c41d 100644
--- a/drivers/crypto/caam/caamalg_qi2.c
+++ b/drivers/crypto/caam/caamalg_qi2.c
@@ -26,7 +26,7 @@
 #include <crypto/xts.h>
 #include <linux/unaligned.h>
 
-#define CAAM_CRA_PRIORITY	2000
+#define CAAM_CRA_PRIORITY	100
 
 /* max key is sum of AES_MAX_KEY_SIZE, max split key size */
 #define CAAM_MAX_KEY_SIZE	(AES_MAX_KEY_SIZE + CTR_RFC3686_NONCE_SIZE + \

---
base-commit: 67aefeccc4101a93627f36abbd049f191b54f903
change-id: 20260928-for-upstream-caam-qi2-priority-76301b8eb3a6

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

