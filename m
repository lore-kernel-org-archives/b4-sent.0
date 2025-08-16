From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 16 Aug 2025 00:53:37 -0500
Subject: [PATCH 5/5] arm64: tegra: Limit max cpu frequency on P3450
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250816-tegra210-speedo-v1-5-a981360adc27@gmail.com>
References: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
In-Reply-To: <20250816-tegra210-speedo-v1-0-a981360adc27@gmail.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Joseph Lo <josephl@nvidia.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thierry Reding <treding@nvidia.com>, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755323658; l=935;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=JtR2frb8U61WYYSqhxHsZ+WqeNipPuKmeW1w+OFmzpU=;
 b=c8aF1tlFVKvuMAgjpH17Vx+W6YJ9ly6+2UZTmDmo879riiX6BemOb25Mah5RxcSAtHIDCI+VW
 kPtnx+v5hAcB7G6R9kog0SaaaP/PtAG4t6pc175XEY1HjM4RniK+1dA
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

P3450's cpu is only rated for 1.4 GHz while the CVB table it uses tries
to scale to 1.5 GHz. Set an appropriate limit on the maximum scaling
frequency.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
index ec0e84cb83ef9bf8f0e52e2958db33666813917c..10f878d3f50815d1f0297d15669048ab9cad73ee 100644
--- a/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts
@@ -594,6 +594,7 @@ clock@70110000 {
 		nvidia,droop-ctrl = <0x00000f00>;
 		nvidia,force-mode = <1>;
 		nvidia,sample-rate = <25000>;
+		nvidia,dfll-max-freq = <1479000000>;
 
 		nvidia,pwm-min-microvolts = <708000>;
 		nvidia,pwm-period-nanoseconds = <2500>; /* 2.5us */

-- 
2.50.1

