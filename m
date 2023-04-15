From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/3] mmc: add support for the dw-mmc controller on
 Hi3798MV200
Date: Sat, 15 Apr 2023 22:18:43 +0800
Message-Id: <20230415-mmc-hi3798mv200-v1-0-db5b91d939d4@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEOyOmQC/x2NQQrCMBAAv1L2bCBJbWy8Cj6gV/GQxNXsIVF2S
 xFK/27qcRiGWUGQCQXO3QqMCwm9awNz6CDlUF+o6NEYrLa9PppBlZJUpv7kx7JYrVVCM6CP3o3
 OQatiEFSRQ01570qQGXkXH8Ynff+rG0zXC9y37Qd+CibYfwAAAA==
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Yang Xiwen <forbidden405@outlook.com>
Cc: linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681568331; l=1144;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=NU2bCHBCBu/FVM8V5ZxWORQ+XnnJ/22QxWvmPvYrkQw=;
 b=3xDF9NiFLIw4XcXlfHospvvBjb4Bhkt3ICZkU3monaSgRKpk0SYnAOCP83Nip5dD4fK9lOTlj
 pz/WjDjUWCACfbtinZekZdg/c7PNTyeth7SCAwKXNcxsbcz7a2UHwgN
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dw-mmc controller found on Hi3798MV200 is like the one found on
Hi3798CV200, but has some tweaks.
Also refreshed the dt binding and converted it to YAML.
Unfortunately, DDR52 is not supported yet.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      mmc: dw_mmc-hi3798cv200: rename to dw_mmc-histb
      mmc: dw_mmc-histb: add support for hi3798mv200
      binding: mmc: hi3798cv200-dw-mshc: convert to YAML and rename to histb-dw-mshc, add compatible of hi3798mv200

 .../bindings/mmc/hi3798cv200-dw-mshc.txt           |  40 ---
 .../devicetree/bindings/mmc/histb-dw-mshc.yaml     |  90 ++++++
 drivers/mmc/host/Kconfig                           |   8 +-
 drivers/mmc/host/Makefile                          |   2 +-
 drivers/mmc/host/dw_mmc-hi3798cv200.c              | 206 -------------
 drivers/mmc/host/dw_mmc-histb.c                    | 336 +++++++++++++++++++++
 6 files changed, 431 insertions(+), 251 deletions(-)
---
base-commit: 76f598ba7d8e2bfb4855b5298caedd5af0c374a8
change-id: 20230415-mmc-hi3798mv200-ce15e9b96866

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

