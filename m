From: Vincent Jardin <vjardin@free.fr>
Subject: [PATCH 0/3] crypto: caam/qi2 - algorithm priority configurable
Date: Mon, 28 Sep 2026 16:01:02 +0200
Message-Id: <20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB5zumoC/x2Nyw5AMBAAf0X2bJOqpB6/Ig7FYg+0tggR/65xm
 WQuMw8EEqYAdfKA0MmB3RolSxPoZ7tOhDxEB620UZUucXSChw+7kF2wtxEba/TCTni/sTC5yrq
 SutwaiBEvNPL1D5r2fT8//3uZcAAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604073; l=1011;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=XYrNlKJfrj2ruygfi45wHsY8oQRCp3XANErbO8AegLA=;
 b=SdkmtfGZjjyyX3oa2lSJEBtFOAmanXuPOAaDp1mtzN1RuMUa+Y52jJu05K55rB8zeuLMLG36R
 eRyBKiGjGwnBrpEwXp7KE9npVKRbFJnvsBrIOWJ+3VOJmvS3LRsHF61
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dpaa2_caam registers its skcipher, aead and ahash algorithms at a fixed
priority above the ARMv8 Crypto Extensions, so on DPAA2 SoCs
every in-kernel consumers of AES, SHA or GCM use the SEC.

Patch 1 adds dpaa2_caam.priority module parameter
Patch 2 doc fsl,qi2-crypto-priority property on the SEC node
Patch 3 reads it at probe, the module parameter takes precedence

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Vincent Jardin (3):
      crypto: caam/qi2 - algorithm priority be a parameter
      dt-bindings: crypto: fsl,sec-v4.0: add fsl,qi2-crypto-priority
      crypto: caam/qi2 - priority from the DTS

 .../devicetree/bindings/crypto/fsl,sec-v4.0.yaml   |  9 ++++++
 drivers/crypto/caam/caamalg_qi2.c                  | 35 ++++++++++++++++++++--
 2 files changed, 41 insertions(+), 3 deletions(-)
---
base-commit: 67aefeccc4101a93627f36abbd049f191b54f903
change-id: 20260928-for-upstream-caam-qi2-priority-76301b8eb3a6

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

