From: Han Gao <gaohan@iscas.ac.cn>
Date: Sun, 22 Nov 2026 02:18:05 +0800
Subject: [PATCH v2 2/2] clk: sophgo: Keep SG2042 gates listed in
 protected-clocks enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-sg2042-efi-rtc-v2-2-6d087e03e4e8@iscas.ac.cn>
References: <20261122-b4-sg2042-efi-rtc-v2-0-6d087e03e4e8@iscas.ac.cn>
In-Reply-To: <20261122-b4-sg2042-efi-rtc-v2-0-6d087e03e4e8@iscas.ac.cn>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>, Yao Zi <me@ziyao.cc>
Cc: Chen Wang <unicorn_wang@outlook.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 sophgo@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795285099; l=1924;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=oDFY3WrZMCRM6HlTzCNBxKLTff2F/eD4wOSph6ERWQ0=;
 b=cW/iHYkr/MTWozHP2PrVACf7/yiuOa4PRHWQevLRm3LEinn1tgQtDNy8bsoT7Jma78StFPjTc
 6oWMwxABIQhDeAD/q1kY8iNJIdo+HshdQVJuWbcK0slgHLblwI70ydz
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Milk-V Pioneer, EFI runtime services use I2C0 and the serial flash,
while Linux drives other devices behind the same gates. When those
devices runtime-suspend, the gates are turned off under the firmware.

Mark gates listed in protected-clocks as critical. Unlike qcom, still
register them, since Linux devices use them too.

Suggested-by: Yao Zi <me@ziyao.cc>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sophgo/clk-sg2042-clkgen.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/sophgo/clk-sg2042-clkgen.c b/drivers/clk/sophgo/clk-sg2042-clkgen.c
index 6abc2c973c49..65ab18f701e1 100644
--- a/drivers/clk/sophgo/clk-sg2042-clkgen.c
+++ b/drivers/clk/sophgo/clk-sg2042-clkgen.c
@@ -840,6 +840,18 @@ static int sg2042_clk_register_divs(struct device *dev,
 	return ret;
 }
 
+static unsigned long sg2042_gate_flags(struct device *dev,
+				       const struct sg2042_gate_clock *gate)
+{
+	u32 id;
+
+	of_property_for_each_u32(dev->of_node, "protected-clocks", id)
+		if (id == gate->id)
+			return gate->hw.init->flags | CLK_IS_CRITICAL;
+
+	return gate->hw.init->flags;
+}
+
 static int sg2042_clk_register_gates(struct device *dev,
 				     struct sg2042_clk_data *clk_data,
 				     const struct sg2042_gate_clock gate_clks[],
@@ -858,7 +870,7 @@ static int sg2042_clk_register_gates(struct device *dev,
 			 NULL,
 			 gate->hw.init->parent_hws[0],
 			 NULL,
-			 gate->hw.init->flags,
+			 sg2042_gate_flags(dev, gate),
 			 clk_data->iobase + gate->offset_enable,
 			 gate->bit_idx,
 			 0,
@@ -900,7 +912,7 @@ static int sg2042_clk_register_gates_fw(struct device *dev,
 			(dev,
 			 gate->hw.init->name,
 			 gate->hw.init->parent_data,
-			 gate->hw.init->flags,
+			 sg2042_gate_flags(dev, gate),
 			 clk_data->iobase + gate->offset_enable,
 			 gate->bit_idx,
 			 0,

-- 
2.55.0

