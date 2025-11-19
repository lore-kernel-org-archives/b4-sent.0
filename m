From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:10 +0900
Subject: [PATCH 11/11] mtd: spi-nor: Call stacked/parallel post init fixups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-11-c555bd85e6e4@infineon.com>
References: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
In-Reply-To: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
To: u-boot@lists.denx.de, Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Jagan Teki <jagan@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Tom Rini <trini@konsulko.com>, 
 Ibai Erkiaga <ibai.erkiaga-elorza@amd.com>, Vignesh R <vigneshr@ti.com>, 
 Prasad Kummari <prasad.kummari@amd.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Havish Mutya <havish.mutya@amd.com>, 
 Ashok Reddy Soma <ashok.reddy.soma@amd.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Daassi Bacem <Bacem.Daassi@infineon.com>, 
 Shinsuke Okada <Shinsuke.Okada@infineon.com>, 
 Hiroyuki Saito <Hiroyuki.Saito2@infineon.com>, 
 Takahiro Kuwano <tkuw584924@gmail.com>, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=1426;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=Tg+dA3mBGmNn97VIjQKqueub32h6w19dYeeUbobngh0=;
 b=70z6GmNnastkl8xKkcCZFkC8mcNjNOBHrRkbEZMxVPBKiBRZKt6w8/lXdrSBZTnHg0ndlacK1
 EGmyghn/MdFDQowsOeekKqTSOf+A0bhGj+4/NqlvkHKShU3nLXPR7Lx
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for stacked/parallel mode by calling post_init_fixups() from
core.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/mtd/spi/sf_internal.h  |  3 +++
 drivers/mtd/spi/spi-nor-core.c | 10 ++++++++++
 2 files changed, 13 insertions(+)

diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 8b1a48f045a..a9825a0b317 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -108,4 +108,7 @@ int clean_bar(struct spi_nor *nor);
 int sst_write(struct mtd_info *mtd, loff_t to, size_t len, size_t *retlen,
 	      const u_char *buf);
 
+int spi_nor_stacked_post_init_fixups(struct spi_nor *nor);
+int spi_nor_parallel_post_init_fixups(struct spi_nor *nor);
+
 #endif /* _SF_INTERNAL_H_ */
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index acfbc0bb702..f9b6971e535 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -4363,6 +4363,16 @@ int spi_nor_scan(struct spi_nor *nor)
 	if (ret)
 		return ret;
 
+#if CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)
+	ret = spi_nor_stacked_post_init_fixups(nor);
+	if (ret)
+		return ret;
+
+	ret = spi_nor_parallel_post_init_fixups(nor);
+	if (ret)
+		return ret;
+#endif
+
 	nor->rdsr_dummy = params.rdsr_dummy;
 	nor->rdsr_addr_nbytes = params.rdsr_addr_nbytes;
 	nor->name = info->name;

-- 
2.34.1

