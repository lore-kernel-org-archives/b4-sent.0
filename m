From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH v3 0/3] Add support for attaching a regulator to w1: ds2482
Date: Sun, 24 Nov 2024 17:21:34 +0100
Message-Id: <20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAI5SQ2cC/2WMywrCMBBFf6Vk7UgyTR+68j/ExTSZtgHbSiJBK
 f1304JQ9O7OhXNmEdg7DuKczcJzdMFNY4L8kAnT09gxOJtYoESt0sAG1DUCWQueO2hZ5Sgl2cq
 WIkkPz617bcHrLXHvwnPy760f1fp+U8VvKiqQYEytmxM1pLC8dAO5+9FMg1hTEXc64p+OSaeCZ
 M5caUvVXl+W5QOztA/L6wAAAA==
X-Change-ID: 20241111-ds2482-add-reg-fe13200ad7d6
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732465298; l=1048;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=/9ijyl8GH0XD0x3k3EDuqb7k1ihuj0joBaoT2aUOF4w=;
 b=T8bKNb/jV0tPhdz3tKUndiEJsHAJ0g2LD8k+h1QGp8n+8cWVyrVgo705iH02D8LTng8BzZN9N
 qivFJymlTwfDjymO/kzxYEDAnB03gHnpYQyoyApCGgSNm40cUn+zsCK
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implemented changes requested in review and retested them.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
Changes in v3:
- Switched from regulator_enable() to devm_regulator_get_enable()
- Removed obvious comments.
- Link to v2: https://lore.kernel.org/r/20241122-ds2482-add-reg-v2-0-a5a03ee74da7@gmail.com

Changes in v2:
- Removed property description
- Changed commit message of binding commit
- Link to v1: https://lore.kernel.org/r/20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com

---
Kryštof Černý (3):
      w1: ds2482: Add regulator support
      w1: ds2482: Fix datasheet URL
      dt-bindings: w1: ds2482: Add vcc-supply property

 Documentation/devicetree/bindings/w1/maxim,ds2482.yaml |  2 ++
 drivers/w1/masters/ds2482.c                            | 10 +++++++++-
 2 files changed, 11 insertions(+), 1 deletion(-)
---
base-commit: 6d59cab07b8d74d0f0422b750038123334f6ecc2
change-id: 20241111-ds2482-add-reg-fe13200ad7d6

Best regards,
-- 
Kryštof Černý <cleverline1mc@gmail.com>

