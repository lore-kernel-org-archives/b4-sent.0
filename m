From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 19:09:36 +0800
Subject: [PATCH] power: supply: mt6360_charger: Set the input voltage limit
 in CHG_CTRL6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt6360-charger-mivr-v1-1-ae6fcfb21bb9@udp0.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMUQqDMBCE4avIPnchibBir1L6UJNRt6AtGxVBv
 HvT9vFjmP+gDFNkulYHGTbN+poL/KWiOD7mAaypmIIL4r1reFqkFsdltAHGk27GdWrRRIj0KVB
 5vg297r/q7f53Xrsn4vJN0Xl+AKY5/ox3AAAA
X-Change-ID: 20261107-mt6360-charger-mivr-3d9e7ce66fd2
To: Sebastian Reichel <sre@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 stable@vger.kernel.org, Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794049778; l=1708;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=NPOAHTLtaaexfTH0i/P9IAyN1qGjNjezFTQY55cDejE=;
 b=24QLSek8cMBjCn+fV0DFLLs5uhUl1By3RsW5vERTdOt7I/qC5khu7TXxFtXcFiRARw5suDHJZ
 uTrousjJyxYDHY0mD2B+7hQyb0GD+LofX2iDGcNVkNZDpK3LfSVyc2B
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6360_charger_set_mivr() updates the MIVR field (bits 7:1) of
CHG_CTRL3, but MIVR lives in CHG_CTRL6, where mt6360_charger_get_mivr()
reads it and MediaTek's own MT6360 charger driver writes it. CHG_CTRL3
holds the input current limit (AICR, bits 7:2) instead.

Writing input_voltage_limit therefore never changed the voltage limit
and replaced the input current limit with the MIVR selector: 4.5 V, for
example, set AICR to 250 mA.

Write the MIVR field of CHG_CTRL6.

Tested on a Redmi Note 13 5G (MT6833 with an MT6360): with this change,
writing 4.6 V to input_voltage_limit only moves CHG_CTRL6 from 0x0d to
0x0f and reads back as 4.6 V, while CHG_CTRL3 stays at 0x72 and
input_current_limit at 1.5 A.

Fixes: 0402e8ebb8b8 ("power: supply: mt6360_charger: add MT6360 charger support")
Cc: stable@vger.kernel.org
Signed-off-by: Rui Cao <i@udp0.com>
---
 drivers/power/supply/mt6360_charger.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/power/supply/mt6360_charger.c b/drivers/power/supply/mt6360_charger.c
index b4d46234315..ccd5c200629 100644
--- a/drivers/power/supply/mt6360_charger.c
+++ b/drivers/power/supply/mt6360_charger.c
@@ -414,7 +414,7 @@ static int mt6360_charger_set_mivr(struct mt6360_chg_info *mci,
 
 	linear_range_get_selector_within(&mt6360_chg_range[MT6360_RANGE_VMIVR], val->intval, &sel);
 	return regmap_update_bits(mci->regmap,
-				  MT6360_PMU_CHG_CTRL3,
+				  MT6360_PMU_CHG_CTRL6,
 				  MT6360_VMIVR_MASK,
 				  sel << MT6360_VMIVR_SHFT);
 }

---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-mt6360-charger-mivr-3d9e7ce66fd2

Best regards,
--  
Rui Cao <i@udp0.com>

