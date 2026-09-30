From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 30 Sep 2026 13:14:29 +0300
Subject: [PATCH v5 3/4] nvmem: mtk-efuse: add CPU speedbin post-processing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-6572-nvmem-v5-3-384d2a3a1770@protonmail.com>
References: <20260930-6572-nvmem-v5-0-384d2a3a1770@protonmail.com>
In-Reply-To: <20260930-6572-nvmem-v5-0-384d2a3a1770@protonmail.com>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Andrew-CT Chen <andrew-ct.chen@mediatek.com>, 
 Lala Lin <lala.lin@mediatek.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790763284; l=1737;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=obcdDbJPC+bJJB8ejmXjnP6/QmD/06/XozyzFUcNY2c=;
 b=5GShSUHPJqiXvrqHRiSZTcESxZC/UG33Tn9SrBVmHk6NKDWSNpSL7fN2RH+escj9ogsV9oqRy
 D6v3trKnWGYDiKD6tLp28Pl4bnfDCjc+XuZwZ15pENMehY6uHxmfM/l
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MediaTek SoCs are often released under the same marketing name, but with
different suffix for the speedbin. For example, mt6572m has 1 GHz limit,
mt6572a - 1.2 GHz, mt6572w - 1.4 GHz.

Since the speedbin is stored as a number in the efuse, add support for
converting it to the bitmask for opp-supported-hw usage in the DT.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/nvmem/mtk-efuse.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/drivers/nvmem/mtk-efuse.c b/drivers/nvmem/mtk-efuse.c
index 980c29d01337..d2e5c69c580e 100644
--- a/drivers/nvmem/mtk-efuse.c
+++ b/drivers/nvmem/mtk-efuse.c
@@ -70,6 +70,18 @@ static int mtk_efuse_gpu_speedbin_pp(void *context, const char *id, int index,
 	return 0;
 }
 
+static int mtk_efuse_cpu_speedbin_pp(void *context, const char *id, int index,
+				     unsigned int offset, void *data, size_t bytes)
+{
+	u8 *val = data;
+
+	if (val[0] >= 8)
+		return -EINVAL;
+
+	val[0] = BIT(val[0]);
+	return 0;
+}
+
 static void mtk_efuse_fixup_dt_cell_info(struct nvmem_device *nvmem,
 					 struct nvmem_cell_info *cell)
 {
@@ -83,6 +95,13 @@ static void mtk_efuse_fixup_dt_cell_info(struct nvmem_device *nvmem,
 	if (cell->nbits <= 3 &&
 	    strncmp(cell->name, "gpu-speedbin", min(sz, strlen("gpu-speedbin"))) == 0)
 		cell->read_post_process = mtk_efuse_gpu_speedbin_pp;
+
+	/*
+	 * On mobile SoCs, the CPU speedbin is a number. Convert it to
+	 * a bitmask for supported-hw usage.
+	 */
+	if (strncmp(cell->name, "cpu-speedbin", min(sz, strlen("cpu-speedbin"))) == 0)
+		cell->read_post_process = mtk_efuse_cpu_speedbin_pp;
 }
 
 static int mtk_efuse_probe(struct platform_device *pdev)

-- 
2.55.0

