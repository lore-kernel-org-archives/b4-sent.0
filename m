From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Subject: [PATCH v3 0/3] arm64: dts: qcom: add the Xiaomi Mi Pad 5 Pro 5G
Date: Tue, 08 Sep 2026 17:56:58 +0200
Message-Id: <20260908-sm8250-xiaomi-enuma-v3-0-0198c3bf954a@dawidwrobel.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ7CIBCF4asY1mKAtpS68h7GBS2DnUSKAaU1T
 e8u7caFxuX/kvlmJhECQiTH3UwCJIzohxzFfke6Xg9XoGhyE8GEZHXBaHRKVIxOqL1DCsPTaQq
 qVlZ0TJW8IPnyHsDitKnnS+4e48OH1/Yk8XX97yVOGQUjjbJt00ipTkaPaMbgW7gdOu/Iqibxk
 RQrf0siS40xrFTScl5V39KyLG8xLDLsBgEAAA==
X-Change-ID: 20260730-sm8250-xiaomi-enuma-e878f2c08413
To: Jianhua Lu <lujianhua000@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2914; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=FdzTo5I9j/Voa2ar+cDzGaGXqj7sHN/MyX8pwpvwWmY=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWQtMAixW5/M9EzBdK5vqGbx9g0rX1T1bHS6dD7w4R1Zt
 W3l51+c6ShlYRDjYpAVU2TRSwvaYxX88vu7F7/DYeawMoEMYeDiFICJOD5g+B9YekI99gDX3YP/
 95by8L3YuN+83YOTaaqO8+Ezcbeyk/0ZGa4dv3JO31Sx6f8s81e/ndP8xB7v/rf6pmrkC6bXHG1
 zqnkA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mi Pad 5 Pro 5G (enuma, 2021) is the modem-equipped variant of the
Mi Pad 5 Pro (elish). The two boards share a design, so this describes
enuma as sm8250-xiaomi-elish-common.dtsi plus the three things that
differ: the board ID the bootloader matches on, the panel compatible and
the WiFi board data variant.

Unlike elish, enuma shipped with a single display variant, so there is
one device tree rather than a per-panel pair. The vendor device trees key
the touch configuration to a display maker, and enuma declares a single
entry against elish's three:

  https://github.com/MiCode/kernel_devicetree/blob/elish-r-oss/qcom/enuma-sm8250.dtsi#L309
  https://github.com/MiCode/kernel_devicetree/blob/elish-r-oss/qcom/elish-sm8250.dtsi#L294

The panel itself is the same part elish uses: both trees pull in the
same dsi-panel-k81-42-02-0a-video.dtsi, so the new
xiaomi,enuma-csot-nt36523 compatible falls back to
xiaomi,elish-csot-nt36523, leaving room to handle any difference that
turns up later without requiring a device tree change.

The WiFi board data is already upstream in ath11k-firmware as
bus=pci,qmi-chip-id=0,qmi-board-id=255,variant=Xiaomi_Pad_5Pro_5G
(QCA6390 hw2.0 board-2.bin, commit 235d09a5e111).

Tested on the device: the panel and WiFi come up and perform as expected
under postmarketOS.

The fingerprint sensor, PCIe2/modem and touchscreen this board also
provides are left out here; they depend on bindings that are not upstream
yet and will follow separately.

Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
Changes in v3:
- Picked up Konrad's Reviewed-by, given on the v1 patch.
- Follow convention and separate status = "okay" with a newline (Konrad Dybcio)
- Keep the copyright date range current (Konrad Dybcio)
- Link to v2: https://lore.kernel.org/r/20260804-sm8250-xiaomi-enuma-v2-0-9dd0486f1155@dawidwrobel.com

Changes in v2:
- Dropped the "label the WiFi node" patch, folded into device tree patch (Krzysztof Kozlowski)
- Link to v1: https://lore.kernel.org/r/20260730-sm8250-xiaomi-enuma-v1-0-ed6d8fb99668@dawidwrobel.com

---
Dawid Wróbel (3):
      dt-bindings: display: panel: novatek,nt36523: add the Mi Pad 5 Pro 5G panel
      dt-bindings: arm: qcom: add the Xiaomi Mi Pad 5 Pro 5G
      arm64: dts: qcom: sm8250: add device tree for the Xiaomi Mi Pad 5 Pro 5G

 Documentation/devicetree/bindings/arm/qcom.yaml    |  5 ++++
 .../bindings/display/panel/novatek,nt36523.yaml    |  4 ++++
 arch/arm64/boot/dts/qcom/Makefile                  |  1 +
 .../boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi  |  2 +-
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts   | 27 ++++++++++++++++++++++
 5 files changed, 38 insertions(+), 1 deletion(-)
---
base-commit: bd94276d96726a82700d85ad3b32892f45809d3a
change-id: 20260730-sm8250-xiaomi-enuma-e878f2c08413

Best regards,
-- 
Dawid Wróbel <me@dawidwrobel.com>

