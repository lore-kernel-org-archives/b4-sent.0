From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/2] ir: support IR for Amlogic A9 SoC
Date: Fri, 27 Nov 2026 03:21:53 +0000
Message-Id: <20261127-a9-ir-v4-0-820209515755@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFH3CGsC/2XMSw7CIBSF4a00jMXwKhRH7sM4wFtoSWwxYIim6
 d6lTRpfw3Nzv39CyUZvEzpUE4o2++TDWIbYVQh6M3YW+7ZsxAiTRBGJjcY+Yl4Ld2FaWUUlKr+
 3aJ1/rJ3Tuezep3uIzzWb6XL9LWSKCRaONAxMY4yjRzNcQ+dhD2FASyOzT6c3xxbHgNFWGekc/
 Dv+dprwzfHioBWKgpQKaP3t5nl+AV/U+8EMAQAA
X-Change-ID: 20260706-a9-ir-354fb297e716
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795749801; l=1248;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=lP8dWaYvlkNxblzfl6GBLSnU86I9FtR51w4nRbCwyHs=;
 b=7O/Thlf1yZqCmYAoCt8dVr+68VqOGpwmlPoslKIKPvqmHSD2PQ9Ks05h/iy7RTv+nLPhZ8fmm
 JrsbGrZIV5mDopbKbGX8jXDRwcuDuzfSeUlkq3hctZsuAD13vT9KfQa
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Amlogic A9 IR controller compatible string and
add the IR controller node for the Amlogic A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- Add Neil Armstrong's Reviewed-by tag.
- Link to v3: https://lore.kernel.org/r/20260903-a9-ir-v3-0-cd471c667c15@amlogic.com

Changes in v3:
- Align the node of group-remote-input-ao-pins.
- Link to v2: https://lore.kernel.org/r/20260709-a9-ir-v2-0-42c21d7a6ffc@amlogic.com

Changes in v2:
- Rename the IR input pinctrl group and its phandle from remote_pins to remote_input_ao_pins.
- Link to v1: https://lore.kernel.org/r/20260706-a9-ir-v1-0-4f082ca8aaf1@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: media: meson6-ir: Add Amlogic A9 IR compatible
      arm64: dts: amlogic: a9: Add IR controller support

 .../devicetree/bindings/media/amlogic,meson6-ir.yaml       |  4 ++++
 arch/arm64/boot/dts/amlogic/amlogic-a9-a311y3-by401.dts    |  6 ++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi                | 14 ++++++++++++++
 3 files changed, 24 insertions(+)
---
base-commit: 807a34cf91c1d91f2beb3cacef9eaa98bd56d172
change-id: 20260706-a9-ir-354fb297e716

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

