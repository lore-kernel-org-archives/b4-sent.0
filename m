From: Rex Fu <Rex.Fu@amd.com>
Date: Thu, 30 Apr 2026 13:44:28 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: name EDSFF and thermtrip SGPIO
 lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-anacapa-sgpio-edsff-thermtrip-v1-1-2fd5e72435d0@amd.com>
X-B4-Tracking: v=1; b=H4sIADvs8mkC/yXMwQrCMAwA0F8ZORvoqgzxV8RD2qVbBLuSVBHG/
 n2dHt/lrWCswga3bgXlj5gsuaE/dRBnyhOjjM3gnR/c5eyQMkUqhDYVWZBHSwnrzPqqKgUpBu+
 vIQ19YGhHUU7y/f33x9/2Dk+O9Uhh23ZG96kXgQAAAA==
X-Change-ID: 20260430-anacapa-sgpio-edsff-thermtrip-acb228bf61be
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Rex Fu <Rex.Fu@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777527924; l=1868;
 i=Rex.Fu@amd.com; s=20260417; h=from:subject:message-id;
 bh=FKvzsI9xHFmGcGo9UHVCAjhAhv7ytsitasP4Y5ub01A=;
 b=GPiFDR+/ibGE0NwGTxGFGmQdcKyr+YrgZyfg43LrcwIi2ZH7TGSoZmO77kXGMks/g4aHs7xEr
 73Dk+5T4CraD5T71ecP2h9D4jP6C68jM1Nj8r/ozRB7Hvh1j+k7MeL/
X-Developer-Key: i=Rex.Fu@amd.com; a=ed25519;
 pk=26ECoh24fxrbXDKgA4hCmgg0xjQ+IxU97kXb46ovwgc=
X-Endpoint-Received: by B4 Relay for Rex.Fu@amd.com/20260417 with auth_id=738
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Name the Anacapa SGPIO lines used for EDSFF power-good and thermtrip
assertion signals.

The affected lines replace legacy or unused CPU-related names with the
platform signal names used by userspace monitoring.

Signed-off-by: Rex Fu <Rex.Fu@amd.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..fe960bb7bc27 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -912,7 +912,7 @@ &sgpiom0 {
 	"PWRGD_PVDDIO_P0", "",
 	"PWRGD_PVDDIO_MEM_S3_P0", "",
 	"PWRGD_CHMP_CPU0_FPGA", "",
-	"PWRGD_CHIL_CPU0_FPGA", "",
+	"HPM_EDSFF_PG", "",
 	"PWRGD_CHEH_CPU0_FPGA", "",
 	"PWRGD_CHAD_CPU0_FPGA", "FM_BMC_READY_PLD",
 	"", "",
@@ -957,8 +957,8 @@ &sgpiom0 {
 	"PDB_ALERT_R_N", "",
 
 	/* L0-L7 line 176-191 */
-	"CPU0_SP7R1", "", "CPU0_SP7R2", "",
-	"CPU0_SP7R3", "", "CPU0_SP7R4", "",
+	"L_EDSFF2_PG", "", "L_EDSFF3_PG", "",
+	"R_EDSFF2_PG", "", "R_EDSFF3_PG", "",
 	"CPU0_CORETYPE0", "", "CPU0_CORETYPE1", "",
 	"CPU0_CORETYPE2", "", "FM_BIOS_POST_CMPLT_R_N", "",
 
@@ -984,8 +984,8 @@ &sgpiom0 {
 	"HPM_PWR_FAIL", "Port80_b0",
 	"FM_DIMM_IP_FAIL", "Port80_b1",
 	"FM_DIMM_AH_FAIL", "Port80_b2",
-	"HPM_AMC_THERMTRIP_R_L", "Port80_b3",
-	"FM_CPU0_THERMTRIP_N", "Port80_b4",
+	"AMC_THERMTRIP_ASSERT", "Port80_b3",
+	"CPU_THERMTRIP_ASSERT", "Port80_b4",
 	"PVDDCR_SOC_P0_OCP_L", "Port80_b5",
 	"CPLD_SGPIO_RDY", "Port80_b6",
 	"", "Port80_b7",

---
base-commit: 9974969c14031a097d6b45bcb7a06bb4aa525c40
change-id: 20260430-anacapa-sgpio-edsff-thermtrip-acb228bf61be

Best regards,
--  
Rex Fu <Rex.Fu@amd.com>

