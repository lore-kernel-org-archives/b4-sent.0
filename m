From: Rex Fu <Rex.Fu@amd.com>
Date: Mon, 18 May 2026 18:00:40 +0800
Subject: [PATCH v2] ARM: dts: aspeed: anacapa: correct SGPIO names for
 monitoring
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-anacapa-sgpio-edsff-thermtrip-v2-1-e43b1847b2dc@amd.com>
X-B4-Tracking: v=1; b=H4sIAEfjCmoC/42OSwrCMBRFt1Iy9kmSfhRH7kM6yOelfUKbkMSgl
 O7dtm7A4YHDuXdhCSNhYrdqYRELJfLzBvJUMTOqeUAguzGTXHa8qTmoWRkVFKQhkAe0yTnII8Y
 pRwqgjJbyql0nNLKtESI6eh/9R//j9NJPNHmP7sZIKfv4OQ4UsXv/bhUBAqSzLV5kU7eW39Vkz
 8ZPrF/X9QvqpmBx2gAAAA==
X-Change-ID: 20260430-anacapa-sgpio-edsff-thermtrip-acb228bf61be
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Rex Fu <Rex.Fu@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779098465; l=4551;
 i=Rex.Fu@amd.com; s=20260417; h=from:subject:message-id;
 bh=R6pEDyauTB50Fmhvxn0QsYGtV2og2/4FKpGrDbJds/8=;
 b=RC64u2ytJ72iyOUFotIilIIvQnQwyvi5OfqMn3hKP+rzzxF8q2th+T0U1TtU6hXd+NbgacbZ0
 kRDPXrW5GeECk58Ywm1UgI3Pjx7idCfONhNhX9W2thRQSbad/63mm9J
X-Developer-Key: i=Rex.Fu@amd.com; a=ed25519;
 pk=26ECoh24fxrbXDKgA4hCmgg0xjQ+IxU97kXb46ovwgc=
X-Endpoint-Received: by B4 Relay for Rex.Fu@amd.com/20260417 with auth_id=738
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update several Anacapa SGPIO line names to match the existing platform
hardware design and the signal names consumed by userspace monitoring.

The previous names did not match the actual Anacapa SGPIO usage. Some
lines were named as CPU or CPU power-good signals, but they are wired and
used on Anacapa for EDSFF presence, EDSFF power-good, boot EDSFF
presence, and thermal-trip assertion monitoring.

Correct the mappings as follows:

  PWRGD_PVDDCR_SOC_P0     -> L_PRSNT_EDSFF0_N
  PWRGD_PVDDIO_P0         -> L_PRSNT_EDSFF1_N
  PWRGD_PVDDIO_MEM_S3_P0  -> R_PRSNT_EDSFF2_N
  PWRGD_CHMP_CPU0_FPGA    -> R_PRSNT_EDSFF3_N
  PWRGD_CHIL_CPU0_FPGA    -> HPM_EDSFF_PG
  EAM2_CPU_MOD_PWR_GD_R   -> PRSNT_EDSFF_BOOT_N
  CPU0_SP7R1              -> L_EDSFF0_PG
  CPU0_SP7R2              -> L_EDSFF1_PG
  CPU0_SP7R3              -> R_EDSFF2_PG
  CPU0_SP7R4              -> R_EDSFF3_PG
  HPM_AMC_THERMTRIP_R_L   -> AMC_THERMTRIP_ASSERT
  FM_CPU0_THERMTRIP_N     -> CPU_THERMTRIP_ASSERT

The left-side EDSFF slots are numbered as EDSFF0 and EDSFF1 to match
the platform slot numbering used by userspace. The thermtrip names are
also updated to describe the asserted condition monitored by userspace
instead of the raw active-low signal names.

This is a naming correction for the existing Anacapa hardware design.
There is no new board revision or underlying hardware change involved.

Signed-off-by: Rex Fu <Rex.Fu@amd.com>
---
Update the Anacapa SGPIO line names to match the existing hardware
design and the platform signal names used by userspace monitoring.

The v2 commit message now explains why changing these userspace-visible
GPIO line names is appropriate and lists the exact old-to-new mappings.
---
Changes in v2:
- Reworked the commit message to explain why these userspace-visible
  GPIO line names are changed.
- Listed the exact old-to-new SGPIO line name mappings.
- Clarified that this is a naming correction for the existing hardware
  design and not a board revision or hardware change.
- Link to v1: https://patch.msgid.link/20260430-anacapa-sgpio-edsff-thermtrip-v1-1-2fd5e72435d0@amd.com

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Joel Stanley <joel@jms.id.au>
To: Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-aspeed@lists.ozlabs.org
Cc: linux-kernel@vger.kernel.org
---
 .../boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts  | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..e898bc11e6f5 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -908,11 +908,11 @@ &sgpiom0 {
 	"", "", "", "",
 
 	/* G0-G7 line 96-111 */
-	"PWRGD_PVDDCR_SOC_P0", "",
-	"PWRGD_PVDDIO_P0", "",
-	"PWRGD_PVDDIO_MEM_S3_P0", "",
-	"PWRGD_CHMP_CPU0_FPGA", "",
-	"PWRGD_CHIL_CPU0_FPGA", "",
+	"L_PRSNT_EDSFF0_N", "",
+	"L_PRSNT_EDSFF1_N", "",
+	"R_PRSNT_EDSFF2_N", "",
+	"R_PRSNT_EDSFF3_N", "",
+	"HPM_EDSFF_PG", "",
 	"PWRGD_CHEH_CPU0_FPGA", "",
 	"PWRGD_CHAD_CPU0_FPGA", "FM_BMC_READY_PLD",
 	"", "",
@@ -934,7 +934,7 @@ &sgpiom0 {
 	"EAM3_BRD_PRSNT_R_L", "",
 	"EAM0_CPU_MOD_PWR_GD_R", "",
 	"EAM1_CPU_MOD_PWR_GD_R", "",
-	"EAM2_CPU_MOD_PWR_GD_R", "",
+	"PRSNT_EDSFF_BOOT_N", "",
 	"EAM3_CPU_MOD_PWR_GD_R", "",
 
 	/* J0-J7 line 144-159 */
@@ -957,8 +957,8 @@ &sgpiom0 {
 	"PDB_ALERT_R_N", "",
 
 	/* L0-L7 line 176-191 */
-	"CPU0_SP7R1", "", "CPU0_SP7R2", "",
-	"CPU0_SP7R3", "", "CPU0_SP7R4", "",
+	"L_EDSFF0_PG", "", "L_EDSFF1_PG", "",
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

