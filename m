From: Sven Peter <sven@kernel.org>
Date: Thu, 12 Jun 2025 21:11:25 +0000
Subject: [PATCH 01/11] pmdomain: apple: Drop default ARCH_APPLE in Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-apple-kconfig-defconfig-v1-1-0e6f9cb512c1@kernel.org>
References: <20250612-apple-kconfig-defconfig-v1-0-0e6f9cb512c1@kernel.org>
In-Reply-To: <20250612-apple-kconfig-defconfig-v1-0-0e6f9cb512c1@kernel.org>
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Ulf Hansson <ulf.hansson@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 =?utf-8?q?Martin_Povi=C5=A1er?= <povik+lin@cutebit.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-i2c@vger.kernel.org, iommu@lists.linux.dev, 
 linux-input@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-sound@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1001; i=sven@kernel.org;
 h=from:subject:message-id; bh=OOlbVfIgzSBqrQXeX6P9ycG03p+lP2ZHx7YjgEpCU6M=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4a304RI+5uRSxcm2H0JiO3dduZX2HrBD36b5tV1dlZfM
 EnjkDLrKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzk7F5GhhlGi+Uymmt3XJY6
 o5eV9aXOS3nGtZvsb97re8a/Led9msbwP7ByVZLoA4uPsRrqS1llrFVnWH9h/9D1rOtKQJZHCsM
 0LgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the first driver for Apple Silicon was upstreamed we accidentally
included `default ARCH_APPLE` in its Kconfig which then spread to almost
every subsequent driver. As soon as ARCH_APPLE is set to y this will
pull in many drivers as built-ins which is not what we want.
Thus, drop `default ARCH_APPLE` from Kconfig.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/pmdomain/apple/Kconfig | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/pmdomain/apple/Kconfig b/drivers/pmdomain/apple/Kconfig
index 12237cbcfaa983083367bad70b1b54ded9ac9824..a8973f8057fba74cd3e8c7d15cd2972081c6697d 100644
--- a/drivers/pmdomain/apple/Kconfig
+++ b/drivers/pmdomain/apple/Kconfig
@@ -9,7 +9,6 @@ config APPLE_PMGR_PWRSTATE
 	select MFD_SYSCON
 	select PM_GENERIC_DOMAINS
 	select RESET_CONTROLLER
-	default ARCH_APPLE
 	help
 	  The PMGR block in Apple SoCs provides high-level power state
 	  controls for SoC devices. This driver manages them through the

-- 
2.34.1

