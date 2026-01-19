From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 19 Jan 2026 18:19:55 +0100
Subject: [PATCH 1/4] iio: proximity: vl53l0x-i2c: Add optional vddio
 regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-vl53l0x-v1-1-cf71715a1353@protonmail.com>
References: <20260119-vl53l0x-v1-0-cf71715a1353@protonmail.com>
In-Reply-To: <20260119-vl53l0x-v1-0-cf71715a1353@protonmail.com>
To: Song Qiang <songqiang1304521@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843207; l=816;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=BV4POcOIZq8QUHOdmdM1SwxBCDON6elezUBUerTNxcg=;
 b=cPVYUMmL1kFKjDAF78n8ou5j2xqWoELiWi5TaQSfe2CUAq3cwCY9ROgWsOIyJv4dGbNP3qK9n
 OaZDney50bkDwL21eO/vxCVlTJo0+ID6CgM28xfqQFO0po7uxBTJjZk
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VL53L0X can be powered using separate core (VDD) and I/O (VDDIO)
supplies. Add support for an optional vio regulator and enable/disable
it during power on/off when present.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 Documentation/devicetree/bindings/iio/proximity/st,vl53l0x.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/proximity/st,vl53l0x.yaml b/Documentation/devicetree/bindings/iio/proximity/st,vl53l0x.yaml
index 322befc41de6..f7e55d427fe4 100644
--- a/Documentation/devicetree/bindings/iio/proximity/st,vl53l0x.yaml
+++ b/Documentation/devicetree/bindings/iio/proximity/st,vl53l0x.yaml
@@ -24,6 +24,8 @@ properties:
 
   vdd-supply: true
 
+  vio-supply: true
+
 required:
   - compatible
   - reg

-- 
2.52.0

