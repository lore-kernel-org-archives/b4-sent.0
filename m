From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/2] usb: dwc3: add glue driver for Hi3798MV200
Date: Sat, 24 Feb 2024 05:43:11 +0800
Message-Id: <20240224-dwc3-v2-0-8e4fcd757175@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG8R2WUC/y3MQQ7CIBCF4as0sxZDp0TQlfcwXQAFO1GLgYqah
 ruL1eX/8vItkFwkl+DQLBBdpkRhqoGbBuyop7NjNNQG5Cg4tpINT9ux3V4qVEYorjXU6z06T6+
 VOfW1R0pziO9Vze13/QMofkBuGWfSe4MOjdayO4bHfA3hsrXhBn0p5QMPbBkDmgAAAA==
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yang Xiwen <forbidden405@foxmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708724592; l=1171;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=wxmKrh/Cs57CnGFgC1amvY2Csn44ZKMzdK1MVS66FAw=;
 b=/y6KnlSRzutvZJNPU9nmWv2ucnSM2BFbmplrG3GtCQGdIKS/YQ/nnXibiML6lMg3E0yNOw7jS
 u6eecyQOmGID+ddnSVp2f/Vhm9o3fOUgy6hiT3MZdhEKiAeIII3D4uR
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
Changes in v2:
- remove histb-clock.h as it's deprecated.
- fix bot error (Rob Herring)
- add a dummy reg property to make simple-bus parent node happy.
  (duplicate with subnode, not used in driver)
- Link to v1: https://lore.kernel.org/r/20240224-dwc3-v1-0-7ffb2e2baa73@outlook.com

---
Yang Xiwen (2):
      dt-bindings: usb: add hisilicon,hi3798mv200-dwc3
      usb: dwc3: of-simple: Add compatible for hi3798mv200 DWC3 controller

 .../bindings/usb/hisilicon,hi3798mv200-dwc3.yaml   | 103 +++++++++++++++++++++
 drivers/usb/dwc3/dwc3-of-simple.c                  |   1 +
 2 files changed, 104 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-dwc3-697828b480aa

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

