From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 06 Apr 2026 01:39:18 -0500
Subject: [PATCH] arm64: tegra: Enable interconnect for MC and EMC on
 Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-tegra210-actmon-dt-fixup-v1-1-6b6149b76eaf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2NwQrCQAxEf6XkbCANbWX9FfGwbGPNwW3NbotQ+
 u8G9fhmeDM7FDGVApdmB5NNi87ZoT01kB4xT4I6OgMTD9RRj1Umi9wSxlSfc8ax4l3f64JDoHT
 uQs8cAri+mHjxnb7efmzyWv2h/sPj+AADDHgtfwAAAA==
X-Change-ID: 20260405-tegra210-actmon-dt-fixup-690c74952299
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <treding@nvidia.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775457559; l=2268;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=gyXAVSoHIXIcTUJk7cMRiRQgVTvpFrxg/mZlvuJD8to=;
 b=fvVZsQOBO01S3p+Rl40KVaAfU07CaNl5IhZUl9HawSK/LN/ypmUJNxJ2VQTZpYFKnAAZYklv0
 zLcQV3um12kDvFrmXLVyCzHxu/5Zy8mLLgjjq3PErkU9HFXwCyv8Jqo
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are being referenced by actmon, but are not currently enabled.

Fixes: 654427e0b9b7 ("arm64: tegra: Add OPP tables on Tegra210")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
When the opp tables were added to tegra210 [0], there was a previous
commit [1] that enabled interconnect on the mc and emc nodes. This was
later reverted [2] because some setups such as the Nvidia regression
test bench do not pass emc training data and thus the emc driver cannot
probe. Since interconnects cannot be optionally routed, the dc
interconnect routes cannot be enabled if the kernel is to support
bootloader setups that do not properly pass emc training data. Thus this
only fixes the routes enough for actmon to operate, because actmon
failing to probe is no more fatal than an emc failure.

This depends on the mc/emc driver patch to add interconnect support [3],
which should be merged first.

[0] https://lore.kernel.org/linux-tegra/20251021-t210-actmon-p4-v5-3-4a4dbc49fbc8@gmail.com/
[1] https://lore.kernel.org/linux-tegra/20251021-t210-actmon-p4-v5-2-4a4dbc49fbc8@gmail.com/
[2] https://lore.kernel.org/linux-tegra/20251217104744.184153-1-jonathanh@nvidia.com/
[3] https://lore.kernel.org/linux-tegra/20260406-t210-actmon-p2-v7-1-91adf535cf8f@gmail.com/
---
 arch/arm64/boot/dts/nvidia/tegra210.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210.dtsi b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
index 5f5e5370d70966918943232acab8992bf91ec42a..a5537a5c472c4bf5d649cc52372e531452b594f7 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210.dtsi
+++ b/arch/arm64/boot/dts/nvidia/tegra210.dtsi
@@ -1028,6 +1028,7 @@ mc: memory-controller@70019000 {
 
 		#iommu-cells = <1>;
 		#reset-cells = <1>;
+		#interconnect-cells = <1>;
 	};
 
 	emc: external-memory-controller@7001b000 {
@@ -1041,6 +1042,7 @@ emc: external-memory-controller@7001b000 {
 		nvidia,memory-controller = <&mc>;
 		operating-points-v2 = <&emc_icc_dvfs_opp_table>;
 
+		#interconnect-cells = <0>;
 		#cooling-cells = <2>;
 	};
 

---
base-commit: 2febe6e6ee6e34c7754eff3c4d81aa7b0dcb7979
change-id: 20260405-tegra210-actmon-dt-fixup-690c74952299

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

