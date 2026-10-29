From: Jian Hu <jian.hu@amlogic.com>
Date: Thu, 29 Oct 2026 17:30:53 +0800
Subject: [PATCH RFC RFT v2 2/3] clk: divider: add CLK_DIVIDER_INVALID_ZERO
 flag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-meson_refactor_n-v2-2-ff4ac74e527b@amlogic.com>
References: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
In-Reply-To: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266267; l=2646;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=erjQIBkjDA84dTVLTzuE89941kvEx6V1M15mAHbEPe8=;
 b=M75Y/COMa5W9P7iRc1XOwuaQfgaKCQJcQkJtXFEVpP2ZItZa3Z3j5x4GpxtgBUsuhYOXxfLUk
 EUICoiNiwyoD68vezXaTQdTyxvh7+B/yg7YLCsnpmyKeXtnwg69fDeW
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a divider register reads zero, divider_recalc_rate() currently
emits a warning (unless CLK_DIVIDER_ALLOW_ZERO is set) and returns
the parent rate.

This behaviour assumes a zero divisor acts as a pass-through, which
does not apply to all hardware. Some dividers, for example PLL
pre-dividers on Amlogic SoCs, come out of reset with a zero value
that does not produce a usable clock. Returning the parent rate
hides this fault behind an incorrect, plausible value.

CLK_DIVIDER_ALLOW_ZERO only suppresses the warning while still
reporting the parent rate, so it cannot represent this hardware
behaviour.

Add CLK_DIVIDER_INVALID_ZERO for dividers where a zero divisor value
is invalid. When this flag is set, recalc_rate() returns 0, making
the faulty state visible to the clock framework rather than hiding it
as a pass-through.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/clk-divider.c    | 3 +++
 include/linux/clk-provider.h | 6 ++++++
 2 files changed, 9 insertions(+)

diff --git a/drivers/clk/clk-divider.c b/drivers/clk/clk-divider.c
index f68216c65d3d..6c1523d22477 100644
--- a/drivers/clk/clk-divider.c
+++ b/drivers/clk/clk-divider.c
@@ -143,6 +143,9 @@ unsigned long divider_recalc_rate(struct clk_hw *hw, unsigned long parent_rate,
 
 	div = _get_div(table, val, flags, width);
 	if (!div) {
+		if (flags & CLK_DIVIDER_INVALID_ZERO)
+			return 0;
+
 		WARN(!(flags & CLK_DIVIDER_ALLOW_ZERO),
 			"%s: Zero divisor and CLK_DIVIDER_ALLOW_ZERO not set\n",
 			clk_hw_get_name(hw));
diff --git a/include/linux/clk-provider.h b/include/linux/clk-provider.h
index dc8e161f9c2c..fe2dbbba49e3 100644
--- a/include/linux/clk-provider.h
+++ b/include/linux/clk-provider.h
@@ -744,6 +744,11 @@ struct clk_div_table {
  *	big endian.
  * CLK_DIVIDER_EVEN_INTEGERS - clock divisor is 2, 4, 6, 8, 10, etc.
  *	Formula is 2 * (value read from hardware + 1).
+ * CLK_DIVIDER_INVALID_ZERO - a zero value read from the register is not a
+ *	divide by one / bypass but an invalid setting which does not produce
+ *	a usable clock.  recalc_rate() returns 0 so that the broken state is
+ *	reported to the framework instead of the parent rate, without
+ *	triggering the CLK_DIVIDER_ALLOW_ZERO warning.
  */
 struct clk_divider {
 	struct clk_hw	hw;
@@ -767,6 +772,7 @@ struct clk_divider {
 #define CLK_DIVIDER_MAX_AT_ZERO		BIT(6)
 #define CLK_DIVIDER_BIG_ENDIAN		BIT(7)
 #define CLK_DIVIDER_EVEN_INTEGERS	BIT(8)
+#define CLK_DIVIDER_INVALID_ZERO	BIT(9)
 
 extern const struct clk_ops clk_divider_ops;
 extern const struct clk_ops clk_divider_ro_ops;

-- 
2.47.1

