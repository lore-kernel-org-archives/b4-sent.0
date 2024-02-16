From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/4] mmc: add hi3798mv200 specific extensions of DWMMC
Date: Fri, 16 Feb 2024 18:37:58 +0800
Message-Id: <20240216-b4-mmc-hi3798mv200-v2-0-010d63e6a1d5@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAY7z2UC/22Nyw6CMBBFf8XM2jHtUB668j8MC2iLTLTUtNhoC
 P9uxa3Lc5J77gLRBrYRTrsFgk0c2U8ZaL8DPXbT1SKbzECClJAksVfonMaRi/rYuERCYFfWhbB
 mkEQa8vAR7MCvLXppM48cZx/e20eSX/vLkaz+5ZJEgbVRlekbVXa2OvvnfPf+dtDeQbuu6wel1
 ClqtgAAAA==
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708079892; l=1790;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=9w2bI+hdTEUkHwmJZgqnNrTm3dF8JO/74q7G3Kshnzg=;
 b=GVrFnTkcI2ByMKXvsctj030QF9pOAZcH1VUk/BLXeBrS/jKXbM2IJzv8YHTt6Q+PNh5oH4MYT
 zh4EJIa0HHBCk5BmMP1L1yDacgy6TQK6dnyRUkiswHr5UAdADAao5i5
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it's modified from hi3798cv200 driver, but quite a lot of code gets
rewritten because of the hardware differences. Actually cv200 DWMMC core
is called HIMCIV200 while mv200 DWMMC core is called HIMCIV300 in
downstream.

Pending on:
[PATCH] mmc: host: replace 1st argument to struct device * for mmc_of_parse_clk_phase():
	https://lore.kernel.org/all/20240215-mmc_phase-v1-1-f27644ee13e4@outlook.com/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- dw_mmc-hi3798mv200: use dev_err_probe() helper - Suggested by Krzysztof Kozlowski.
- dw_mmc-hi3798mv200: add missing err=0;
- dw_mmc-hi3798c(m)v200: remove unused MODULE_ALIAS() - Suggested by Krzysztof Kozlowski.
- binding: rename the binding, a lot of tweaks suggested by Krzysztof Kozlowski.
- Link to v1: https://lore.kernel.org/r/20240216-b4-mmc-hi3798mv200-v1-0-7d46db845ae6@outlook.com

---
Yang Xiwen (4):
      mmc: dw_mmc-hi3798cv200: remove MODULE_ALIAS()
      mmc: dw_mmc: add support for hi3798mv200
      dt-bindings: mmc: dw-mshc-hi3798cv200: convert to YAML
      dt-bindings: mmc: hisilicon,hi3798cv200-dw-mshc: rename to hisilicon,hi3798-dw-mshc

 .../bindings/mmc/hi3798cv200-dw-mshc.txt           |  40 ----
 .../bindings/mmc/hisilicon,hi3798-dw-mshc.yaml     |  92 ++++++++
 drivers/mmc/host/Kconfig                           |   9 +
 drivers/mmc/host/Makefile                          |   1 +
 drivers/mmc/host/dw_mmc-hi3798cv200.c              |   1 -
 drivers/mmc/host/dw_mmc-hi3798mv200.c              | 235 +++++++++++++++++++++
 6 files changed, 337 insertions(+), 41 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240121-b4-mmc-hi3798mv200-a5730edf122c

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

