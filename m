From: Han Gao <gaohan@iscas.ac.cn>
Date: Thu, 26 Nov 2026 21:41:10 +0800
Subject: [PATCH v2 2/4] pinctrl: sunxi: allow a per-controller IRQ register
 base
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-v861-pinctrl-v2-2-b1875a6a9bb8@iscas.ac.cn>
References: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
In-Reply-To: <20261126-v861-pinctrl-v2-0-b1875a6a9bb8@iscas.ac.cn>
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700469; l=1288;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=Q5nKbDPfL5bIJRudVipL8eRl+Sf6kVk4l+UGPGRoSrU=;
 b=8bZrCJohIh2gijQZl5H/Bqifftn/CgDJZCWiItvlJ6fD++qTp1yNnJuu9gKmZM4Po7X7gSChf
 QUbH1OPmz67DXaaIWmoEV2DaP86qvQgW70/yaCqb4O89WFVlcHlrMCP
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The V861 always-on pin controller has its interrupt registers at 0x40
instead of 0x200. Let the descriptor override the base.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/pinctrl/sunxi/pinctrl-sunxi.h | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/pinctrl/sunxi/pinctrl-sunxi.h b/drivers/pinctrl/sunxi/pinctrl-sunxi.h
index 7c2f29e75519..a0f5eac5c914 100644
--- a/drivers/pinctrl/sunxi/pinctrl-sunxi.h
+++ b/drivers/pinctrl/sunxi/pinctrl-sunxi.h
@@ -152,6 +152,11 @@ struct sunxi_pinctrl_desc {
 	unsigned			pin_base;
 	unsigned			irq_banks;
 	const unsigned int		*irq_bank_map;
+	/*
+	 * Interrupt register base, where zero selects the traditional 0x200.
+	 * Not used with the NCAT3 register layout.
+	 */
+	u32				irq_reg_base;
 	bool				irq_read_needs_mux;
 	bool				disable_strict_mode;
 	enum sunxi_desc_bias_voltage	io_bias_cfg_variant;
@@ -261,7 +266,7 @@ static inline u32 sunxi_irq_base_reg(const struct sunxi_pinctrl *pctl, u16 bank)
 		return pctl->bank_offset + bank * pctl->bank_mem_size +
 		       A733_IRQ_REGS_OFFSET;
 
-	return IRQ_REGS_OFFSET +
+	return (pctl->desc->irq_reg_base ?: IRQ_REGS_OFFSET) +
 	       sunxi_irq_hw_bank_num(pctl->desc, bank) * IRQ_MEM_SIZE;
 }
 

-- 
2.55.0

