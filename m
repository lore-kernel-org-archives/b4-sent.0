From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 26 Feb 2025 12:51:59 -0600
Subject: [PATCH v2] cpufreq: tegra194: Allow building for Tegra234
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250226-build-tegra234-v2-1-cf7e0828714e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAM5iv2cC/3XMyw6DIBCF4Vcxsy6NjNhIV32PxgXKgJN4C1jSx
 vjupe67/E9yvh0iBaYI92KHQIkjL3MOvBTQD2b2JNjmBiyxLhGV6F48WrGRDwYrJXrZ1J012ll
 lIJ/WQI7fJ/hscw8ctyV8Tj/J3/qXSlKUotKkSEt0+tY8/GR4vPbLBO1xHF8+ucJarAAAAA==
X-Change-ID: 20250224-build-tegra234-c185bda9fd4a
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Sumit Gupta <sumitg@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740595920; l=1281;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=GG8pNgZW8mtQ5aeY2C820RuKlp035VZNXb4TjlINh+A=;
 b=zB4HOcISgehHy7Msut+TQBc3j6s72LSJxEraXHywnKs5su5bJZGKTooUzqOTLcm1t2VlpsoHs
 z+bdcI1fiPxAIradJsOH/0g6L2oh2A9Hw4ml19sMM3W0hgIAW2YCsEs
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support was added for Tegra234 in the referenced commit, but the Kconfig
was not updated to allow building for the arch.

Fixes: 273bc890a2a8 ("cpufreq: tegra194: Add support for Tegra234")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Drop pci patch which duplicates
  https://lore.kernel.org/lkml/20250128044244.2766334-1-vidyas@nvidia.com/
- Link to v1: https://lore.kernel.org/r/20250224-build-tegra234-v1-0-39e4e912f968@gmail.com
---
 drivers/cpufreq/Kconfig.arm | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/cpufreq/Kconfig.arm b/drivers/cpufreq/Kconfig.arm
index 9e46960f6a862b8b686a79bf3c20f1024ce3d02d..4f9cb943d945c244eb2b29f543d14df6cac4e5d4 100644
--- a/drivers/cpufreq/Kconfig.arm
+++ b/drivers/cpufreq/Kconfig.arm
@@ -254,7 +254,7 @@ config ARM_TEGRA186_CPUFREQ
 
 config ARM_TEGRA194_CPUFREQ
 	tristate "Tegra194 CPUFreq support"
-	depends on ARCH_TEGRA_194_SOC || (64BIT && COMPILE_TEST)
+	depends on ARCH_TEGRA_194_SOC || ARCH_TEGRA_234_SOC || (64BIT && COMPILE_TEST)
 	depends on TEGRA_BPMP
 	default y
 	help

---
base-commit: d082ecbc71e9e0bf49883ee4afd435a77a5101b6
change-id: 20250224-build-tegra234-c185bda9fd4a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

