From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 06 Nov 2026 07:08:46 +0000
Subject: [PATCH] pinctrl: amlogic: a4: Allow functions without groups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-debug-info-v1-1-067c5c554f91@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAP187WoC/x2MQQqAIBAAvyJ7bkGNFPpKdMhcbS8aShGEf086z
 sDMC5UKU4VZvFDo5so5dVCDgP3YUiRk3xm01EYpadCTuyJyChmdm7qj0VhloQdnocDPP1vW1j7
 7Vr3yXAAAAA==
X-Change-ID: 20261106-debug-info-bb5611e36717
To: Linus Walleij <linusw@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793948933; l=2986;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=38GizBhLDTW4i/GAT4DbimPes3s2Ei64bmXiM44p6dM=;
 b=Zp2hrVUInW3tmySD+qP23c2GiuMu7cuWGPE7KpTaGQtXN3rnWgNGaDXPPlqLObAPZOi7+XzRa
 Me9xUYBVdZ5BwnG79tTvNzKV6JE2Az0cijnFmwxSoHYLJFkY+nj7+s7
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow function nodes without child groups during device tree
parsing instead of returning an error.

Only count and parse nodes with the "func-" prefix as pinctrl
functions, ignoring other non-GPIO child nodes.

Also handle zero-sized allocations when no groups are defined
by checking for ZERO_SIZE_PTR in addition to NULL.

This allows the driver to support function nodes without
groups and avoid treating unrelated device tree nodes as
pinctrl functions.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Add debugging information for error dts and Error pinctrl config not affect normal pin work.
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 26 +++++++++++++++++---------
 1 file changed, 17 insertions(+), 9 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index 39eb8cc7fc0d..d0e3cec3ead0 100644
--- a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
+++ b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
@@ -821,8 +821,10 @@ static int aml_pctl_parse_functions(struct device_node *np,
 	func = &info->functions[index];
 	func->name = np->name;
 	func->ngroups = of_get_child_count(np);
-	if (func->ngroups == 0)
-		return dev_err_probe(dev, -EINVAL, "No groups defined\n");
+	if (func->ngroups == 0) {
+		dev_dbg(dev, "func %s No groups defined\n", func->name);
+		return  0;
+	}
 
 	func->groups = devm_kcalloc(dev, func->ngroups, sizeof(*func->groups), GFP_KERNEL);
 	if (!func->groups)
@@ -899,8 +901,12 @@ static void aml_pctl_dt_child_count(struct aml_pinctrl *info,
 		if (of_property_read_bool(child, "gpio-controller")) {
 			info->nbanks++;
 		} else {
-			info->nfunctions++;
-			info->ngroups += of_get_child_count(child);
+			if (!strncmp(child->name, "func-", 5)) {
+				info->nfunctions++;
+				info->ngroups += of_get_child_count(child);
+			} else {
+				dev_dbg(info->dev, "func node defined err %s\n", child->name);
+			}
 		}
 	}
 }
@@ -1128,7 +1134,8 @@ static int aml_pctl_probe_dt(struct platform_device *pdev,
 
 	info->banks = devm_kcalloc(dev, info->nbanks, sizeof(*info->banks), GFP_KERNEL);
 
-	if (!info->functions || !info->groups || !info->banks)
+	if (IS_ERR_OR_NULL(info->functions) || IS_ERR_OR_NULL(info->groups) ||
+	    IS_ERR_OR_NULL(info->banks))
 		return -ENOMEM;
 
 	info->data = (struct aml_pctl_data *)of_device_get_match_data(dev);
@@ -1166,10 +1173,11 @@ static int aml_pctl_probe_dt(struct platform_device *pdev,
 			}
 			bank++;
 		} else {
-			ret = aml_pctl_parse_functions(child, info,
-						       i++, &grp_index);
-			if (ret)
-				return ret;
+			if (!strncmp(child->name, "func-", 5)) {
+				ret = aml_pctl_parse_functions(child, info, i++, &grp_index);
+				if (ret)
+					return ret;
+			}
 		}
 	}
 

---
base-commit: 89edcad9f23925f5706b7555b02165d1990444d5
change-id: 20261106-debug-info-bb5611e36717

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

