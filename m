From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/3] mmc: add hi3798mv200 specific extensions of DWMMC
Date: Fri, 16 Feb 2024 01:46:41 +0800
Message-Id: <20240216-b4-mmc-hi3798mv200-v1-0-7d46db845ae6@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAFOzmUC/x3MPQqAMAxA4atIZgNpVPy5ijhom2qGqrQggnh3i
 +M3vPdAkqiSYCgeiHJp0mPPMGUBdpv3VVBdNjBxTYYNLjWGYHHTqu27cDERzk1bkThvmC3k8Iz
 i9f6n4/S+HxbAM4FkAAAA
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708019203; l=1049;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=3SmWmcck5G21RkHFmC4DweIdttsir78RJ8t2utgkGNQ=;
 b=iDJmQqTXs95Iec5RYgBkbeSZNLygTPRYG7YrVtIPzwwKnTycoUIsL5xoH+f3o+MFsRz0AY/z3
 hPEFez78WuhDTV2TNtdCfyP+ZoRA1tu2zw+hH8asPLXEDBC5PvPIlWu
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it's modified from hi3798cv200 driver, but quite a lot of code gets
rewritten because of the hardware differences. Actually cv200 DWMMC core
is called HIMCIV200 while mv200 DWMMC core is called HIMCIV300 in
downstream.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      mmc: dw_mmc: add support for hi3798mv200
      dt-bindings: mmc: dw-mshc-hi3798cv200: convert to YAML
      dt-bindings: mmc: dw-mshc-hi3798cv200: rename to dw-mshc-histb

 .../bindings/mmc/hi3798cv200-dw-mshc.txt           |  40 ----
 .../devicetree/bindings/mmc/histb-dw-mshc.yaml     | 130 +++++++++++
 drivers/mmc/host/Kconfig                           |   9 +
 drivers/mmc/host/Makefile                          |   1 +
 drivers/mmc/host/dw_mmc-hi3798mv200.c              | 238 +++++++++++++++++++++
 5 files changed, 378 insertions(+), 40 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240121-b4-mmc-hi3798mv200-a5730edf122c

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

