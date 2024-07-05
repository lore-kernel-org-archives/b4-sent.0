From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH 0/3] Add power sequence for Amlogic WCN chips
Date: Fri, 05 Jul 2024 19:13:24 +0800
Message-Id: <20240705-pwrseq-v1-0-31829b47fc72@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFXVh2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcwND3YLyouLUQl2jZPOUJDODNPPEFEMloOKCotS0zAqwQdGxtbUAlrI
 2IFgAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178006; l=934;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=NR6dERoCSDaycJgCgMkPX5tK/ic6aM93Ky3+ivQy/0M=;
 b=hz7wspgeRvBvZlGNqvwuOnM9aoR98FrZ0S3JTGFxVGzumsGu8kh7uXFHMDfMyAzZ/cVLa2ndf
 MtnmewNrcbRBpd06Pt0pgoD17OLx3Khm9dUuvGh/f+bvlX1EV8HYpls
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic WCN power sequence, including dt-binding, power sequence
provider with Amlogic, and enable POWER_SEQUENCING_AML_WCN in defconfig.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Yang Li (3):
      dt-bindings: power: Add power sequence for Amloigc WCN chips
      power: sequenceing: Add power sequence for Amlogic WCN chips
      MAINTAINERS: Add an entry for Amlogic WCN power sequence

 .../bindings/power/amlogic,w155s2-pwrseq.yaml      |  62 ++++++
 MAINTAINERS                                        |   8 +
 drivers/power/sequencing/Kconfig                   |   7 +
 drivers/power/sequencing/Makefile                  |   1 +
 drivers/power/sequencing/pwrseq-aml-wcn.c          | 209 +++++++++++++++++++++
 5 files changed, 287 insertions(+)
---
base-commit: 0b58e108042b0ed28a71cd7edf5175999955b233
change-id: 20240701-pwrseq-2c7db60f7ad1

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

