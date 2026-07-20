From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH 0/2] media: i2c: add support for ITE IT6625/IT6626 HDMI to
 MIPI CSI-2 bridge
Date: Mon, 20 Jul 2026 15:57:44 +0800
Message-Id: <20260720-upstream-it6625-it6626-v1-0-475912f74459@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPjUXWoC/yWMQQ5AMBAAvyJ71qQtXeIr4lAs9qCkLZGIv2s4T
 eYwc0MgzxSgyW7wdHLgzSVReQbDYt1MgsfkoKVGWSkUxx6iJ7sKjoja/ECBdVXavramkAZSvHu
 a+PrGbfc8L/m2ES1oAAAA
X-Change-ID: 20260716-upstream-it6625-it6626-6874ab8a5305
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784534292; l=1353;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=om9Z0znRE3p24CehzGI9n1x1Swl0bLKrLB53xSQZXKs=;
 b=Wg8c8qFgkns5cReMKTZE5mwlNvUhFMiQ07Qc0aHTgVB2Om8M5rwpIJgX14HOGpdkJ0qkbQ5D0
 +ztQUpAjZquBHP5dVu0pnxeL6at7OnylY9MNLB/ZOEIu10J+/MN8qsC
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the ITE IT6625/IT6626 HDMI to MIPI CSI-2
bridge chips. IT6625 accepts an HDMI 2.0 input and IT6626 an HDMI 2.1
input, converting it to a D-PHY (or C/D-PHY on IT6626) MIPI CSI-2
output. The bridge is configured over I2C, exposes an HDMI CEC
adapter, and supports EDID read/write, DV timings detection and
configuration, and HPD control via the standard V4L2 subdevice pad
and video ops.

Patch 1 documents the devicetree binding for the bridge, including
its three graph ports (two selectable CSI-2 outputs and one HDMI
input).

Patch 2 adds the V4L2 subdevice driver itself.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (2):
      dt-bindings: media: add ITE IT6625/IT6626 HDMI bridge binding
      media: i2c: add driver for ITE IT6625/IT6626

 .../devicetree/bindings/media/i2c/ite,it6625.yaml  |  136 ++
 MAINTAINERS                                        |    7 +
 drivers/media/i2c/Kconfig                          |   18 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/it6625.c                         | 2088 ++++++++++++++++++++
 5 files changed, 2250 insertions(+)
---
base-commit: 8dac27bfa2f994ecb11f01a63641527d17d48fc1
change-id: 20260716-upstream-it6625-it6626-6874ab8a5305

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

