From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 09 Nov 2026 00:42:54 +0100
Subject: [PATCH RFC] crypto: caam - never share the gcm and skcipher
 descriptors serially
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-for-upstream-caam-shdsc-share-never-v1-v1-1-65a1dd146db2@free.fr>
X-B4-Tracking: v=1; b=H4sIAP0I8WoC/x2NsQoCMRAFf+XY2oUk4im2gh9gKxYhefG2MHfsa
 hCO+3eDzcA0MysZVGB0HlZSNDGZaxe/GyhNsT7BkrtTcGH03p24zMqfxd6K+OIUO2zKljqjgis
 alJtnjOVYDnAxhz312KIo8v2P7nS7XuixbT+z/oCIfQAAAA==
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, 
 Sahil Malhotra <sahil.malhotra@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794181377; l=2652;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=GjgJFHU6i0RDErS9t9bCe4m/vvJ6D6x0VQ3z3zcG9iA=;
 b=fPogTEoHycur6tnNhWpxrxlaar2/uhPjtIH747LHL7Aord5CzukTNCgAotCO74RcK1cmyuAVH
 SAHlGW8k7vED9aFiXbxAxzF/uXFjuZzk1+4rYLGtEuSZfDd87qsEi+q
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gcm and skcipher shared descriptors were built with HDR_SHARE_SERIAL,
so the SEC runs the jobs of one key one after the other:
it leads to about 4 Gbps per key on LX2160A, whatever the number of
CPUs or queues. No hardware reason for this code has been found.

From benchmarks, when built with HDR_SHARE_NEVER, the performance
is much better and scales: for instance with one CPU, AES-128-GCM,
the gains are:
  - 325 -> 592 MB/s at 1420 B
  - 498 -> 6283 MB/s at 16 KiB

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/crypto/caam/caamalg_desc.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/crypto/caam/caamalg_desc.c b/drivers/crypto/caam/caamalg_desc.c
index 04c1105eb1f5..32d614a3431d 100644
--- a/drivers/crypto/caam/caamalg_desc.c
+++ b/drivers/crypto/caam/caamalg_desc.c
@@ -639,7 +639,7 @@ void cnstr_shdsc_gcm_encap(u32 * const desc, struct alginfo *cdata,
 	u32 *key_jump_cmd, *zero_payload_jump_cmd, *zero_assoc_jump_cmd1,
 	    *zero_assoc_jump_cmd2;
 
-	init_sh_desc(desc, HDR_SHARE_SERIAL);
+	init_sh_desc(desc, HDR_SHARE_NEVER);
 
 	/* skip key loading if they are loaded due to sharing */
 	key_jump_cmd = append_jump(desc, JUMP_JSL | JUMP_TEST_ALL |
@@ -765,7 +765,7 @@ void cnstr_shdsc_gcm_decap(u32 * const desc, struct alginfo *cdata,
 {
 	u32 *key_jump_cmd, *zero_payload_jump_cmd, *zero_assoc_jump_cmd1;
 
-	init_sh_desc(desc, HDR_SHARE_SERIAL);
+	init_sh_desc(desc, HDR_SHARE_NEVER);
 
 	/* skip key loading if they are loaded due to sharing */
 	key_jump_cmd = append_jump(desc, JUMP_JSL |
@@ -1463,7 +1463,7 @@ void cnstr_shdsc_skcipher_encap(u32 * const desc, struct alginfo *cdata,
 	bool is_chacha20 = ((cdata->algtype & OP_ALG_ALGSEL_MASK) ==
 			    OP_ALG_ALGSEL_CHACHA20);
 
-	init_sh_desc(desc, HDR_SHARE_SERIAL | HDR_SAVECTX);
+	init_sh_desc(desc, HDR_SHARE_NEVER | HDR_SAVECTX);
 	/* Skip if already shared */
 	key_jump_cmd = append_jump(desc, JUMP_JSL | JUMP_TEST_ALL |
 				   JUMP_COND_SHRD);
@@ -1539,7 +1539,7 @@ void cnstr_shdsc_skcipher_decap(u32 * const desc, struct alginfo *cdata,
 	bool is_chacha20 = ((cdata->algtype & OP_ALG_ALGSEL_MASK) ==
 			    OP_ALG_ALGSEL_CHACHA20);
 
-	init_sh_desc(desc, HDR_SHARE_SERIAL | HDR_SAVECTX);
+	init_sh_desc(desc, HDR_SHARE_NEVER | HDR_SAVECTX);
 	/* Skip if already shared */
 	key_jump_cmd = append_jump(desc, JUMP_JSL | JUMP_TEST_ALL |
 				   JUMP_COND_SHRD);

---
base-commit: 82e91fe19fb838f235f7c8829afc1eb389c93bdf
change-id: 20261108-for-upstream-caam-shdsc-share-never-v1-e6f7f5e0ad23

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

