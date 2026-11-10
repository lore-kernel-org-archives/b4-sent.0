From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 10 Nov 2026 05:09:12 +0000
Subject: [PATCH v2] pinctrl: amlogic: a4: Allow functions without groups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-debug-info-v2-1-73ad7aa0874b@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPim8moC/22MQQ6CMBAAv0L27Bq22hI9+Q/DgZYtbCKUtEo0p
 H+3cvY4k8xskDgKJ7hWG0ReJUmYC6hDBW7s5oFR+sKgamWIaoM929eAMvuA1uri+GQaaqAES2Q
 v7312bwuPkp4hfvb3Sj/7d7MSEtamcdppffYXunXTIwziji5M0Oacv4gh8L2mAAAA
X-Change-ID: 20261106-debug-info-bb5611e36717
To: Linus Walleij <linusw@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794287355; l=2644;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=sWD7zbg1mSXOEg9K8sOVvNf5EChgrS2CCVGEpGmu0uo=;
 b=Bn+UorY0bcUbavYtuQe7WCJiVKPEGNSMK8QgR2s6loKCX7ROkp3eRi8Rgestk9kEQdi97vDnV
 gPVKPwqjHjMCFU6ZIImK8Ma4yH99sq5pnmF1eeZVaotV47oXxU4ZJuA
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow function nodes without child groups during device tree
parsing instead of returning an error.

Only count and parse nodes with the "func-" prefix as pinctrl
functions, ignoring other non-GPIO child nodes.

This allows the driver to support function nodes without
groups and avoid treating unrelated device tree nodes as
pinctrl functions.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Add debugging information for error dts and Error pinctrl config not affect normal pin work.
---
Changes in v2:
- Reserve banks nfunctions and ngroups no-zero judgement and update commit message simultaneously.
- Link to v1: https://lore.kernel.org/r/20261106-debug-info-v1-1-067c5c554f91@amlogic.com
---
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c | 23 +++++++++++++++--------
 1 file changed, 15 insertions(+), 8 deletions(-)

diff --git a/drivers/pinctrl/meson/pinctrl-amlogic-a4.c b/drivers/pinctrl/meson/pinctrl-amlogic-a4.c
index 39eb8cc7fc0d..bd12f6fa3d4d 100644
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
@@ -1166,10 +1172,11 @@ static int aml_pctl_probe_dt(struct platform_device *pdev,
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

