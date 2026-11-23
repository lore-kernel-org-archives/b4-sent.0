From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 23 Nov 2026 23:02:33 +0200
Subject: [PATCH v6 3/4] nvmem: mtk-efuse: add CPU speedbin post-processing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-6572-nvmem-v6-3-7ba710b15657@protonmail.com>
References: <20261123-6572-nvmem-v6-0-7ba710b15657@protonmail.com>
In-Reply-To: <20261123-6572-nvmem-v6-0-7ba710b15657@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795467904; l=1989;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=wvU1NPRqy3lUR7AfJOi5v05HYuK5G0Upeyo71cnpGfs=;
 b=dINnKayKiufmwMGlbu1UkXsdVD7HlPGdUOWY7gX2+5TMwc/36W3OembB361yATvx2DZ7/2qIY
 wXGadnGV/0oCo5ZakANtiWWTWJprfZK6OVFVShLLOkY0inSc8B4dlHO
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MediaTek SoCs are often released under the same marketing name, but with
different suffix for the speedbin. For example, mt6572m has 1 GHz limit,
mt6572a - 1.2 GHz, mt6572w - 1.4 GHz.

Since CPU speedbin is stored as a number in the efuse, similar to GPU,
rename mtk_efuse_gpu_speedbin_pp() to mtk_efuse_speedbin_pp() and add
check for cpu-speedbin node to fixup the value for supported-hw usage in
OPP tables.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/nvmem/mtk-efuse.c | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/drivers/nvmem/mtk-efuse.c b/drivers/nvmem/mtk-efuse.c
index 980c29d01337..2c09649ce7f9 100644
--- a/drivers/nvmem/mtk-efuse.c
+++ b/drivers/nvmem/mtk-efuse.c
@@ -59,8 +59,8 @@ static int mtk_reg_read(void *context,
 	return 0;
 }
 
-static int mtk_efuse_gpu_speedbin_pp(void *context, const char *id, int index,
-				     unsigned int offset, void *data, size_t bytes)
+static int mtk_efuse_speedbin_pp(void *context, const char *id, int index,
+				 unsigned int offset, void *data, size_t bytes)
 {
 	u8 *val = data;
 
@@ -76,13 +76,14 @@ static void mtk_efuse_fixup_dt_cell_info(struct nvmem_device *nvmem,
 	size_t sz = strlen(cell->name);
 
 	/*
-	 * On some SoCs, the GPU speedbin is not read as bitmask but as
+	 * On some SoCs, the CPU/GPU speedbin is not read as bitmask but as
 	 * a number with range [0-7] (max 3 bits): post process to use
 	 * it in OPP tables to describe supported-hw.
 	 */
 	if (cell->nbits <= 3 &&
-	    strncmp(cell->name, "gpu-speedbin", min(sz, strlen("gpu-speedbin"))) == 0)
-		cell->read_post_process = mtk_efuse_gpu_speedbin_pp;
+	    (strncmp(cell->name, "gpu-speedbin", min(sz, strlen("gpu-speedbin"))) == 0 ||
+	     strncmp(cell->name, "cpu-speedbin", min(sz, strlen("cpu-speedbin"))) == 0))
+		cell->read_post_process = mtk_efuse_speedbin_pp;
 }
 
 static int mtk_efuse_probe(struct platform_device *pdev)

-- 
2.56.1

