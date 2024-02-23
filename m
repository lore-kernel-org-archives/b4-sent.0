From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 24 Feb 2024 05:43:13 +0800
Subject: [PATCH v2 2/2] usb: dwc3: of-simple: Add compatible for
 hi3798mv200 DWC3 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-dwc3-v2-2-8e4fcd757175@outlook.com>
References: <20240224-dwc3-v2-0-8e4fcd757175@outlook.com>
In-Reply-To: <20240224-dwc3-v2-0-8e4fcd757175@outlook.com>
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yang Xiwen <forbidden405@foxmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708724592; l=809;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=CsDB1ujYdciRCCnGm2g0rfxKORwEFR6rPwogWA69oCs=;
 b=KkKHeuyBlpvQfJvXcl1xGd95Gd6boVNpwtooXy/M1MormomR7w53c6GZkvmN48t1alclr7B73
 bw3agINaGzkBq1DUqv68Eq1RJ+15RdleLVe9rBI4JL4uf8Wuix8qZgx
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi3798MV200 uses dwc3 controller with a few more clocks and a dedicated
resets. Use of_simple driver for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/usb/dwc3/dwc3-of-simple.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/dwc3/dwc3-of-simple.c b/drivers/usb/dwc3/dwc3-of-simple.c
index d1539fc9eabd..158acae08af5 100644
--- a/drivers/usb/dwc3/dwc3-of-simple.c
+++ b/drivers/usb/dwc3/dwc3-of-simple.c
@@ -173,6 +173,7 @@ static const struct of_device_id of_dwc3_simple_match[] = {
 	{ .compatible = "sprd,sc9860-dwc3" },
 	{ .compatible = "allwinner,sun50i-h6-dwc3" },
 	{ .compatible = "hisilicon,hi3670-dwc3" },
+	{ .compatible = "hisilicon,hi3798mv200-dwc3" },
 	{ .compatible = "intel,keembay-dwc3" },
 	{ /* Sentinel */ }
 };

-- 
2.43.0

