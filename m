From: Sven Peter <sven@kernel.org>
Date: Thu, 12 Jun 2025 21:11:26 +0000
Subject: [PATCH 02/11] soc: apple: Drop default ARCH_APPLE in Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250612-apple-kconfig-defconfig-v1-2-0e6f9cb512c1@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1647; i=sven@kernel.org;
 h=from:subject:message-id; bh=1ktk8adW9Q8MazSYAza7zZHZaiASrCb+ItILUqRabHI=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4a308QpomuvNzTHFunsvpOzQYPt/dn00ioHC64jf48yT
 /NcO/94RykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiU7kZGb5dbpp4bXq8vCdf
 5OnLvw7tjj8dxvdAOo4rMZeXQVJ1kywjw+8LG7V/apnUcOdNUrp44/RNV10J+9Rr36eq3JKtqb4
 QxAQA
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
 drivers/soc/apple/Kconfig | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/drivers/soc/apple/Kconfig b/drivers/soc/apple/Kconfig
index 6388cbe1e56b5a9d90acad3ee2377ed6ac0d207d..ad67368892311bed5a94d358288390a6fb8b3b4a 100644
--- a/drivers/soc/apple/Kconfig
+++ b/drivers/soc/apple/Kconfig
@@ -8,7 +8,6 @@ config APPLE_MAILBOX
 	tristate "Apple SoC mailboxes"
 	depends on PM
 	depends on ARCH_APPLE || (64BIT && COMPILE_TEST)
-	default ARCH_APPLE
 	help
 	  Apple SoCs have various co-processors required for certain
 	  peripherals to work (NVMe, display controller, etc.). This
@@ -21,7 +20,6 @@ config APPLE_RTKIT
 	tristate "Apple RTKit co-processor IPC protocol"
 	depends on APPLE_MAILBOX
 	depends on ARCH_APPLE || COMPILE_TEST
-	default ARCH_APPLE
 	help
 	  Apple SoCs such as the M1 come with various co-processors running
 	  their proprietary RTKit operating system. This option enables support
@@ -33,7 +31,6 @@ config APPLE_RTKIT
 config APPLE_SART
 	tristate "Apple SART DMA address filter"
 	depends on ARCH_APPLE || COMPILE_TEST
-	default ARCH_APPLE
 	help
 	  Apple SART is a simple DMA address filter used on Apple SoCs such
 	  as the M1. It is usually required for the NVMe coprocessor which does

-- 
2.34.1

