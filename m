From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Sun, 22 Nov 2026 08:44:12 -0800
Subject: [PATCH] board: microsoft: surface-rt: clear VDDCTRL EN1 assignment
 before enabling VDD_CPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-surface-rt-en1-vddctrl-v1-1-2e60fd8db38b@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAyA4VeRnBdoI4jbq4wdujZqxugkqTIQ3
 32dHr/D/29grMIGt2YD5VVMPrnCXxqIU8gjo6RqIEed90Roiw4hMmpBzh7XlGLRN15D27eOXAo
 dQY1n5UG+x/j+OG3L88Wx/G+w7z/vymkMegAAAA==
X-Change-ID: 20261122-surface-rt-en1-vddctrl-9a383020da62
To: u-boot@lists.u-boot-project.org
Cc: =?utf-8?q?Jonas_Schw=C3=B6bel?= <jonasschwoebel@yahoo.de>, 
 Tom Rini <trini@konsulko.com>, Svyatoslav Ryhel <clamor95@gmail.com>, 
 Thierry Reding <treding@nvidia.com>, 
 Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2852;
 i=jerome.berclaz@proton.me; h=from:subject:message-id;
 bh=HSSoZSlKsMYdiGqKvQP5da+Ymx6Ab63Lv8j3V4haIKo=;
 b=kA0DAAoWM75tse0VEHIByyZiAGsDG+2hmHUaxGcon9ES7d3E49QJCcU+TmNUHMG2cx79255VU
 Yh1BAAWCgAdFiEEBYAxZZ/IBlBxL57CM75tse0VEHIFAmsDG+0ACgkQM75tse0VEHIizQD/bqV0
 Xpo/k2a6Qz7+daJRQGl/xVotm9grmWNd08e/ZpMBANZeBzAtjHlqr0Pz6CECMeQ4kkfJ7+Fel36
 3IUCMopcK
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/default with auth_id=1608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Linux's tps65910 regulator driver assigns the CPU rail (TPS65911 VDDCTRL)
to the EN1 input, which is driven by the Tegra CPU_PWR_REQ signal, with a
0 V sleep voltage. A PMC warm reset (PMC_CNTRL MAIN_RST, used for example
to reboot into RCM) does not reset the PMIC, so U-Boot and the next kernel
start with that assignment still active instead of the cold boot state.
About half of such boots then hung right after "Starting kernel...", with
no output from the kernel.

Clear EN1_SMPS_ASS before setting up VDD_CPU, so every boot starts from
the same PMIC state as a cold boot. Linux assigns the external controls
again when the regulator driver probes. The SPL I2C helper can only write,
so the whole register is cleared; on the Surface RT only VDDCTRL is
assigned to EN1.

Tested on a Surface RT: 6 consecutive PMC warm-reset boots with U-Boot
loaded over RCM all reached userspace (about half hung before), and LP1
suspend still works afterwards. Normal reboots go through the PMIC restart
handler and were not affected.

The problem was investigated, and this change and its description written,
with the help of an AI coding assistant (Claude); I reviewed the change and
tested it on my device as described above.

Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
Sent here as suggested on the libre-tegra tracker:
https://codeberg.org/libre-tegra/u-boot/pulls/8
---
 board/microsoft/surface-rt/surface-rt-spl.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/board/microsoft/surface-rt/surface-rt-spl.c b/board/microsoft/surface-rt/surface-rt-spl.c
index f327a80ef..7a8c38395 100644
--- a/board/microsoft/surface-rt/surface-rt-spl.c
+++ b/board/microsoft/surface-rt/surface-rt-spl.c
@@ -18,6 +18,8 @@
 #define TPS65911_VDDCTRL_SR_REG		0x27
 #define TPS65911_VDDCTRL_OP_DATA	(0x2400 | TPS65911_VDDCTRL_OP_REG)
 #define TPS65911_VDDCTRL_SR_DATA	(0x0100 | TPS65911_VDDCTRL_SR_REG)
+#define TPS65911_EN1_SMPS_ASS_REG	0x46
+#define TPS65911_EN1_SMPS_ASS_DATA	(0x0000 | TPS65911_EN1_SMPS_ASS_REG)
 
 #define TPS62361B_I2C_ADDR		(0x60 << 1)
 #define TPS62361B_SET3_REG		0x03
@@ -30,6 +32,14 @@ void pmic_enable_cpu_vdd(void)
 
 	udelay(1000);
 
+	/*
+	 * Linux assigns VDDCTRL to the EN1 input (CPU_PWR_REQ) with a 0 V
+	 * sleep voltage. A PMC warm reset does not reset the PMIC, so drop
+	 * that assignment to start from the same state as a cold boot.
+	 */
+	tegra_i2c_ll_write(TPS65911_I2C_ADDR, TPS65911_EN1_SMPS_ASS_DATA);
+	udelay(1000);
+
 	/*
 	 * Bring up CPU VDD via the TPS65911x PMIC on the DVC I2C bus.
 	 * First set VDD to 1.0125V, then enable the VDD regulator.

---
base-commit: e578056c766d653270b14557c2a9d8daec414c17
change-id: 20261122-surface-rt-en1-vddctrl-9a383020da62

Best regards,
--  
Jerome Berclaz <jerome.berclaz@proton.me>

