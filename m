From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v3 0/4] arm64: qcom: x1-vivobook-s15: add X1P42100 variant,
 restructure dts files
Date: Sat, 14 Feb 2026 09:32:52 +0100
Message-Id: <20260214-b4-vivobook-v3-0-3c88065bbf77@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADYzkGkC/3XOQQ6CMBCF4auQrq3pFErAlfcwLigdZCJxTIuNS
 ri7BTeycPm/ZL7MJAJ6wiAO2SQ8RgrEtxT5LhNt39wuKMmlFlrpUgFU0hYyUmTLfJVOGVOU2GF
 baZEu7h47eq7a6Zy6pzCyf614hGX9OlptnQhSybyprUEwea3qIw8utD3zEHh4jOmnsLf0Fgsa9
 Q8EsIV0gurOKFWAcRrdX2ie5w8hVlcR/AAAAA==
X-Change-ID: 20260118-b4-vivobook-d05546efec82
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>, 
 "Colin K. Williams" <colin@li-nk.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771057984; l=2082;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Ghx+NO5PD21JPthd0b2XCXAdcOQW8V5g2COXkPcaDf8=;
 b=QEwgM6fwAwd7J50x07qde4b19KBiyOkcEVoA1sCPHgFkCDMC1fmcmoWlZeFrnOF3t07gTVaZz
 GgJa4haFNDjBjiyMFo4SnutLoA91rPATfDoghZPiFgskWuQVoTipoSR
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds the X1P42100 variant of the ASUS Vivobook S15 [1]. To avoid
redundant code, it pulls the part that is identical to both variants into
x1-asus-vivobook-s15.dtsi.

I have maintained the X1P42100 variant on my tree for about a year now, it has
been tested by quite a few users. Also added sound (not in this patchset) and
users operate this successfully.

[1]: https://www.asus.com/de/laptops/for-home/vivobook/asus-vivobook-s-15-s5507/techspec/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v3:
- Fixed the \nstatus = "okay"; nit
- Dropped the t-b on the bindings commit
- Rebased onto next-20260213
- Link to v2: https://lore.kernel.org/r/20260211-b4-vivobook-v2-0-9f500415d2ed@oldschoolsolutions.biz

Changes in v2:
- Fixed the bindings mixup and the redundant gpu node in the Purwa dts
- Re-partitioned the patch set to have no new dangling file
- Rebased onto next-20260210
- Thanks to all that commented on the patches.
- Link to v1: https://lore.kernel.org/r/20260208-b4-vivobook-v1-0-3a9b5e153909@oldschoolsolutions.biz

---
Jens Glathe (4):
      dt-bindings: arm: qcom: Add ASUS Vivobook X1P42100 variant
      firmware: qcom: scm: allow QSEECOM on ASUS Vivobook X1P42100 variant
      arm64: dts: qcom: x1-vivobook-s15: create a common dtsi for Hamoa and Purwa variants
      arm64: dts: qcom: x1-vivobook-s15: add Purwa-compatible device tree

 Documentation/devicetree/bindings/arm/qcom.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    2 +
 arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi | 1362 ++++++++++++++++++++
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 1346 +------------------
 .../boot/dts/qcom/x1p42100-asus-vivobook-s15.dts   |   44 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 6 files changed, 1411 insertions(+), 1345 deletions(-)
---
base-commit: 635c467cc14ebdffab3f77610217c1dacaf88e8c
change-id: 20260118-b4-vivobook-d05546efec82

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

