From: Ben Grisdale <bengris32@protonmail.ch>
Subject: [PATCH 0/2] regulator: fan53555: Add support for Silergy SYM827
Date: Fri, 06 Nov 2026 15:13:04 +0000
Message-Id: <20261106-fan53555-silergy-sym827-support-v1-0-4e871c7f475c@protonmail.ch>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQ6CMBBA0auQWTsJLRlAr2JYUDrFMQpNB4yEc
 HerLt/m/x2Uk7DCpdgh8UtU5inDnAoYbv00MorPBlva2piSMPQTVUSEKg9O44a6PVvboK4xzml
 BH86tb6j2lXOQKzFxkPfvcO3+1tXdeVi+WTiODyw8U8iDAAAA
X-Change-ID: 20261105-fan53555-silergy-sym827-support-df98d756d3bb
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793978058; l=842;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=luqQfSxLzy1m2Cu0B0ORh9PcmErSggIyVznVMub0yXk=;
 b=vVs3KvxNaznyT1s+5qudB8D7vZGpKURnN8holT3JVNTv2aSHtsDBYi0JJ1Vqa0PNi/wK5MKgG
 LrbCNq7rtJtAedUCZhWKYGwzmVq8iCOC2+rhEYCqMDg058btcbGiNHr
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Silergy SYM827 is a 6A synchronous step-down converter with a
similar I2C register map to the FAN53555, found in MediaTek MT8163
devices as the external VPROC regulator. It differs from the already
supported SYR827 in its die ID and output voltage range.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
Ben Grisdale (2):
      regulator: dt-bindings: fan53555: Add Silergy SYM827
      regulator: fan53555: Add support for Silergy SYM827

 Documentation/devicetree/bindings/regulator/fcs,fan53555.yaml |  1 +
 drivers/regulator/fan53555.c                                  | 11 +++++++++++
 2 files changed, 12 insertions(+)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261105-fan53555-silergy-sym827-support-df98d756d3bb

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

