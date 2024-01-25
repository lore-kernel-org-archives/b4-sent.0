From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH v3 0/2] Add PM8010 regulators for sm8650 boards.
Date: Thu, 25 Jan 2024 17:31:14 +0800
Message-Id: <20240125-sm8650_pm8010_support-v3-0-2f291242a7c4@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGIqsmUC/43NQQ6CMBCF4auQrq2ZDowQV97DGIJtkVkAtYVGQ
 7i7hZ0rXf4vmW8WEaxnG8Q5W4S3kQOPQ4r8kAndNcPDSjapBQIWoDCXoa9OBLXrK1BQh9m50U+
 yJNBADWlDRqRb523Lr9293lJ3HKbRv/c3UW3rLzEqCdJYjYiFobKAy3NmzYM+6rEXmxnxLweTQ
 9iSKu8IjTLfzrquH4ohnNkEAQAA
To: kernel@quicinc.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, quic_collinsd@quicinc.com, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706175079; l=1205;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=HyKIL7MR0TT3sSkhF/hxv6Xzw9uF1jLRyVnGFnT9B4c=;
 b=MwaMrUsVDw8ZqP/STnoorwurZg9Rk9jDEX2VTUFbuKxodgE7PyVveBgbJclfsKgqubHwPiOTl
 j3onBIhMblrDi+SPMNNn2HsHIZsFRxCHeIsiRizg5QYJhUHHwSrAOuN
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PM8010 RPMh regulators for sm8650-mtp and sm8650-qrd boards.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Changes in v3:
- Split vdd-l6-l7 supply for regulator-6, and split vdd-l5-l6 for regulator-7,
  as vdd-[5-7]-supply is defined in the driver seperately.
- Add regulator-allow-set-load and regulator-allowed-modes for LDO1/LDO2
  as they are the only LDOs support mode transition in PM8010.
- Link to v2: https://lore.kernel.org/r/20240123-sm8650_pm8010_support-v2-0-52f517b20a1d@quicinc.com

Changes in v2:
- Added Reviewed-by/Tested-by trailers
- Link to v1: https://lore.kernel.org/r/20240123-sm8650_pm8010_support-v1-0-dec2224d5740@quicinc.com

---
Fenglin Wu (2):
      arm64: dts: qcom: sm8650-mtp: add PM8010 regulators
      arm64: dts: qcom: sm8650-qrd: add PM8010 regulators

 arch/arm64/boot/dts/qcom/sm8650-mtp.dts | 132 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8650-qrd.dts | 132 ++++++++++++++++++++++++++++++++
 2 files changed, 264 insertions(+)
---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240123-sm8650_pm8010_support-750c05a5cd5d

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

