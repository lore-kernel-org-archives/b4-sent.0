From: Samuel Herdman <lk.gzpc0@passmail.com>
Date: Sat, 14 Nov 2026 20:37:11 +1100
Subject: [PATCH] hwmon: (nct6683) Add customer ID for ASRock X600DC-ITX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-nct6683-asrock-x600dc-itx-v1-1-cbccf1a627fe@passmail.com>
X-B4-Tracking: v=1; b=H4sIAMYr+GoC/yXMSw7CMAwA0atUXmMpbkr4XAWxaB0DBilFcUCRq
 t6dAMu3mFnAJKsYHLsFsrzVdE4NtOmAb2O6Cmpsht71gYgGTFxC2HscLc/8wBqci4xaKvpIu2l
 wh+i3Hlr/zHLR+nufzn/ba7oLl+8Q1vUDqnQOyX0AAAA=
X-Change-ID: 20261114-nct6683-asrock-x600dc-itx-3d17b409d353
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Dahlin <jdahlin@gmail.com>, 
 Samuel Herdman <lk.gzpc0@passmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794649030; l=3221;
 i=lk.gzpc0@passmail.com; s=linux-kernel-email; h=from:subject:message-id;
 bh=r00174raxcwNDJ0unlfuiA9FEN/TRz6+o/AOvvcTaUE=;
 b=r/OEHth9ckNwibOkJ4agSSH0EI4C5VV6R/ALYCm8m8Mc4qhxhGiCaD8JxZVzYX7weoH7ZenUu
 DPTXBRBQ7lxA8ovEtGlACvNNRP4QcttEk0GCMTOxvzTvD2l1tH/7fdp
X-Developer-Key: i=lk.gzpc0@passmail.com; a=ed25519;
 pk=tqivbAq+N5SMZTlmU8VfcD5yzezM4r5J8zXeFSl+KIE=
X-Endpoint-Received: by B4 Relay for lk.gzpc0@passmail.com/linux-kernel-email with auth_id=1519
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASRock X600DC-ITX (BIOS 2.02) has an NCT6686D with customer ID
0x165f, which the driver does not know, so it only binds with force=1:

  nct6683: Found NCT6686D or compatible chip at 0x2e:0xa20
  nct6683 nct6683.2592: Enabling support for unknown customer ID 0x165f
  nct6683 nct6683.2592: NCT6686D EC firmware version 1.0 build 12/23/25

The change:

Add the customer ID so the driver binds on this board without force=1,
and add the board to the list of tested boards.

Tests:

- With force=1 the readings are plausible: the CPU temperature (AMD TSI
  Addr 98h) is within a few degrees of k10temp's Tctl, VCC, VSB and
  AVSB read 3.36 V, VBAT reads 3.2 V, and fan1 reads about 1450 RPM.
- With the same change applied to v7.3.3 on this board, the driver
  binds without force=1 and reports temperature and fan readings.

The patch and this changelog were drafted with an AI coding assistant
(Claude Code); I reviewed them and ran the tests above on my board.

Signed-off-by: Samuel Herdman <lk.gzpc0@passmail.com>
---
This overlaps with Johan Dahlin's pending series "hwmon: (nct6683) Fan
control and sensor names for ASRock NCT6686D boards" (v2, 11 Nov 2026).
Its first patch also adds NCT6683_CUSTOMER_ID_ASROCK8 (0x164a) and a
table row at the same spot, and its later patches key fan control on
that macro. Whichever lands second needs its macro renumbered
throughout; I'm happy to rebase on top of that series if preferred.
---
 Documentation/hwmon/nct6683.rst | 1 +
 drivers/hwmon/nct6683.c         | 3 +++
 2 files changed, 4 insertions(+)

diff --git a/Documentation/hwmon/nct6683.rst b/Documentation/hwmon/nct6683.rst
index 62da8fd01..e2e95a33e 100644
--- a/Documentation/hwmon/nct6683.rst
+++ b/Documentation/hwmon/nct6683.rst
@@ -97,6 +97,7 @@ ASRock X570			NCT6683D EC firmware version 1.0 build 06/28/19
 ASRock X670E			NCT6686D EC firmware version 1.0 build 05/19/22
 ASRock B650 Steel Legend WiFi	NCT6686D EC firmware version 1.0 build 11/09/23
 ASRock Z590 Taichi		NCT6686D EC firmware version 1.0 build 01/25/21
+ASRock X600DC-ITX		NCT6686D EC firmware version 1.0 build 12/23/25
 MSI B550			NCT6687D EC firmware version 1.0 build 05/07/20
 MSI B550M			NCT6687D EC firmware version 1.0 build 05/07/20
 MSI B650			NCT6687D EC firmware version 0.0 build 09/27/22
diff --git a/drivers/hwmon/nct6683.c b/drivers/hwmon/nct6683.c
index de5b0194c..01784fa6a 100644
--- a/drivers/hwmon/nct6683.c
+++ b/drivers/hwmon/nct6683.c
@@ -209,6 +209,7 @@ superio_exit(int ioreg)
 #define NCT6683_CUSTOMER_ID_ASROCK5	0x1621
 #define NCT6683_CUSTOMER_ID_ASROCK6	0x1633
 #define NCT6683_CUSTOMER_ID_ASROCK7	0x163d
+#define NCT6683_CUSTOMER_ID_ASROCK8	0x165f
 
 #define NCT6683_REG_BUILD_YEAR		0x604
 #define NCT6683_REG_BUILD_MONTH		0x605
@@ -1640,6 +1641,8 @@ static int nct6683_probe(struct platform_device *pdev)
 		break;
 	case NCT6683_CUSTOMER_ID_ASROCK7:
 		break;
+	case NCT6683_CUSTOMER_ID_ASROCK8:
+		break;
 	default:
 		if (!force)
 			return -ENODEV;

---
base-commit: f9f5501d60c77c71f60bf5b273375e3777d66080
change-id: 20261114-nct6683-asrock-x600dc-itx-3d17b409d353

Best regards,
--  
Samuel Herdman <lk.gzpc0@passmail.com>

