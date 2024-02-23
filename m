From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/2] usb: dwc3: add glue driver for Hi3798MV200
Date: Sat, 24 Feb 2024 01:17:48 +0800
Message-Id: <20240224-dwc3-v1-0-7ffb2e2baa73@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADzT2GUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0Nz3ZTyZGNdM0tzCyOLJBMLg8REJaDSgqLUtMwKsDHRsbW1AOQg0ip
 WAAAA
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yang Xiwen <forbidden405@foxmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708708670; l=874;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=yAqE4Gklx+CS9b43iJDoKMxjk5QyMnffq2TCExLKUk8=;
 b=L/FFhJMRyX2yxgyBw/IzR4EWYcSESiHMGfckFR27oIqWZL2j763k/uZXLFLA/1ei4SiT7MC97
 zT471j/+NPMB2WVcMPCt4PgkUqPBJwdn7DLr52+L3+dadQX+MXT8WZR
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi3798MV200 uses DWC3 with a few more clocks and a dedicated reset.

Note xhci-histb.c can also be used. But since it's DWC3 in fact, trying
to support it with the help of DWC3 framework seems a better solution.

Hi3798CV200 can also try to migrate to this driver too. Thus we can
remove xhci-histb.c in the future.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (2):
      dt-bindings: usb: add hisilicon,hi3798mv200-dwc3
      usb: dwc3: of-simple: Add compatible for hi3798mv200 DWC3 controller

 .../bindings/usb/hisilicon,hi3798mv200-dwc3.yaml   | 100 +++++++++++++++++++++
 drivers/usb/dwc3/dwc3-of-simple.c                  |   1 +
 2 files changed, 101 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-dwc3-697828b480aa

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

