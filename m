From: Colin Huang <u8813345@gmail.com>
Date: Tue, 02 Jun 2026 21:25:02 +0800
Subject: [PATCH v3 7/9] ARM: dts: aspeed: anacapa: Align PDB fan GPIO
 numbering
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-anacapa-devlop-phase-devicetree-v3-7-7c93c5df8d9b@gmail.com>
References: <20260602-anacapa-devlop-phase-devicetree-v3-0-7c93c5df8d9b@gmail.com>
In-Reply-To: <20260602-anacapa-devlop-phase-devicetree-v3-0-7c93c5df8d9b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Rex Fu <rex.fu.amd@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780406700; l=2161;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=gT219DNuHxVGx46EEdxGOjRGMVdr1IWCg5Am0KC7qdQ=;
 b=GzMK2oG6vuFeC3uQWCKA8E6WjSBtprj2by4f31yoAWzXwveSQgkzHLNUkL2Th9P3LQzVQ9201
 eD4oRty2efECbLfuHWorPxbBgoqF1Fb2jyuPY65OMkdD3vHvGOIO5NF
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Rex Fu <rex.fu.amd@gmail.com>

Update the LPDB and RPDB fan GPIO line names to align with the platform
fan numbering scheme.

The LPDB fan GPIOs are named FAN0 through FAN4, while the RPDB fan GPIOs
are named FAN5 through FAN8. This keeps the GPIO line names consistent
with the fan inventory and platform-level fan numbering.

Signed-off-by: Rex Fu <rex.fu.amd@gmail.com>
---
 .../dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts  | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
index c703d64edfae..29df10697613 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
@@ -510,11 +510,11 @@ gpio@24 {
 					"RPDB_EAM2_PRSNT_MOS_N_R", "RPDB_EAM3_PRSNT_MOS_N_R",
 					"RPDB_PWRGD_P50V_HSC4_SYS_R",
 					"RPDB_PWRGD_P50V_STBY_SYS_BUF_R",
-					"RPDB_P50V_FAN1_R2_PG", "RPDB_P50V_FAN2_R2_PG",
-					"RPDB_P50V_FAN3_R2_PG", "RPDB_P50V_FAN4_R2_PG",
-					"", "RPDB_FAN1_PRSNT_N_R",
-					"", "RPDB_FAN2_PRSNT_N_R",
-					"RPDB_FAN3_PRSNT_N_R", "RPDB_FAN4_PRSNT_N_R",
+					"RPDB_P50V_FAN5_R2_PG", "RPDB_P50V_FAN6_R2_PG",
+					"RPDB_P50V_FAN7_R2_PG", "RPDB_P50V_FAN8_R2_PG",
+					"", "RPDB_FAN5_PRSNT_N_R",
+					"", "RPDB_FAN6_PRSNT_N_R",
+					"RPDB_FAN7_PRSNT_N_R", "RPDB_FAN8_PRSNT_N_R",
 					"", "";
 			};
 
@@ -559,11 +559,11 @@ gpio@24 {
 				interrupts = <174 IRQ_TYPE_LEVEL_LOW>;
 
 				gpio-line-names =
-					"LPDB_P50V_FAN1_R2_PG","LPDB_P50V_FAN2_R2_PG",
-					"LPDB_P50V_FAN3_R2_PG","LPDB_P50V_FAN4_R2_PG",
-					"LPDB_P50V_FAN5_R2_PG","LPDB_FAN1_PRSNT_N_R",
-					"LPDB_FAN2_PRSNT_N_R","LPDB_FAN3_PRSNT_N_R",
-					"LPDB_FAN4_PRSNT_N_R","LPDB_FAN5_PRSNT_N_R",
+					"LPDB_P50V_FAN0_R2_PG","LPDB_P50V_FAN1_R2_PG",
+					"LPDB_P50V_FAN2_R2_PG","LPDB_P50V_FAN3_R2_PG",
+					"LPDB_P50V_FAN4_R2_PG","LPDB_FAN0_PRSNT_N_R",
+					"LPDB_FAN1_PRSNT_N_R","LPDB_FAN2_PRSNT_N_R",
+					"LPDB_FAN3_PRSNT_N_R","LPDB_FAN4_PRSNT_N_R",
 					"","",
 					"","",
 					"","";

-- 
2.34.1

