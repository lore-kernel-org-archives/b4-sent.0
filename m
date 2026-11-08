From: Igor Velkov <iav@iav.lv>
Date: Sun, 08 Nov 2026 22:02:51 +0000
Subject: [PATCH] arm64: dts: rockchip: Enable all CPU OPPs on Kobol
 Helios64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-helios64-cpu-opps-v1-1-31aa4afb7eb8@iav.lv>
X-B4-Tracking: v=1; b=H4sIAIrx8GoC/x3MMQqAMAxA0atIZgONSBGvIg5aUxsQWxoUQXp3i
 +Mb/n9BOQsrjM0LmW9RiWcFtQ24sJw7o2zV0JnOEpkBAx8S1fbo0oUxJcVhWTfr2ZI3BLVLmb0
 8/3OaS/kA9iWdAWMAAAA=
To: Heiko Stuebner <heiko@sntech.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2693; i=iav@iav.lv;
 h=from:subject:message-id; bh=edWxjml98aK3nfS7bKrBTOBhCYbn9/aBY4i4ZQTEi+w=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkfPvbcO3oyY5n4PY38eIPUy4H8X5MyS+d79cz2eHWCP
 17kCeOMjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCR4ixGhsaSmH//uleGmGUJ
 yaTNFvHkY1ad/Orxue5HHBKbHlU/TGT4X7nt5sT5M9OYOcROTH2ybdsZu3uB3Pb/jjlpVM2ZczD
 wKRsA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Helios64 device tree deletes the lower OPPs of both CPU clusters
because the board was not stable with cpufreq.

With all OPPs and regulator-ramp-delay = <1000> on vdd_cpu_b, the board
hung about 9.5 s into boot both times we tried. With 40000 it ran 40
boots and three one-hour DVFS runs under load without errors. We did not
find out why the slower ramp hangs.

40000 selects the slew rate we read from the regulator in U-Boot after a
cold start, 64 mV/us; 1000 slows it down.

Restore the OPPs and raise the ramp delay.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Linux 7.3 and its device tree, with the U-Boot and the .config
of Armbian. The PCIe host driver was not loaded: on this board it takes
an external abort at probe on some boots, with or without this change
(about 5% of boots with it, 1 of 4 without). One boot with it loaded
brought the link up, without DVFS load.

Besides the boots and runs above: one hour each of schedutil under
bursty load and of switching only one cluster.

Ramp delay scan with all OPPs: 2000 hung twice in 5 boots (once at boot,
once on reboot after an hour under load), 8000 passed 13 of 13 boots,
32000 passed 3 of 3.
---
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 24 +---------------------
 1 file changed, 1 insertion(+), 23 deletions(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
index f13ea2df7a30..f2f900f576a0 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-kobol-helios64.dts
@@ -354,28 +354,6 @@ vdd_log: regulator-vdd-log {
 	};
 };
 
-/*
- * The system doesn't run stable with cpu freq enabled, so disallow the lower
- * frequencies until this problem is properly understood and resolved.
- */
-&cluster0_opp {
-	/delete-node/ opp00;
-	/delete-node/ opp01;
-	/delete-node/ opp02;
-	/delete-node/ opp03;
-	/delete-node/ opp04;
-};
-
-&cluster1_opp {
-	/delete-node/ opp00;
-	/delete-node/ opp01;
-	/delete-node/ opp02;
-	/delete-node/ opp03;
-	/delete-node/ opp04;
-	/delete-node/ opp05;
-	/delete-node/ opp06;
-};
-
 &cpu_b0 {
 	cpu-supply = <&vdd_cpu_b>;
 };
@@ -542,7 +520,7 @@ vdd_cpu_b: regulator@40 {
 		regulator-boot-on;
 		regulator-min-microvolt = <712500>;
 		regulator-max-microvolt = <1500000>;
-		regulator-ramp-delay = <1000>;
+		regulator-ramp-delay = <40000>;
 		vin-supply = <&vcc5v0_sys>;
 
 		regulator-state-mem {

---
base-commit: c3baae5f1a15645cddadcb2b9abddef5df291f59
change-id: 20261108-helios64-cpu-opps-8abd6fe61f01

Best regards,
-- 
Igor Velkov <iav@iav.lv>

