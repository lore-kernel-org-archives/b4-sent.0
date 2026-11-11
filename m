From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 06:00:11 +0000
Subject: [PATCH v2 5/8] arm64: dts: allwinner: orangepi-zero2: Keep VDD-SYS
 at or above 900 mV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-h616-zero2-dt-v2-5-88d8030fc975@gmail.com>
References: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
In-Reply-To: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794376807; l=1740;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=7dRmuEnXweiSK3ig6SjcXECMwYZqvp9fut5LB8gZugM=;
 b=hY+KOq6luqxLRdLmdChUvRel0o0EzwvWoP1PFOXHMKZi8Q2seKhI3U3A//ubeLw0X2zftgor3
 eIDcUKPTHHpBUiX6cl2udnWxHNrSjwOgiXRjcaC+ZcH10ryAhZ7oJVu
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Orange Pi Zero2 the AXP305 DCDCC "vdd-gpu-sys" rail feeds both
the Mali-G31 and the SoC's VDD-SYS domain, which includes the video
engine. Its regulator range starts at 810 mV, the lowest GPU operating
point, so once GPU DVFS is enabled the rail drops to 810 mV whenever
the GPU is idle. The video engine does not tolerate that: with the VE
at 600 MHz, 4K H.265 decodes intermittently produce a few corrupted
CTBs, without any kernel message. Only 6 of 13 runs were bit-exact at
810 mV, against 3 of 3 at 890 mV, 3 of 3 at 950 mV, and 3 of 3 at
810 mV with the VE clocked down to 432 MHz. The vendor BSP runs every
GPU operating point at 950 mV, so it never lowers this rail.

Raise the regulator minimum to 900 mV before GPU DVFS is enabled. The
H616 GPU operating points use <target min max> triplets with a 990 mV
maximum, so the regulator core clamps the low-frequency requests into
[900, 990] mV and devfreq still scales the GPU clock.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index 1fdf2d3c1a87..719d6dadf7bf 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -114,7 +114,7 @@ reg_dcdca: dcdca {
 
 			reg_dcdcc: dcdcc {
 				regulator-always-on;
-				regulator-min-microvolt = <810000>;
+				regulator-min-microvolt = <900000>;
 				regulator-max-microvolt = <990000>;
 				regulator-name = "vdd-gpu-sys";
 			};

-- 
2.55.0

