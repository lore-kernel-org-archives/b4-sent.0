From: George Chan <gchan9527@gmail.com>
Date: Tue, 20 May 2025 22:25:59 +0800
Subject: [PATCH 4/4] usb: gadget: Introduce usb gadget vendor/product
 default id for ARCH_QCOM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250520-sc7180-android-boot-v1-4-3075a84ea094@gmail.com>
References: <20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com>
In-Reply-To: <20250520-sc7180-android-boot-v1-0-3075a84ea094@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747751157; l=1027;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=GqK0WVCZk8iWoMSZ7t6DB+MXl/Suedu5OgUA7VOZdkY=;
 b=m75ZHwpBDrOXQt1BQ50jI8/9zrWEC9EUDQZdwngm3zUNOOwTQ2DkkUCwIe4W7b4vicYBdMjfU
 FXj3aaPGzyADmeiGCpyDTgI1VgzxgkSCnteYRiycvCONtJDfU/fDSjR
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently vendor/product id are both 0, and that might not as we want.
Set to some arbitary known value that we can make it work more smoothly.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/usb/gadget/Kconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/gadget/Kconfig b/drivers/usb/gadget/Kconfig
index 46a83141481..2a56e360b5f 100644
--- a/drivers/usb/gadget/Kconfig
+++ b/drivers/usb/gadget/Kconfig
@@ -60,6 +60,7 @@ config USB_GADGET_VENDOR_NUM
 	default 0x0955 if ARCH_TEGRA
 	default 0x1f3a if ARCH_SUNXI
 	default 0x2207 if ARCH_ROCKCHIP
+	default 0x18d1 if ARCH_QCOM
 	default 0x0
 	help
 	  Vendor ID of the USB device emulated, reported to the host device.
@@ -86,6 +87,7 @@ config USB_GADGET_PRODUCT_NUM
 	default 0x350a if ROCKCHIP_RK3568
 	default 0x350b if ROCKCHIP_RK3588
 	default 0x350c if ROCKCHIP_RK3528
+	default 0x4ee0 if ARCH_QCOM
 	default 0x0
 	help
 	  Product ID of the USB device emulated, reported to the host device.

-- 
2.43.0

