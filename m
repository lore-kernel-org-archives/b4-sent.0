From: Asdlerto Korry <korryasdlerto@gmail.com>
Subject: [PATCH net-next v3 0/2] nfc: s3fwrn5: Add optional pvdd-supply
Date: Thu, 12 Nov 2026 19:25:48 +0200
Message-Id: <20261112-m52xq-nfc-netdev-v3-0-725a61ce4148@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJz29WoC/x2Myw5AMBAAf0X2bBOtqMeviAO62IOibaSJ+Hcbx
 0lm5oFAnilAlz3g6ebAhxMo8wzmbXQrIVth0IU2SimNe6XThW6Z0VG0dGNdtJVpJmOssiDZ6Wn
 h9C97EEe8FGF43w88qg5dbAAAAA==
X-Change-ID: 20261112-m52xq-nfc-netdev-709568b66d1d
To: Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>
Cc: oe-linux-nfc@lists.linux.dev, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794504348; l=1231;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=FPzxZu2nWQWrhcZEqMnLi0tLkX9iDWIfqKNtKI9gkAw=;
 b=gW9J7ls4k0dEC8Q5IvGh+B9T+zT1xb+yXjtYd6yr7gOL8mQ5eU5z7mcN9UIzDmToSCjxzav73
 3knriemU/c+DKtD0pXO/wE+34P5h5QQQNYha+Pnh0PIGoiKfIBL6S2S
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung S3FWRN5 NFC chip has a PVDD supply pin. On the Samsung
Galaxy M52 5G (sm7325) it is fed by a PMIC regulator that is not
always-on, so the driver has to enable it. These two patches add the
optional supply to the binding and make the driver enable it before the
enable GPIO is driven.

They were part of the series "arm64: dts: qcom: Add Samsung Galaxy M52
5G" (v2). As suggested by Krzysztof, they are split out and resent for
net-next. The DTS patches stay in the Qualcomm series; the DTS node uses
pvdd-supply only after this binding is merged.

Changes since v2 (as part of the DTS series):
 - sent as a separate series with the net-next prefix
 - no code changes, Reviewed-by from Krzysztof kept

---
Asdlerto Korry (2):
      dt-bindings: net: nfc: samsung,s3fwrn5: Add pvdd-supply
      nfc: s3fwrn5: i2c: Enable the pvdd supply

 Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml | 5 +++++
 drivers/nfc/s3fwrn5/i2c.c                                      | 7 +++++++
 2 files changed, 12 insertions(+)
---
base-commit: 7649ba73f9e7e1e04d0b46213e39c79ae09dd55c
change-id: 20261112-m52xq-nfc-netdev-709568b66d1d

Best regards,
-- 
Asdlerto Korry <korryasdlerto@gmail.com>

