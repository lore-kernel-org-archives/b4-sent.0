From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org
Cc: lgirdwood@gmail.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH] regulator: mt6358: fix MT6366 VDRAM2 vosel_mask
Date: Wed, 25 Nov 2026 23:48:22 +0000
Message-Id: <20261125234822.94684-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795650502; l=1559;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=NR5lTAGqEZZZ+e0evyu7yj4VBUXqt2FNsTxclnP6kJ8=;
 b=U30rDd2xT5dzziJ5z1nFS+q2oq2JPjQNp/vgG3PCxQ8HRFoChmiCTmCUY5fbDqPXvN9a1EY65
 vOV0au3HUU4ArN+3oNOWH3Xs7QsTAftTpHXQWWemy0OL/6BJ8GVJStW
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6366_regulators[] declares VDRAM2 with vosel_mask = 0x10 (a single
bit, bit 4) on MT6358_LDO_VDRAM2_ELR0, even though vdram2_selectors[]
uses values { 0, 12 } (0x0 and 0xc) which live in bits 3:0.

MT6358 in the same file (mt6358_regulators[]) and MediaTek's downstream
MT6358/MT6366 regulator driver both use vosel_mask = 0xf on
MT6358_LDO_VDRAM2_ELR0.

Change MT6366 VDRAM2 vosel_mask from 0x10 to 0xf.

Found and drafted with an AI coding assistant while auditing MT6366.

Fixes: f0e3c6261af1 ("regulator: mt6366: Add support for MT6366 regulator")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/regulator/mt6358-regulator.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/regulator/mt6358-regulator.c b/drivers/regulator/mt6358-regulator.c
index d6a0ec4..1d62c25 100644
--- a/drivers/regulator/mt6358-regulator.c
+++ b/drivers/regulator/mt6358-regulator.c
@@ -604,7 +604,7 @@ static const struct mt6358_regulator_info mt6366_regulators[] = {
 	MT6366_REG_FIXED("vrf18", VRF18, "vs1-ldo1", MT6358_LDO_VRF18_CON0, 0, 1800000),
 	MT6366_REG_FIXED("vaud28", VAUD28, "vsys-ldo1", MT6358_LDO_VAUD28_CON0, 0, 2800000),
 	MT6366_LDO("vdram2", VDRAM2, vdram2, "vs2-ldo1",
-		   MT6358_LDO_VDRAM2_CON0, 0, MT6358_LDO_VDRAM2_ELR0, 0x10),
+		   MT6358_LDO_VDRAM2_CON0, 0, MT6358_LDO_VDRAM2_ELR0, 0xf),
 	MT6366_LDO("vsim1", VSIM1, vsim, "vsys-ldo1",
 		   MT6358_LDO_VSIM1_CON0, 0, MT6358_VSIM1_ANA_CON0, 0xf00),
 	MT6366_LDO("vibr", VIBR, vibr, "vsys-ldo3",
-- 
2.54.0 (Apple Git-157)


