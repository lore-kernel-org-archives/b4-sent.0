From: Larisa Grigore <larisa.grigore@oss.nxp.com>
Date: Sat, 14 Nov 2026 12:55:43 +0100
Subject: [PATCH v11 11/14] ufs: pltfrm: Add a flag to manage fixed rate
 clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-ufs-s32n7-v11-11-dc36e11919d5@oss.nxp.com>
References: <20261114-b4-ufs-s32n7-v11-0-dc36e11919d5@oss.nxp.com>
In-Reply-To: <20261114-b4-ufs-s32n7-v11-0-dc36e11919d5@oss.nxp.com>
To: "Martin K. Petersen" <mkp@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Rob Herring <robh@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>
Cc: devicetree@vger.kernel.org, Ajay Neeli <ajay.neeli@amd.com>, 
 Adrian Hunter <adrian.hunter@intel.com>, linux-arm-msm@vger.kernel.org, 
 Peter Wang <peter.wang@mediatek.com>, linux-kernel@vger.kernel.org, 
 NXP S32 Linux Team <s32@nxp.com>, Asutosh Das <quic_asutoshd@quicinc.com>, 
 linux-arm-kernel@lists.infradead.org, Stanley Jhu <stanleyjhu@google.com>, 
 Frank Li <Frank.Li@nxp.com>, imx@lists.linux.dev, 
 linux-scsi@vger.kernel.org, Bean Huo <beanhuo@micron.com>, 
 linux-mediatek@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Pedro Sousa <pedrom.sousa@synopsys.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, eballetb@redhat.com, 
 Peter Griffin <peter.griffin@linaro.org>, echanude@redhat.com, 
 Chaotian Jing <chaotian.jing@mediatek.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>, 
 Sai Krishna Potthuri <sai.krishna.potthuri@amd.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-rockchip@lists.infradead.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, clizzi@redhat.com, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>, Matthias Brugger <matthias.bgg@gmail.com>, 
 Chunyan Zhang <zhang.lyra@gmail.com>, Can Guo <can.guo@oss.qualcomm.com>, 
 Orson Zhai <orsonzhai@gmail.com>, aruizrui@redhat.com, 
 linux-renesas-soc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794657370; l=5794;
 i=larisa.grigore@oss.nxp.com; s=20261114; h=from:subject:message-id;
 bh=gfpDkcJvEuz9ohkYzalTe5JXhCA/VTTkJXlX970pQDU=;
 b=o1tlKOyaboHDGeDGhpmh3x4nGW0otGNWGbqfiXBQ0n0U/gzpzUz43PtRaIkF+qw47BCvRW8KU
 ho70Z9Qj3ZtDkP9m/+ELCNqFq+O1bVFQtCXo0Gf7h0LuaRtowpustei
X-Developer-Key: i=larisa.grigore@oss.nxp.com; a=ed25519;
 pk=Jpt52sb6ETKTtvWjUzhz5Sv5FjB9AEg9QKCcbpWFx3w=
X-Endpoint-Received: by B4 Relay for larisa.grigore@oss.nxp.com/20261114 with auth_id=1522
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some UFS host controllers have clocks whose rate is set by the clock
provider and is never scaled. ufshcd_parse_clock_info() registers the
clocks listed in clock-names only when freq-table-hz is present, and
ufshcd_parse_operating_points() only when operating-points-v2 is
present. On such platforms the UFS core therefore neither enables the
clocks at probe nor gates them on idle and on suspend.

Describing these clocks with a dummy operating-points-v2 table, or with
the deprecated freq-table-hz property, only to make the core manage
them is not desirable.

Registering the clocks unconditionally is not possible either: some
glue drivers list clocks without a frequency table and manage them
themselves (e.g. ufs-rockchip on rk3576), and the core would then start
to enable, gate and possibly scale the same clocks.

Add UFSHCD_PLTFRM_FIXED_RATE_CLKS. When a glue driver passes it to
ufshcd_pltfrm_init() and neither freq-table-hz nor operating-points-v2
is present, register the clocks from clock-names with min_freq and
max_freq set to 0. ufshcd_init_clocks() then leaves their rate
unchanged, and the UFS core enables and gates them like any other
clock. The flag is not meant to be combined with
UFSHCD_CAP_CLK_SCALING.

Assisted-by: LLM
Signed-off-by: Larisa Grigore <larisa.grigore@oss.nxp.com>
---
 drivers/ufs/host/ufshcd-pltfrm.c | 57 ++++++++++++++++++++++++----------------
 drivers/ufs/host/ufshcd-pltfrm.h |  9 +++++++
 2 files changed, 44 insertions(+), 22 deletions(-)

diff --git a/drivers/ufs/host/ufshcd-pltfrm.c b/drivers/ufs/host/ufshcd-pltfrm.c
index f8b2d64b6b4b..50afc2816dc7 100644
--- a/drivers/ufs/host/ufshcd-pltfrm.c
+++ b/drivers/ufs/host/ufshcd-pltfrm.c
@@ -21,7 +21,7 @@
 
 #define UFSHCD_DEFAULT_LANES_PER_DIRECTION		2
 
-static int ufshcd_parse_clock_info(struct ufs_hba *hba)
+static int ufshcd_parse_clock_info(struct ufs_hba *hba, unsigned int flags)
 {
 	int ret = 0;
 	int cnt;
@@ -51,32 +51,43 @@ static int ufshcd_parse_clock_info(struct ufs_hba *hba)
 
 	sz = of_property_count_u32_elems(np, "freq-table-hz");
 	if (sz <= 0) {
-		dev_info(dev, "freq-table-hz property not specified\n");
-		goto out;
-	}
+		/*
+		 * Without a frequency table the clocks are either registered by
+		 * ufshcd_parse_operating_points() or managed by the glue driver,
+		 * unless the glue driver asked for fixed rate clocks.
+		 */
+		if (!(flags & UFSHCD_PLTFRM_FIXED_RATE_CLKS) ||
+		    of_property_present(np, "operating-points-v2")) {
+			dev_info(dev, "freq-table-hz property not specified\n");
+			goto out;
+		}
 
-	if (sz != 2 * cnt) {
+		dev_dbg(dev, "no frequency table, using fixed rate clocks\n");
+		sz = 0;
+	} else if (sz != 2 * cnt) {
 		dev_err(dev, "%s len mismatch\n", "freq-table-hz");
 		ret = -EINVAL;
 		goto out;
 	}
 
-	clkfreq = devm_kzalloc_objs(dev, *clkfreq, sz);
-	if (!clkfreq) {
-		ret = -ENOMEM;
-		goto out;
-	}
+	if (sz) {
+		clkfreq = devm_kzalloc_objs(dev, *clkfreq, sz);
+		if (!clkfreq) {
+			ret = -ENOMEM;
+			goto out;
+		}
 
-	ret = of_property_read_u32_array(np, "freq-table-hz",
-			clkfreq, sz);
-	if (ret && (ret != -EINVAL)) {
-		dev_err(dev, "%s: error reading array %d\n",
+		ret = of_property_read_u32_array(np, "freq-table-hz",
+						 clkfreq, sz);
+		if (ret && (ret != -EINVAL)) {
+			dev_err(dev, "%s: error reading array %d\n",
 				"freq-table-hz", ret);
-		return ret;
+			return ret;
+		}
 	}
 
-	for (i = 0; i < sz; i += 2) {
-		ret = of_property_read_string_index(np,	"clock-names", i/2,
+	for (i = 0; i < cnt; i++) {
+		ret = of_property_read_string_index(np,	"clock-names", i,
 						    &name);
 		if (ret)
 			goto out;
@@ -87,8 +98,10 @@ static int ufshcd_parse_clock_info(struct ufs_hba *hba)
 			goto out;
 		}
 
-		clki->min_freq = clkfreq[i];
-		clki->max_freq = clkfreq[i+1];
+		if (clkfreq) {
+			clki->min_freq = clkfreq[2 * i];
+			clki->max_freq = clkfreq[2 * i + 1];
+		}
 		clki->name = devm_kstrdup(dev, name, GFP_KERNEL);
 		if (!clki->name) {
 			ret = -ENOMEM;
@@ -97,8 +110,8 @@ static int ufshcd_parse_clock_info(struct ufs_hba *hba)
 
 		if (!strcmp(name, "ref_clk"))
 			clki->keep_link_active = true;
-		dev_dbg(dev, "%s: min %u max %u name %s\n", "freq-table-hz",
-				clki->min_freq, clki->max_freq, clki->name);
+		dev_dbg(dev, "%s: min %u max %u name %s\n", __func__,
+			clki->min_freq, clki->max_freq, clki->name);
 		list_add_tail(&clki->list, &hba->clk_list_head);
 	}
 out:
@@ -670,7 +683,7 @@ int ufshcd_pltfrm_init(struct platform_device *pdev,
 
 	hba->vops = vops;
 
-	err = ufshcd_parse_clock_info(hba);
+	err = ufshcd_parse_clock_info(hba, flags);
 	if (err) {
 		dev_err(dev, "%s: clock parse failed %d\n",
 				__func__, err);
diff --git a/drivers/ufs/host/ufshcd-pltfrm.h b/drivers/ufs/host/ufshcd-pltfrm.h
index 0dc48c8d89d5..1f612734507c 100644
--- a/drivers/ufs/host/ufshcd-pltfrm.h
+++ b/drivers/ufs/host/ufshcd-pltfrm.h
@@ -5,6 +5,7 @@
 #ifndef UFSHCD_PLTFRM_H_
 #define UFSHCD_PLTFRM_H_
 
+#include <linux/bits.h>
 #include <ufs/ufshcd.h>
 
 #define UFS_PWM_MODE 1
@@ -25,6 +26,14 @@ struct ufs_host_params {
 	u32 desired_working_mode;
 };
 
+/*
+ * Register the clocks listed in clock-names even when neither freq-table-hz
+ * nor operating-points-v2 is present. Their rate is set by the clock provider
+ * and is not scaled, but the UFS core enables and gates them. Not meant to be
+ * combined with UFSHCD_CAP_CLK_SCALING, as there is nothing to scale.
+ */
+#define UFSHCD_PLTFRM_FIXED_RATE_CLKS	BIT(0)
+
 int ufshcd_negotiate_pwr_params(const struct ufs_host_params *host_params,
 				const struct ufs_pa_layer_attr *dev_max,
 				struct ufs_pa_layer_attr *agreed_pwr);

-- 
2.43.0

