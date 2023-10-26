From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH v2 0/2] hwmon: add ti,ina237 support to ina238 driver
Date: Thu, 26 Oct 2023 09:08:48 +0200
Message-Id: <20231026-ina237-v2-0-dec44811a3c9@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIAQOmUC/2XMywrCMBCF4VcpszYyM7WWuPI9pIuQix2QVBINl
 ZJ3N3br8j8cvg2yT+IzXLoNki+SZYkt+NCBnU28eyWuNTByT8iDkmi4HxUGMtrSKbjBQTs/kw+
 y7tBtaj1Lfi3ps7uFfusfUUihMkj6TKRHRnt9SHyvR+cLTLXWLz4oR82cAAAA
To: Guenter Roeck <linux@roeck-us.net>, Jean Delvare <jdelvare@suse.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1698304135; l=878;
 i=richard.leitner@linux.dev; s=20231025; h=from:subject:message-id;
 bh=/GtJaouCP9uYvnQf/YrQKxvci6Y4JpBN0GXQjS2r29E=;
 b=0tI3/dPziYw9MSGLgP4np9BF9AJSZ2F7UAb/TMp0Q9VBuy5n3mYqM+tlptr9PzIZ5Ry7Nh3zqkVY
 Rw49LwMcAnEYWN8DrDuEHdJAHZxMWhV1HXkKjLNHKC3636hVLHYJ
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=ZYa5+0m9RFYtnNU6DLet7sHyPehnVHa0ucJlYiAu2NU=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20231025 with auth_id=90
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the ina237 power monitor to the ina238
driver as those two are very similar.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Changes in v2:
- Drop separate MAINTAINERS entry as it's covered by hwmon
- Drop separate dt-bindings for ina23{7,8} as discussed with Krzysztof
- Link to v1: https://lore.kernel.org/r/20231025-ina237-v1-0-a0196119720c@linux.dev

---
Richard Leitner (2):
      hwmon: ina238: add ina237 support
      dt-bindings: hwmon: ti,ina2xx: add ti,ina237

 Documentation/devicetree/bindings/hwmon/ti,ina2xx.yaml | 1 +
 drivers/hwmon/ina238.c                                 | 3 ++-
 2 files changed, 3 insertions(+), 1 deletion(-)
---
base-commit: 4f82870119a46b0d04d91ef4697ac4977a255a9d
change-id: 20231025-ina237-0f1a9c14fd5d

Best regards,
-- 
Richard Leitner <richard.leitner@linux.dev>

