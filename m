From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 21 Nov 2026 10:30:21 +0100
Subject: [PATCH 2/3] power: supply: smb347: Make the APSD and AICL
 registers readable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-upstream-smb347-apsd-v1-2-ca46b92bfd44@tsv-stahl-riesa.de>
References: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
In-Reply-To: <20261121-upstream-smb347-apsd-v1-0-ca46b92bfd44@tsv-stahl-riesa.de>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Dmitry Osipenko <digetx@gmail.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Bruce Robertson <brucer42@gmail.com>, 
 =?utf-8?q?Martin_J=C3=BCcker?= <martin.juecker@gmail.com>, 
 Mithil Bavishi <bavishimithil@gmail.com>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795253429; l=2425;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=qo/m+YK2xUxKc3Lw/oUCa6pEdiiFJLNVhUkFo+v1kq0=;
 b=Aa8mbgRF9MIDgIuMhXTKajcLZsAjFkfhCso+OP8Itmcc/LiaMaG5VI6qKO0LtLR0b319+P/su
 N6x6ZPiJhzcAWju/kaToJiGtDjYCptW1nTX9uCi11hK6/OAcOfXMTLO
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The charger has a few registers that the driver does not list as
readable yet:

  0x02  CFG_VARIOUS_FUNCTION  includes the AICL enable bit
  0x04  CFG_CHARGE_CONTROL    includes the APSD enable bit
  0x3e  STAT_D                automatic power source detection result

The bit assignments are taken from the Android 3.1 kernel for the
Nexus 7 (2012), drivers/power/smb347-charger.c in the
android-tegra3-grouper-3.1-lollipop-release branch of
https://android.googlesource.com/kernel/tegra.

Add them to the readable registers. STAT_D reflects the state of the
input and is volatile. The other two are configuration registers like
the ones the driver already caches.

This makes them visible in the regmap debugfs and prepares for using
the detected charger type to set the USB input current limit.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/power/supply/smb347-charger.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/power/supply/smb347-charger.c b/drivers/power/supply/smb347-charger.c
index 72dfa15b3d80..03d58b378a25 100644
--- a/drivers/power/supply/smb347-charger.c
+++ b/drivers/power/supply/smb347-charger.c
@@ -43,10 +43,12 @@
 #define CFG_CURRENT_LIMIT_DC_MASK		0xf0
 #define CFG_CURRENT_LIMIT_DC_SHIFT		4
 #define CFG_CURRENT_LIMIT_USB_MASK		0x0f
+#define CFG_VARIOUS_FUNCTION			0x02
 #define CFG_FLOAT_VOLTAGE			0x03
 #define CFG_FLOAT_VOLTAGE_FLOAT_MASK		0x3f
 #define CFG_FLOAT_VOLTAGE_THRESHOLD_MASK	0xc0
 #define CFG_FLOAT_VOLTAGE_THRESHOLD_SHIFT	6
+#define CFG_CHARGE_CONTROL			0x04
 #define CFG_STAT				0x05
 #define CFG_STAT_DISABLED			BIT(5)
 #define CFG_STAT_ACTIVE_HIGH			BIT(7)
@@ -128,6 +130,7 @@
 #define STAT_C_CHG_SHIFT			1
 #define STAT_C_CHG_TERM				BIT(5)
 #define STAT_C_CHARGER_ERROR			BIT(6)
+#define STAT_D					0x3e
 #define STAT_E					0x3f
 
 #define SMB347_MAX_REGISTER			0x3f
@@ -1199,6 +1202,7 @@ static bool smb347_volatile_reg(struct device *dev, unsigned int reg)
 	case STAT_A:
 	case STAT_B:
 	case STAT_C:
+	case STAT_D:
 	case STAT_E:
 		return true;
 	}
@@ -1211,7 +1215,9 @@ static bool smb347_readable_reg(struct device *dev, unsigned int reg)
 	switch (reg) {
 	case CFG_CHARGE_CURRENT:
 	case CFG_CURRENT_LIMIT:
+	case CFG_VARIOUS_FUNCTION:
 	case CFG_FLOAT_VOLTAGE:
+	case CFG_CHARGE_CONTROL:
 	case CFG_STAT:
 	case CFG_PIN:
 	case CFG_THERM:

-- 
2.56.1

