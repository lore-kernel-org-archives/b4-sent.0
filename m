From: Torsten Rupp <torsten.rupp@8tronix.de>
Date: Thu, 03 Sep 2026 09:20:42 +0200
Subject: [PATCH] fix 32bit silent truncation of 64bit offset in
 mmc_get_env_addr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-mmc-fixes-v1-1-946242839347@8tronix.de>
X-B4-Tracking: v=1; b=H4sIAMofmWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwNj3dzcZN20zIrUYl2LxMQkIxNTS1NLSwsloPqColSwBFB5dGxtLQA
 XpJDyWwAAAA==
To: "NXP i.MX U-Boot Team" <uboot-imx@nxp.com>, 
 u-boot@lists.u-boot-project.org
Cc: Frieder Schrempf <frieder.schrempf@kontron.de>, 
 Tom Rini <trini@konsulko.com>, Stefano Babic <sbabic@nabladev.com>, 
 Fabio Estevam <festevam@gmail.com>, Peng Fan <peng.fan@nxp.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Tanmay Kathpalia <tanmay.kathpalia@altera.com>, 
 Eric Chung <eric.chung@riscstar.com>, Han Xu <han.xu@nxp.com>, 
 Torsten Rupp <torsten.rupp@8tronix.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788420043; l=5217;
 i=torsten.rupp@8tronix.de; s=20260903; h=from:subject:message-id;
 bh=N6Oa9ovFnWj46mDS7TgLCycBPoyr0wpKaQ0+dg6Tbb8=;
 b=9GcuB7eAl6+f15bU5Nub2g0oBza1JWytDfG8bTlinAESI3LtVAoWSxcF+WGMhtK0d5y4kWdZy
 O36R2EacfsgD7/mqvBVyoeNFdy3lNr32ikSL9CD+o/7eJdYUFZPxJUT
X-Developer-Key: i=torsten.rupp@8tronix.de; a=ed25519;
 pk=DFK2o6nuApZFiFHnUsWwIP/HTQZwoFI2698xwMNi5rw=
X-Endpoint-Received: by B4 Relay for torsten.rupp@8tronix.de/20260903 with auth_id=999
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The function mmc_get_env_addr() return the address (offset) of the
enviroment variables. Internally it calculates a 64bit value, but
the value is silently truncated by the provided 32bit return value.
For offsets greater than 4GB the environment is read from and written
to the wrong place in e. g. the flash memory and may override
arbitrary data.

Signed-off-by: Torsten Rupp <torsten.rupp@8tronix.de>
---
The function mmc_get_env_addr() return the address (offset) of the
enviroment variables. Internally it calculates a 64bit value, but
the value is silently truncated by the provided 32bit return value.
For offsets greater than 4GB the environment is read from and written
to the wrong place in e. g. the flash memory and may override
arbitrary data.
---
 board/kontron/osm-s-mx8mp/osm-s-mx8mp.c |  2 +-
 board/kontron/osm-s-mx93/osm-s-mx93.c   |  2 +-
 board/kontron/sl-mx8mm/sl-mx8mm.c       |  2 +-
 board/nxp/common/sdhc_boot.c            |  2 +-
 env/mmc.c                               | 10 +++++-----
 include/mmc.h                           |  2 +-
 6 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/board/kontron/osm-s-mx8mp/osm-s-mx8mp.c b/board/kontron/osm-s-mx8mp/osm-s-mx8mp.c
index 739a78d2c8b..aaf73a2bbb2 100644
--- a/board/kontron/osm-s-mx8mp/osm-s-mx8mp.c
+++ b/board/kontron/osm-s-mx8mp/osm-s-mx8mp.c
@@ -132,7 +132,7 @@ uint mmc_get_env_part(struct mmc *mmc)
 	}
 }
 
-int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr)
+int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr)
 {
 	/* use normal offset for SD card */
 	if (IS_SD(mmc)) {
diff --git a/board/kontron/osm-s-mx93/osm-s-mx93.c b/board/kontron/osm-s-mx93/osm-s-mx93.c
index 02bee34ac66..23e33bddc53 100644
--- a/board/kontron/osm-s-mx93/osm-s-mx93.c
+++ b/board/kontron/osm-s-mx93/osm-s-mx93.c
@@ -120,7 +120,7 @@ uint mmc_get_env_part(struct mmc *mmc)
 	}
 }
 
-int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr)
+int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr)
 {
 	/* use normal offset for SD card */
 	if (IS_SD(mmc)) {
diff --git a/board/kontron/sl-mx8mm/sl-mx8mm.c b/board/kontron/sl-mx8mm/sl-mx8mm.c
index d24d5286e45..0138c5921a2 100644
--- a/board/kontron/sl-mx8mm/sl-mx8mm.c
+++ b/board/kontron/sl-mx8mm/sl-mx8mm.c
@@ -256,7 +256,7 @@ uint mmc_get_env_part(struct mmc *mmc)
 	}
 }
 
-int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr)
+int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr)
 {
 	/* use normal offset for SD card */
 	if (IS_SD(mmc)) {
diff --git a/board/nxp/common/sdhc_boot.c b/board/nxp/common/sdhc_boot.c
index 5ee730cefd0..0c2532a8595 100644
--- a/board/nxp/common/sdhc_boot.c
+++ b/board/nxp/common/sdhc_boot.c
@@ -16,7 +16,7 @@
 
 #define ESDHC_DEFAULT_ENVADDR	0x400
 
-int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr)
+int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr)
 {
 	u8 *tmp_buf;
 	u32 blklen, code_offset, code_len, n;
diff --git a/env/mmc.c b/env/mmc.c
index 1eddba3b0f8..4b5f8e2dcee 100644
--- a/env/mmc.c
+++ b/env/mmc.c
@@ -230,7 +230,7 @@ static bool mmc_env_is_redundant_in_both_boot_hwparts(struct mmc *mmc)
 	return mmc_offset(mmc, 0) == mmc_offset(mmc, 1);
 }
 
-__weak int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr)
+__weak int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr)
 {
 	s64 offset = mmc_offset(mmc, copy);
 
@@ -331,7 +331,7 @@ static int env_mmc_save(void)
 	ALLOC_CACHE_ALIGN_BUFFER(env_t, env_new, 1);
 	int dev = mmc_get_env_dev();
 	struct mmc *mmc = find_mmc_device(dev);
-	u32	offset;
+	u64	offset;
 	int	ret, copy = 0;
 	const char *errmsg;
 
@@ -402,7 +402,7 @@ static int env_mmc_erase(void)
 	int dev = mmc_get_env_dev();
 	struct mmc *mmc = find_mmc_device(dev);
 	int	ret, copy = 0;
-	u32	offset;
+	u64	offset;
 	const char *errmsg;
 
 	errmsg = init_mmc_for_env(mmc);
@@ -459,7 +459,7 @@ static inline int read_env(struct mmc *mmc, unsigned long size,
 static int env_mmc_load_redundant(void)
 {
 	struct mmc *mmc;
-	u32 offset1, offset2;
+	u64 offset1, offset2;
 	int read1_fail = 0, read2_fail = 0;
 	int ret;
 	int dev = mmc_get_env_dev();
@@ -517,7 +517,7 @@ static int env_mmc_load_singular(void)
 {
 	ALLOC_CACHE_ALIGN_BUFFER(char, buf, CONFIG_ENV_SIZE);
 	struct mmc *mmc;
-	u32 offset;
+	u64 offset;
 	int ret;
 	int dev = mmc_get_env_dev();
 	const char *errmsg;
diff --git a/include/mmc.h b/include/mmc.h
index 4bda44ea220..9a796e0655f 100644
--- a/include/mmc.h
+++ b/include/mmc.h
@@ -1002,7 +1002,7 @@ void mmc_set_preinit(struct mmc *mmc, int preinit);
 void board_mmc_power_init(void);
 int board_mmc_init(struct bd_info *bis);
 int cpu_mmc_init(struct bd_info *bis);
-int mmc_get_env_addr(struct mmc *mmc, int copy, u32 *env_addr);
+int mmc_get_env_addr(struct mmc *mmc, int copy, u64 *env_addr);
 # ifdef CONFIG_ENV_MMC_EMMC_HW_PARTITION
 extern uint mmc_get_env_part(struct mmc *mmc);
 # endif

---
base-commit: cc8c034e78eba6b2a3845783889b80753bb1af1e
change-id: 20260903-mmc-fixes-8aab24595998

Best regards,
-- 
Torsten Rupp <torsten.rupp@8tronix.de>

