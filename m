From: Chuan Liu <chuan.liu@amlogic.com>
Date: Thu, 31 Jul 2025 20:39:58 +0800
Subject: [PATCH] clk: Add fault tolerance to of_clk_hw_onecell_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-add_fault_tolerance_to_of_clk_hw_onecell_get-v1-1-886214fab4a7@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAB1ki2gC/x2NQQrDIBQFrxL+uoJJkJRepZSP6PuJVLSoaQshd
 690N7OZOaiiBFS6DQcVvEMNOXUZLwO5zaYVKvjuNOnJ6GXWynrPYvfYuOWIYpNDJ87CLj55+3B
 OcIiRVzQl3l1HWTAba6gnXwUSvv/d/XGeP9e3QhR+AAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753965607; l=2309;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=k/ApzTLmVZinx72j2hoSqfkFYHo5DCBt6wQQxOx8J2g=;
 b=xf705Yot6owGRVQJbr/b5M1+yj9w2q+3qLYSJ/YZz+PAkv/dBXTlVCSlJvwTUlDkjrmhCH3xq
 V3mhB4EzHMSByuN/kPatFCkLlWjE2hVjazB4QKFWVvZKmaX+/Uic4Cm
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In specific cases, even a clk_provider managing only a single clock may
reference of_clk_hw_onecell_get() to access its member clocks, as seen
in implementations like clk-scmi.

For a clk_provider with only one clock, when calling
of_parse_phandle_with_args(), the phandle_args->args[] members are not
assigned. In this case, the reference to phandle_args->args[0] in
of_clk_hw_onecell_get() becomes invalid. If phandle_args->args[0]
initially contains a non-zero value, this will trigger an error.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Error conditions observed:

scmi_clk: protocol@14 {
	reg = <0x14>;
	#clock-cells = <0>;
};

phandle1: clock-controller@1 {
	#clock-cells = <1>;
}

clock-consumer@2 {
	assigned-clocks = <&phandle1 1>,
			  <&scmi_clk>;
	assigned-clock-rates = <xxx>,
			       <xxx>;
}

Under these conditions, executing of_clk_set_defaults() triggers the
error: 'of_clk_hw_onecell_get: invalid index 1'.

While the root cause lies in invalid input data to
of_clk_hw_onecell_get(), checking phandle->args_count for data validity
improves driver fault tolerance.
---
 drivers/clk/clk.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 0565c87656cf..4994c551befe 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -4966,7 +4966,7 @@ EXPORT_SYMBOL_GPL(of_clk_hw_simple_get);
 struct clk *of_clk_src_onecell_get(struct of_phandle_args *clkspec, void *data)
 {
 	struct clk_onecell_data *clk_data = data;
-	unsigned int idx = clkspec->args[0];
+	unsigned int idx = clkspec->args_count ? clkspec->args[0] : 0;
 
 	if (idx >= clk_data->clk_num) {
 		pr_err("%s: invalid clock index %u\n", __func__, idx);
@@ -4981,7 +4981,7 @@ struct clk_hw *
 of_clk_hw_onecell_get(struct of_phandle_args *clkspec, void *data)
 {
 	struct clk_hw_onecell_data *hw_data = data;
-	unsigned int idx = clkspec->args[0];
+	unsigned int idx = clkspec->args_count ? clkspec->args[0] : 0;
 
 	if (idx >= hw_data->num) {
 		pr_err("%s: invalid index %u\n", __func__, idx);

---
base-commit: 58abdca0eb653c1a2e755ba9ba406ee475d87636
change-id: 20250730-add_fault_tolerance_to_of_clk_hw_onecell_get-fdc81f7e35a5

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

