From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 30 Oct 2025 07:35:38 +0100
Subject: [PATCH v3 2/6] regulator: bd718x7: Fix voltages scaled by resistor
 divider
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-mini_iv-v3-2-ef56c4d9f219@gocontroll.com>
References: <20251030-mini_iv-v3-0-ef56c4d9f219@gocontroll.com>
In-Reply-To: <20251030-mini_iv-v3-0-ef56c4d9f219@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Matti Vaittinen <mazziesaccount@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761806140; l=1067;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=tuKfLXiuKVJmrScuYv67N/GxQOk6XTz9dS5/tFi0lBM=;
 b=+LGPkSfwqhDloJj9Elfn+cdPBbg26FW8C9k93ZFY/maawtjxrITscXXTDy/sYrW8WQEidINh6
 og24Myhv3XcBXsfy2nYWUcViUf3olUdKJT++KiSSb2QQfevkFwSju0E
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The .min_sel and .max_sel fields remained uninitialized in the new
linear_range, causing an error further down the line. Copy the old
values of these fields to the new one as they represent the range of
register values, which does not change.

Fixes: d2ad981151b3a ("regulator: bd718x7: Support external connection to scale voltages")
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 drivers/regulator/bd718x7-regulator.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/regulator/bd718x7-regulator.c b/drivers/regulator/bd718x7-regulator.c
index 022d98f3c32a2..ea9c4058ee6a5 100644
--- a/drivers/regulator/bd718x7-regulator.c
+++ b/drivers/regulator/bd718x7-regulator.c
@@ -1613,6 +1613,8 @@ static int setup_feedback_loop(struct device *dev, struct device_node *np,
 				step /= r1;
 
 				new[j].min = min;
+				new[j].min_sel = desc->linear_ranges[j].min_sel;
+				new[j].max_sel = desc->linear_ranges[j].max_sel;
 				new[j].step = step;
 
 				dev_dbg(dev, "%s: old range min %d, step %d\n",

-- 
2.51.2

