From: David Heidelberg <david@ixit.cz>
Date: Thu, 27 Aug 2026 16:27:41 +0200
Subject: [PATCH] mfd: Fix MAX77705 dependency on regmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260827-deps-reg-max77705-v1-1-c83a74d3d428@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CQAxA4auQrmlSxkAHrkJcjFCxJvxkimYSw
 t0ddfkt3jvAJKoYdMUBUd5qui4ZVVnA8AjLJKhjNjhyDXnHOMpmGGXCOSRmphrJX+rQkm+ZG8j
 dFuWu6ffsr3/b6/aUYf+O4Dw/ONQoLnUAAAA=
X-Change-ID: 20260827-deps-reg-max77705-0835a9089776
To: Lee Jones <lee@kernel.org>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, stable@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1508; i=david@ixit.cz;
 h=from:subject:message-id; bh=QX7JkiZbHlW0D55dPU0RlQr972FkBkLXUTJRO6pdqeY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqkElknuZIm/NYkZXg7Xt2bid7sZ6JEAFx+AMRt
 PXGnID3HHaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapBJZAAKCRBgAj/E00kg
 chMOEACpS6o4pAozT1WKpIs7KcZyTvKxndxnrZpXi1iGLUPhkGd5dU0GZoiOEk+D5iyY50emJvR
 nw9iLvGZn2TyTgtQzB18XwMVPxUlv6DBYvoR2shXdxRxF5Rll8jh0PCxLPOeT82XOUsudOXmc6B
 1vBGgiCMc8SbRBTw0zK9CLfyKZfUGubRlKxMeNJbgf1MmJh026Pil2SSxNIDQnLH2MVmVmJQzEv
 w5alpjNGPM6T+TIqeBIUoTuZupSHihh4sQTT7OGm7vfHp3IU8BOGqHfFlZRBU3hE/9YaPHsReyL
 NPIFv83r1s1ylog3+sThQItEyqPrJfQH7YCrDT18yYkCeU3hE9+dWWbbf1ujQJvxA17A25u3yjo
 F7pFiz3y/OBO0c8G2XoDnlcDbbenW60rKAPj+mKW6aL7qy5oJ6us/GYM8VNImtA/VFhDMPOT1AF
 R87hOY7D1WRvpeBvGL+7KmwsT2GPkcRksmjqa6avPJC60w83i4dcUuloDoOJoy/bSdjS7f9ROiV
 kQJmPI6l9RmJBpsER/lXnxcTYACTJldjwY9+ATB2ZADpWVrmcseYjD8eMWnQBjVSpavYm4BNyqt
 7RlSi0i+Uzv915slto0Y7TWUU7PUpJbUDD+ALd+Du11DSVUi2qajmCnE4yyxx0GkwhIgYE95/29
 ffzu6KRdQQwYyRQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The max77705 uses devm_regmap_add_irq_chip(), so add REGMAP_IRQ
and REGMAP_I2C to what the core driver selects in order to provide
thise APIs.
This fixes a build error:

drivers/mfd/max77705.o: in function `max77705_i2c_probe':
max77705.c:(.text+0x250): undefined reference to `devm_regmap_add_irq_chip'

Cc: stable@vger.kernel.org
Fixes: c8d50f029748 ("mfd: Add new driver for MAX77705 PMIC")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/mfd/Kconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/mfd/Kconfig b/drivers/mfd/Kconfig
index e4fd4572472f9..857ca3bb0d5bf 100644
--- a/drivers/mfd/Kconfig
+++ b/drivers/mfd/Kconfig
@@ -1001,16 +1001,18 @@ config MFD_MAX77693
 	  additional drivers must be enabled in order to use the functionality
 	  of the device.
 
 config MFD_MAX77705
 	tristate "Maxim MAX77705 PMIC Support"
 	depends on I2C
 	select MFD_CORE
 	select MFD_SIMPLE_MFD_I2C
+	select REGMAP_I2C
+	select REGMAP_IRQ
 	help
 	  Say yes here to add support for Maxim Integrated MAX77705 PMIC.
 	  This is a Power Management IC with Charger, safe LDOs, Flash, Haptic
 	  and MUIC controls on chip.
 	  This driver provides common support for accessing the device;
 	  additional drivers must be enabled in order to use the functionality
 	  of the device.
 

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260827-deps-reg-max77705-0835a9089776

Best regards,
--  
David Heidelberg <david@ixit.cz>

