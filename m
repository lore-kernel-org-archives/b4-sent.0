From: =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
Date: Fri, 18 Apr 2025 10:43:22 +0200
Subject: [PATCH v2] backlight: ktd2801: depend on GPIOLIB
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-ktd-fix-v2-1-cf3d19bafc9e@skole.hr>
X-B4-Tracking: v=1; b=H4sIAKkQAmgC/2WMQQrCMBAAv1L27EqzNk3w5D+kh2pWs1SakpSgl
 Pzd2KvHGYbZIHEUTnBuNoicJUmYK9Chgbsf5yejuMpALem2Uwqn1eFD3mhGzdrZXpubhVovkav
 eT9ehspe0hvjZx1n97P8jK1TIpiPtyJyot5c0hRcffYShlPIFEY6HN50AAAA=
X-Change-ID: 20250411-ktd-fix-7a5e5d8657b8
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>
Cc: Randy Dunlap <rdunlap@infradead.org>, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Duje_Mihanovi=C4=87?= <duje.mihanovic@skole.hr>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1451;
 i=duje.mihanovic@skole.hr; s=20240706; h=from:subject:message-id;
 bh=NvkEKW66oVkFED6cl1L9OEBr+ZdxEWUqxuIzm2YmzSg=;
 b=owGbwMvMwCW21nBykGv/WmbG02pJDBlMAmvM9CdPb+m7JZzJc36l/CX7loglnypbg2edbVi5o
 1iaJ+xTRykLgxgXg6yYIkvuf8drvJ9Ftm7PXmYAM4eVCWQIAxenAExkUhEjw5fgD3Hzz0zc8MLo
 gWtc3Zd6Zra5ec9b9pWYbhY+WLi5ZTvDX4kC5SNTFrFKbpFLqiif6btkr6KWmuOhaRyi+akfKnp
 usQAA
X-Developer-Key: i=duje.mihanovic@skole.hr; a=openpgp;
 fpr=6DFF41D60DF314B5B76BA630AD319352458FAD03
X-Endpoint-Received: by B4 Relay for duje.mihanovic@skole.hr/20240706 with auth_id=191
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ExpressWire library used by the driver depends on GPIOLIB, and by
extension the driver does as well. This is not reflected in the driver's
Kconfig entry, potentially causing Kconfig warnings. Fix this by adding
the dependency.

Closes: https://lore.kernel.org/all/5cf231e1-0bba-4595-9441-46acc5255512@infradead.org
Reported-by: Randy Dunlap <rdunlap@infradead.org>
Tested-by: Randy Dunlap <rdunlap@infradead.org>
Acked-by: Randy Dunlap <rdunlap@infradead.org>
Signed-off-by: Duje Mihanović <duje.mihanovic@skole.hr>
---
Changes in v2:
- s/Link/Closes
- Pull Randy's tags
- Link to v1: https://lore.kernel.org/r/20250411-ktd-fix-v1-1-e7425d273268@skole.hr
---
 drivers/video/backlight/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/video/backlight/Kconfig b/drivers/video/backlight/Kconfig
index d9374d208ceebbf8b3c27976e9cb4d725939b942..37341474beb9982f7099711e5e2506081061df46 100644
--- a/drivers/video/backlight/Kconfig
+++ b/drivers/video/backlight/Kconfig
@@ -185,6 +185,7 @@ config BACKLIGHT_KTD253
 
 config BACKLIGHT_KTD2801
 	tristate "Backlight Driver for Kinetic KTD2801"
+	depends on GPIOLIB || COMPILE_TEST
 	select LEDS_EXPRESSWIRE
 	help
 	  Say Y to enable the backlight driver for the Kinetic KTD2801 1-wire

---
base-commit: 01c6df60d5d4ae00cd5c1648818744838bba7763
change-id: 20250411-ktd-fix-7a5e5d8657b8

Best regards,
-- 
Duje Mihanović <duje.mihanovic@skole.hr>

