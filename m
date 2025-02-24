From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 24 Feb 2025 11:55:33 -0600
Subject: [PATCH 1/2] cpufreq: tegra194: Allow building for Tegra234
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250224-build-tegra234-v1-1-39e4e912f968@gmail.com>
References: <20250224-build-tegra234-v1-0-39e4e912f968@gmail.com>
In-Reply-To: <20250224-build-tegra234-v1-0-39e4e912f968@gmail.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Sumit Gupta <sumitg@nvidia.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Vidya Sagar <vidyas@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740419820; l=901;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=N2Unw1HuoZWqut2GowZ6qITdgEN13Wd6f/8bHNS8mDo=;
 b=B8qdAanYCm4O6Ij5o9kyBkVQdPmpbNKzWrUVatQgd0MRn5PaeCkcVY7+cxX2EsGFxYRGcfnir
 bTVg0lW5L+qBQygnAPy7tsip9aQK4lToggc7ZlO9tn5dmalOrJxcG2+
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support was added for Tegra234 in the referenced commit, but the Kconfig
was not updated to allow building for the arch.

Fixes: 273bc890a2a8 ("cpufreq: tegra194: Add support for Tegra234")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
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

-- 
2.48.1

