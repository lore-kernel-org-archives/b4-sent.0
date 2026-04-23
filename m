From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/2] basic devicetree support for Amlogic A9
Date: Thu, 23 Apr 2026 09:20:53 +0000
Message-Id: <20260423-a9-baisc-dts-v4-0-c26b480a068c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHXk6WkC/3XPTQ6CMBCG4auQrq2ZDn/FlfcwLtqhhSZCDSVEQ
 7i7hY2KcflN8rzJzCyYwZnATsnMBjO54HwfR3ZIGLWqbwx3ddwMAQtAyLmquFYuEK/HwElrbdC
 AsBJYJPfBWPfYcpdr3K0Lox+eW30S6/VPaBIcuECBOitslavyrLqbbxwdyXdsTU34wVHuOEael
 Zms6pxIKPnL0zdPId3xdOXaooD4CuT0zZdleQHZnAXgKAEAAA==
X-Change-ID: 20260205-a9-baisc-dts-cbbbe2e01f80
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776936062; l=1483;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=J5L1A2jbbo0SMdIEzOxqGDDsrZHiKwYymWv6/n3eMPs=;
 b=MMB+BaVniSUyZKdSGxjqC0+QARageSMqnZG67niJuAY6OQmXCEfsmCh/0soeIxzjkXY1sPihL
 mK7TYOWPD74CAavjMWq4lIXY1y23HbjGva2d3NvS34N9uZrEiO+a8zT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new A9 SoC/board device tree and related bindings.

Since the serial submission has removed this patch as a separate patch.
The dtb check needs to be relied upon for serial submission mereged, or
check failed, when run "make ARCH=arm64 dtbs_check W=1".

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- Rebase code, modfiy size of gic reg, and drop cpu_mask for timer node due to GICv3.
- Link to v3: https://lore.kernel.org/r/20260303-a9-baisc-dts-v3-0-4bf21001f05c@amlogic.com

Changes in v3:
- Remove serial bindings from this patches and will send it independently.
- Link to v2: https://lore.kernel.org/r/20260228-a9-baisc-dts-v2-0-47489d5cc1a8@amlogic.com

Changes in v2:
- Move default interrupt-parent into dtsi.
- Link to v1: https://lore.kernel.org/r/20260205-a9-baisc-dts-v1-0-1212b46f95a7@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: arm: amlogic: add A311Y3 support
      arm64: dts: add support for A9 based Amlogic BY401

 Documentation/devicetree/bindings/arm/amlogic.yaml |   6 +
 arch/arm64/boot/dts/amlogic/Makefile               |   1 +
 .../boot/dts/amlogic/amlogic-a9-a311y3-by401.dts   |  40 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        | 128 +++++++++++++++++++++
 4 files changed, 175 insertions(+)
---
base-commit: 8b379d5e9eb7933c73e77e768d95f11ef2833c26
change-id: 20260205-a9-baisc-dts-cbbbe2e01f80

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

