From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] i2c: Add driver support Amlogic A9 I2C
Date: Thu, 24 Sep 2026 08:39:33 +0000
Message-Id: <20260924-a9-i2c-v1-0-b8ad9b46f4a8@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMXhtGoC/x3NwQqDMBCE4VeRPbvUrGLVVyk9xHRa9xIlERGC7
 27S4898MIkigiLSVCUKODTq6nOYuiK3WP8D6yc3SSN9MxrDdmQVx9J1zwEi6IeWMp5tBM/Berc
 UnsmjMI9zL/MW8NXz//N6X9cN2hcA83cAAAA=
X-Change-ID: 20260911-a9-i2c-24478e22e683
To: Junyi Zhao <junyi.zhao@amlogic.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Xianwei Zhao <xianwei.zhaol@amlogic.com>
Cc: Junyi Zhao <junyi.zhaol@amlogic.com>, linux-i2c@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790239188; l=891;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=0Zdvv1H2vY20qgMq7ejxgwzP9h/gzw/1guKtZBvMtyI=;
 b=nGXvSYzZAE1DmqOkbjIhGAK1rvc731QofIqzvdiWy3K17AECnFpZbcvHNlqHn4CQZF0aDxGzi
 Itu9wKqZKCdDQ0N0sYYTz4I8Oo9Kwc2sEXWQEtzFtzrVBw+2vOkgWbf
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Device Tree binding and driver for the I2C controller found on the
Amlogic A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Junyi Zhao (1):
      i2c: amlogic: Add Amlogic A9 I2C controller driver

Xianwei Zhao (2):
      dt-bindings: i2c: add Amlogic A9 I2C controller
      MAINTAINERS: Add an entry for Amlogic I2C driver

 .../devicetree/bindings/i2c/amlogic,a9-i2c.yaml    |  61 +++
 MAINTAINERS                                        |   8 +
 drivers/i2c/busses/Kconfig                         |   9 +
 drivers/i2c/busses/Makefile                        |   1 +
 drivers/i2c/busses/i2c-amlogic-a9.c                | 504 +++++++++++++++++++++
 5 files changed, 583 insertions(+)
---
base-commit: e817a366cd24ddc8f986ef43c5d54cc3f60b0c21
change-id: 20260911-a9-i2c-24478e22e683

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

