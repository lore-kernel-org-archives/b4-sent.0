From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 0/4] hwmon: add ti,ina237 support to ina238 driver
Date: Wed, 25 Oct 2023 10:34:10 +0000
Message-Id: <20231025-ina237-v1-0-a0196119720c@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACLvOGUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2NDAyNT3cy8RCNjc12DNMNEy2RDk7QU0xQloOKCotS0zAqwQdGxtbUAgSW
 57FgAAAA=
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698230088; l=974;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=xtsuT6/iXfx/uvEO3WShw9/zkkhG/bR6W4AGKYROtvM=;
 b=JSCc6cvbBsoffyx845Xz1K3QnAHJDn6h/3HULSsfLgA7GaAMdQDRywoCxnPoEBDsbxIVDErRcq5c
 4RSZFpziB6Fb979JlJ5Ko1OaM0w0qSIWWsks1YSxlqQCISpmoZdu
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the ina237 power monitor to the ina238
driver as those two are very similar.

As the driver missed MAINTAINERS and dt-bindings I've also added them.
If this is incorrect please just ignore the patches or drop me a line so
I can provide a v2.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (4):
      MAINTAINERS: Add entry for ina238 driver
      dt-bindings: hwmon: add ti,ina238
      hwmon: ina238: add ina237 support
      dt-bindings: hwmon: ti,ina238: add ti,ina237

 .../devicetree/bindings/hwmon/ti,ina238.yaml       | 47 ++++++++++++++++++++++
 MAINTAINERS                                        |  7 ++++
 drivers/hwmon/ina238.c                             |  3 +-
 3 files changed, 56 insertions(+), 1 deletion(-)
---
base-commit: 4f82870119a46b0d04d91ef4697ac4977a255a9d
change-id: 20231025-ina237-0f1a9c14fd5d

Best regards,
-- 
Richard Leitner <richard.leitner@linux.dev>

