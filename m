From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Subject: [PATCH 0/4] arm64: dts: qcom: add the Xiaomi Mi Pad 5 Pro 5G
Date: Thu, 30 Jul 2026 23:51:59 +0200
Message-Id: <20260730-sm8250-xiaomi-enuma-v1-0-ed6d8fb99668@dawidwrobel.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBuYtB/pKtFCaqxZaKEUQnT3p
 OW3eO+BxFE4wVg9EPmWJEcoaOoKlt2GjVHWYlCkeho0YfJGdYRZ7OEFOVzeIpvBOLWQaRsNpTw
 jO8n/dZrf9wOJQMBCZQAAAA==
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
 =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2440; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=ylL4HaLJUGIisHKBhr3vt+N6GH9GmauZVEy1Ot7Z0Ig=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlH+9P7G1rjtLsvSJ4eUUYe6SO+7qkTeGM81er78o1u
 i42eapMRykLgxgXg6yYIoteWtAeq+CX39+9+B0OM4eVCWQIAxenAExEaR4jw/oWRTu5B70Mghpp
 0cdPLgxn/vxo2Sc3s2u/IrcJvf7SmcPw3+3MR6nX+78k1Yu9akhqOzRBMWJNyG/JDbuz2A9s4Xi
 5lxsA
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
Dawid Wróbel (4):
      dt-bindings: display: panel: novatek,nt36523: add the Mi Pad 5 Pro 5G panel
      dt-bindings: arm: qcom: add the Xiaomi Mi Pad 5 Pro 5G
      arm64: dts: qcom: sm8250-xiaomi-elish: label the WiFi node
      arm64: dts: qcom: sm8250: add device tree for the Xiaomi Mi Pad 5 Pro 5G

 Documentation/devicetree/bindings/arm/qcom.yaml    |  5 +++++
 .../bindings/display/panel/novatek,nt36523.yaml    |  4 ++++
 arch/arm64/boot/dts/qcom/Makefile                  |  1 +
 .../boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi  |  2 +-
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-enuma.dts   | 26 ++++++++++++++++++++++
 5 files changed, 37 insertions(+), 1 deletion(-)
---
base-commit: bd94276d96726a82700d85ad3b32892f45809d3a
change-id: 20260730-sm8250-xiaomi-enuma-e878f2c08413

Best regards,
-- 
Dawid Wróbel <me@dawidwrobel.com>

