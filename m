From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH v2 0/2] arm64: dts: mediatek: mt8395-radxa-nio-12l: Enable
 i2c3 on 40-pin header
Date: Wed, 24 Jun 2026 17:45:52 +0200
Message-Id: <20260624-nio-12l-add-i2c-40-pin-v2-0-cf3707a6aaf1@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7ZjOWAm68h6GBbaDjDGlaZFoC
 HcX8AAuX/L++xNkSSoZzsUESUbN2ocFeFeA65pwF1S/MLDh0pRsMWiPxE9svEdlh9Zg1IB0EmM
 rbn11OMIyjklafW/ha/3j/Lo9xA1rbTU6zUOfPtvzSKv392QkJGxLRySeqbLuEpvkNeg+yAD1P
 M9fTGA7BNAAAAA=
X-Change-ID: 20260624-nio-12l-add-i2c-40-pin-19e0482fd835
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1961; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=t/FdEOdKFRydzqNszOoE3W7Wm9xvewq16CLXGLDuIQs=;
 b=owEBiQF2/pANAwAIATteP+Oex+3pAcsmYgBqO/uz3CqJQLwTCOCs/fZ33SftVnybXcbr3CU6A
 5BlUqWkJHiJAU8EAAEIADkWIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCajv7sxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwwLDMACgkQO14/457H7ekz4wf+PJj0qBqgPJibSseohoa7sj+e3Zpn5dK
 5YhPtpDIOeXxiQoPKHpnVvThZYTVN2yTDtoNe1J527gaka+83sd0i8u+PT3bmd4GMUMMctc83wx
 93kecJEO/Lj5niqrhSFhvn2KnOll1n3kB+/d42GlyVCYSdINA7tavIszLcF+9enkHkQgFCdVJc0
 UOP9Z0mAMwwQ9qcYZLcnawhzSt8bXqeAqwU+1G9iNKYX49vY79QQupy5kLgGqL0sPyO7/4vfx9O
 lg1XgMiUaUrJe7ikYOwdKmsOX6EE0izDtM4DqfX3ocO7PF3HT0Zv5gZ6dB/xnZu/E5Hhvp6wn8R
 H7ILTMlFRNA==
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa NIO 12L exposes i2c3 (SDA3/SCL3, GPIO14/GPIO15) on its 40-pin
GPIO header, on the blue-colored pins 27 (SCL3) and 28 (SDA3).

Enable the i2c3 controller, add the matching pinctrl configuration and run
the bus at 400 kHz, matching the other I2C buses already enabled on this
board.

While at it, drop a pre-existing redundant drive-strength from i2c2_pins
that was also about to be copied into i2c3: specifying both drive-strength
(mA) and drive-strength-microamp (uA) makes the generic pinconf parser log
"cannot have multiple drive strength properties" at boot, and the advanced
(uA) setting wins in hardware, leaving the mA value dead.

Tested using a SD1306 I2C OLED display.

---
Changes in v2:
- Add a drive-by patch dropping the redundant drive-strength in i2c2_pins
  (via Claude, reported by Sashiko).
- i2c3: use only drive-strength-microamp, as per Sashiko's review.
- Link to v1: https://patch.msgid.link/20260624-nio-12l-add-i2c-40-pin-v1-1-f6c11ed2184c@pardini.net

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Matthias Brugger <matthias.bgg@gmail.com>
To: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-mediatek@lists.infradead.org
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>

---
Ricardo Pardini (2):
      arm64: dts: mediatek: mt8395-radxa-nio-12l: Drop redundant i2c2 drive-strength
      arm64: dts: mediatek: mt8395-radxa-nio-12l: Enable i2c3 on 40-pin header

 arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260624-nio-12l-add-i2c-40-pin-19e0482fd835

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

