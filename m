From: Sven Peter <sven@kernel.org>
Subject: [PATCH 00/11] Drop default ARCH_APPLE from Kconfig and use
 defconfig instead
Date: Thu, 12 Jun 2025 21:11:24 +0000
Message-Id: <20250612-apple-kconfig-defconfig-v1-0-0e6f9cb512c1@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHxCS2gC/y2MQQqAIBAAvxJ7biELw/pKdFBbaylMFCII/55Et
 5nDzAOJIlOCsXog0sWJT19E1BXYTfuVkJfi0DatbHohUIdwEO729I5XXMj9ZKRUqu+0smaAUod
 Iju/vPM05vx3OGPppAAAA
X-Change-ID: 20250611-apple-kconfig-defconfig-b558863a8cb9
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1992; i=sven@kernel.org;
 h=from:subject:message-id; bh=NJlC89e85kPwnIrRRCWxs5BdJsq3vAE6W0Ymwg3gpew=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4a3U6dZ4Ztcjq5zQonza32t3J9YGMQ0PjDSnbD/jIi18
 ITHgQc6SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABN5Zs/wP5kp4uxT2Zp2YWsl
 +cmOLgVCpo7J3D+thMpvP3pTXrp6IcP/nIMz18Rev6yRM+OVyuwn8YGHl875+rOvr9AyS+ldk5g
 6BwA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

When support for Apple Silicon was originally upstreamed we somehow
started using `default ARCH_APPLE` for most drivers. arm64 defconfig
also contains ARCH_APPLE=y such that this will turn into `default y`
there by default which is neither what we want nor how this is usually
done.
Let's fix all that by dropping the default everywhere and adding the
drivers to defconfig as modules instead of built-ins.
None of these patches depend on each other so we can just take them all
independently through the respective subsystem trees.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (11):
      pmdomain: apple: Drop default ARCH_APPLE in Kconfig
      soc: apple: Drop default ARCH_APPLE in Kconfig
      clk: apple-nco: Drop default ARCH_APPLE in Kconfig
      nvmem: apple: drop default ARCH_APPLE in Kconfig
      i2c: apple: Drop default ARCH_APPLE in Kconfig
      cpufreq: apple: drop default ARCH_APPLE in Kconfig
      iommu/apple-dart: Drop default ARCH_APPLE in Kconfig
      Input: apple_z2: Drop default ARCH_APPLE in Kconfig
      dmaengine: apple-admac: Drop default ARCH_APPLE in Kconfig
      ASoC: apple: mca: Drop default ARCH_APPLE in Kconfig
      arm64: defconfig: Enable Apple Silicon drivers

 arch/arm64/configs/defconfig      | 19 +++++++++++++++++++
 drivers/clk/Kconfig               |  1 -
 drivers/cpufreq/Kconfig.arm       |  1 -
 drivers/dma/Kconfig               |  1 -
 drivers/i2c/busses/Kconfig        |  1 -
 drivers/input/touchscreen/Kconfig |  1 -
 drivers/iommu/Kconfig             |  1 -
 drivers/nvmem/Kconfig             |  1 -
 drivers/pmdomain/apple/Kconfig    |  1 -
 drivers/soc/apple/Kconfig         |  3 ---
 sound/soc/apple/Kconfig           |  1 -
 11 files changed, 19 insertions(+), 12 deletions(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250611-apple-kconfig-defconfig-b558863a8cb9

Best regards,
-- 
Sven Peter <sven@kernel.org>

