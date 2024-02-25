From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v4 0/2] usb: dwc3: add glue driver for Hi3798MV200
Date: Sun, 25 Feb 2024 20:03:47 +0800
Message-Id: <20240225-dwc3-v4-0-8c1fd6c6f615@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKMs22UC/23MQQ7CIBCF4as0rMXAAIKuvIdxQelgiVpMW1HT9
 O7S6sbY5ZvM9w+kwzZgR3bFQFpMoQuxyUOuCuJq25yQhipvAgwkA65p9XCCbrbagCmlYdaS/Hp
 r0YfnnDkc865D18f2NVcTn67fAMhPIHHKqPa+BITSWi328d5fYjyvXbySKZFgiUFmBqV3lVaaa
 /XPxBITmYESyjtE7Zn5ZeM4vgE6APEuCAEAAA==
To: Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708862628; l=1668;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=zPcJ2vC3A6HhIVo48qXQTTqMOtfOET2qYf2tQ9lsrYY=;
 b=sjlryJDUd028obFeraj/Zs16TT0AhhjYtAK23/PgjYEVlDO03Ex/s8VCyMAXzJb26y7kuRDiB
 bhkAaOd4SckApV2UcAI3de8VumYuXzlh2cEG0qf88nN38lAIOcx/vAL
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
Changes in v4:
- bindings: example: move ranges after compatible
- remove me from email
- Link to v3: https://lore.kernel.org/r/20240224-dwc3-v3-0-2535fcee7f08@outlook.com

Changes in v3:
- binding: remove example address
- binding: remove reg (Krzysztof)
- binding: rearrange required (Krzysztof)
- binding: put additionalProperties after required (Krzysztof)
- binding: indent properly (Krzysztof)
- Link to v2: https://lore.kernel.org/r/20240224-dwc3-v2-0-8e4fcd757175@outlook.com

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

 .../bindings/usb/hisilicon,hi3798mv200-dwc3.yaml   | 99 ++++++++++++++++++++++
 drivers/usb/dwc3/dwc3-of-simple.c                  |  1 +
 2 files changed, 100 insertions(+)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240217-dwc3-697828b480aa

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

