From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH v4 0/2] Add Samsung Galaxy Tab S9 Wi-Fi (SM-X710) support
Date: Thu, 22 Oct 2026 23:58:18 +0200
Message-Id: <20261022-gts9wifi-dts-v4-0-a361428fe59c@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMQQ6CMBCF4auQrq0pQwHrynsYF6XTwiQKpiWII
 dzdwgoxLt9Lvn9iwXqygZ2TiXk7UKCujUMeEmYa3daWE8bNQECRCiF53Qf1Ikcc+8ARZAn2pHL
 IJIvk6a2jcc1db3E3FPrOv9f6kC7vn9CQcsFTJ7BElKWV+oIjPjTdj8awpTTAVuc7DVGbTBtVC
 aeMrX50ttEgdjqLWjsUhasAlVNfep7nDzlaXDElAQAA
X-Change-ID: 20261004-gts9wifi-dts-d2472e895234
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Nizat Mikayilli <nacht@dxdmail.cc>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792706340; l=2005;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=PfTYWAs2CSTbVke9UM6xjpocxVnW5Km5StAU7TfdOwM=;
 b=OHn7JOVgbCXm8HZejwM3Kz0D4MBzAQ1UZW2LAbeJcW/oRK59BCpXfyfmFKRckuWxa8fpAGLjo
 32lpAB7UDZFAoMGooWKVW9XtcAWMUQULYxG8DQKTZvhueR91dCssu3W
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree support for the Samsung Galaxy Tab S9 Wi-Fi (SM-X710),
an SM8550 tablet. Two patches: the qcom.yaml board entry and the board
DTS describing UFS, microSD, USB 2.0 peripheral via eUSB2 with an NXP
PTN3222 repeater, keys, GPU, video decoder, ADSP, the CS35L45/VA-macro
audio path and WCN6855 Wi-Fi/Bluetooth.

Tested on hardware on top of linux-next next-20261002 (boots to a shell
through U-Boot): storage, microSD, USB gadget, framebuffer console, keys
including the book-cover switch, CPU frequency scaling, GPU firmware and
render node, video decoder node, speaker playback, DMIC capture, Wi-Fi
scanning and Bluetooth firmware loading.

---
Changes in v4:
- Keep the modem carveouts except rmtfs_mem, the MPSS firmware is
  shipped on this SKU; memtest=1 is clean (Konrad)
- Add Konrad's Reviewed-by
- Link to v3: https://lore.kernel.org/r/20261020-gts9wifi-dts-v3-0-afd06fb2d9f9@dxdmail.cc

Changes in v3:
- Add Wi-Fi and Bluetooth (Konrad)
- Test microSD and audio, update the commit message (Konrad)
- Add a blank line before status properties (Konrad)
- Expand the GPIO36..39 and USB comments (Konrad)
- Add Krzysztof's Acked-by
- Link to v2: https://lore.kernel.org/r/20261005-gts9wifi-dts-v2-0-c3ac9b0f9ceb@dxdmail.cc

Changes in v2:
- Use my name for author and Signed-off-by (Conor)
- Link to v1: https://lore.kernel.org/r/20261004-gts9wifi-dts-v1-0-1f0d7dd47e4a@dxdmail.cc

---
Nizat Mikayilli (2):
      dt-bindings: arm: qcom: Add Samsung Galaxy Tab S9 Wi-Fi
      arm64: dts: qcom: sm8550: Add support for Samsung Galaxy Tab S9 Wi-Fi

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sm8550-samsung-gts9wifi.dts      | 873 +++++++++++++++++++++
 3 files changed, 875 insertions(+)
---
base-commit: f0406245cb9855e6318335a8a223551354291a46
change-id: 20261004-gts9wifi-dts-d2472e895234

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

