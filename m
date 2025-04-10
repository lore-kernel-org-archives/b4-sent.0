From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH 0/3] update e-mail address for Michael Riesch
Date: Thu, 10 Apr 2025 21:41:29 +0200
Message-Id: <20250410-maintainer-mriesch-v1-0-cdc5c6c68238@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOoe+GcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0MD3dzEzLwSIE4t0s0F6UzO0DVOMbQwNTFIMkpLMlcCaiwoSk3LrAA
 bGh1bWwsAMGSZLGQAAAA=
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Sascha Hauer <s.hauer@pengutronix.de>, Shawn Guo <shawnguo@kernel.org>, 
 Fabio Estevam <festevam@gmail.com>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, imx@lists.linux.dev, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744314121; l=1300;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=SabI+vQohgwZoGDBdV/O1b0jCw1dwkyTziMkwNMVoak=;
 b=EeQE2RZ6/nv/2KYm3bdfAzi43a+GNtVc0yCaKN/zDsu0Ale+mzT2Xw5s+1uuu3I76u4imTJqv
 Xz5rGoJNIjaCcWoVMUQQ7LSUJr7Q/qR3XFewc1GOmyqWbAMIBMokQho
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,
    
"All things must pass..." After five interesting years I recently left
WolfVision and joined Collabora.
    
These patches add a corresponding entry to the mailmap and update my
e-mail address in the Sony IMX415 image sensor driver, which I would like
to continue maintaining using the new Collabora e-mail address.
    
When I prepared the series, I noticed that the i.MX maintainers are most
likely informed about every device tree bindings change for Sony IMX
image sensors. The first patch adds an exclude to fix this.
    
Best regards,
Michael
    

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Michael Riesch (3):
      MAINTAINERS: add exclude for dt-bindings to imx entry
      mailmap: add entry for Michael Riesch
      media: dt-bindings: sony,imx415: update maintainer e-mail address

 .mailmap                                                     | 1 +
 Documentation/devicetree/bindings/media/i2c/sony,imx415.yaml | 2 +-
 MAINTAINERS                                                  | 3 ++-
 3 files changed, 4 insertions(+), 2 deletions(-)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250410-maintainer-mriesch-3d18540b2fb7

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

