From: Jia Wang <wangjia@ultrarisc.com>
Date: Mon, 20 Jul 2026 08:38:04 +0800
Subject: [PATCH v4 1/3] clk: composite: Export devm composite pdata helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-ultrarisc-clock-v4-1-fe639d63bbac@ultrarisc.com>
References: <20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com>
In-Reply-To: <20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784507902; l=845;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=mmNYdl//tm5jVxgVHLR5oIpB4MdMweBH1Jbb6olZW8U=;
 b=805WxaH5WTkCWtyOv0d+xqNS/6rgmIa8Pn5/DAoxqF9NAsDUOIPyvRF9xHW2+peiVPbQJ2D1w
 qMDlpUBydL9C8j0gfz5Lx38X/NsQDpMsAZjsoxjjFweorLTWUEW1IH6
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow modular clock drivers to use
devm_clk_hw_register_composite_pdata() by exporting the helper.

The non-devm composite helpers are already available to modules. Export
this devm variant as well so users do not need to open-code devres
cleanup.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Reviewed-by: Brian Masney <bmasney@redhat.com>
---
 drivers/clk/clk-composite.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/clk/clk-composite.c b/drivers/clk/clk-composite.c
index 835b1e4e5869..11842bce5918 100644
--- a/drivers/clk/clk-composite.c
+++ b/drivers/clk/clk-composite.c
@@ -462,3 +462,4 @@ struct clk_hw *devm_clk_hw_register_composite_pdata(struct device *dev,
 						rate_hw, rate_ops, gate_hw,
 						gate_ops, flags);
 }
+EXPORT_SYMBOL_GPL(devm_clk_hw_register_composite_pdata);

-- 
2.34.1

