From: George Chan <gchan9527@gmail.com>
Date: Tue, 21 Oct 2025 00:23:59 +0800
Subject: [PATCH 2/2] usb: gadget: Introduce usb gadget vendor/product
 default id for ARCH_QCOM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-sc7180-minor-v1-2-9fe33c73365e@gmail.com>
References: <20251021-sc7180-minor-v1-0-9fe33c73365e@gmail.com>
In-Reply-To: <20251021-sc7180-minor-v1-0-9fe33c73365e@gmail.com>
To: u-boot@lists.denx.de
Cc: George Chan <gchan9527@gmail.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760977468; l=1201;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=ldgJNz2wHJliI43avdl9F3gBvhVbCT7sU2a1+PlLkQc=;
 b=yzwIYFFhQ1s/v9g4wNlMCn99XpUcUK5n3AxzYTZVS/XFBa4kw2ryZF57xIvV34V+KnzRiwQKD
 fxbVWxXiulgBX2efE9WwRLVwlxyC3OQnpLVfpxZQbz3ssR+GyYIRELc
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently vendor/product id are both 0, and that might not as we want.
Set to some arbitary known value that we can make it work more smoothly.

Reviewed-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Acked-by: Mattijs Korpershoek <mkorpershoek@kernel.org>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/usb/gadget/Kconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/gadget/Kconfig b/drivers/usb/gadget/Kconfig
index e845e46e0b7..008f8c99a58 100644
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
@@ -87,6 +88,7 @@ config USB_GADGET_PRODUCT_NUM
 	default 0x350b if ROCKCHIP_RK3588
 	default 0x350c if ROCKCHIP_RK3528
 	default 0x350e if ROCKCHIP_RK3576
+	default 0x4ee0 if ARCH_QCOM
 	default 0x0
 	help
 	  Product ID of the USB device emulated, reported to the host device.

-- 
2.43.0

