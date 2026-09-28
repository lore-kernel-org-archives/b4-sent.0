From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 16:06:56 +0200
Subject: [PATCH] crypto: caam/qi2 - reset the DPSECI at probe only when
 enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-caam-qi2-dpseci-reset-v1-1-042be6c05472@free.fr>
X-B4-Tracking: v=1; b=H4sIAH90umoC/x2NwQ6CMBAFf4XsmU2gIgK/YjzU9hX3INRdNCaEf
 7fxMslcZnYyqMBoqnZSfMRkXYq0dUXh4ZcZLLE4ucb1zegGTqvyO9um8E8OvuAljmM2BGGFYeP
 zeGnjcErdvUtUQlmR5PufXG/H8QOy3DuhdAAAAA==
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, 
 Sahil Malhotra <sahil.malhotra@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604419; l=1994;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=64VY4tkbF5YIprmJtGNmeGjNbSHu8M2PhnkG7m0FjNk=;
 b=CBnORxWR3872L1eaK2z5NVlQtTdwHgCmKeIvcfWveQzvlrEYka2Fl5j+x6gHK9eLxwfMa1iiL
 aqdGIkdTNQKBoNesJ+hoIHvMP10jChPM6DLySTAWTEVf6XF2i8mNMng
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the commit
  060ce5037d5f ("crypto: caam/qi2 - add support for dpseci_reset()")
probe resets every DPSECI.

On a DPSECI the MC has just created from the DPL, never enabled,
MC 10.40.x then logs for each of its queues:

  [E, qbman_rec_isr:396, QBMAN]  QBMAN recoverable event 0x1000000
  [E, dpmng_dump_rerr_fqid:1335, QBMAN]  REL_FQ (FQ[0]) has 1 messages, dumping up to 16:
  [W, DPSECI]  DPSECI ID[0]: Flush on queue 43 not confirmed

That is 16 error lines for an 8-queue DPSECI, at every boot, although
there is nothing to flush: a disabled DPSECI has no request in flight.

The reset at remove is unchanged.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/crypto/caam/caamalg_qi2.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/crypto/caam/caamalg_qi2.c b/drivers/crypto/caam/caamalg_qi2.c
index 6b47bcc16a50..6dccbd3b27a3 100644
--- a/drivers/crypto/caam/caamalg_qi2.c
+++ b/drivers/crypto/caam/caamalg_qi2.c
@@ -5041,11 +5041,22 @@ static int __cold dpaa2_dpseci_setup(struct fsl_mc_device *ls_dev)
 	dev_info(dev, "dpseci v%d.%d\n", priv->major_ver, priv->minor_ver);
 
 	if (DPSECI_VER(priv->major_ver, priv->minor_ver) > DPSECI_VER(5, 3)) {
-		err = dpseci_reset(priv->mc_io, 0, ls_dev->mc_handle);
+		int enabled;
+
+		err = dpseci_is_enabled(priv->mc_io, 0, ls_dev->mc_handle,
+					&enabled);
 		if (err) {
-			dev_err(dev, "dpseci_reset() failed\n");
+			dev_err(dev, "dpseci_is_enabled() failed\n");
 			goto err_get_vers;
 		}
+
+		if (enabled) {
+			err = dpseci_reset(priv->mc_io, 0, ls_dev->mc_handle);
+			if (err) {
+				dev_err(dev, "dpseci_reset() failed\n");
+				goto err_get_vers;
+			}
+		}
 	}
 
 	err = dpseci_get_attributes(priv->mc_io, 0, ls_dev->mc_handle,

---
base-commit: 67aefeccc4101a93627f36abbd049f191b54f903
change-id: 20260928-for-upstream-caam-qi2-dpseci-reset-5971d83f4b4f

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

