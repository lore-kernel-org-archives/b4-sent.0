From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH 0/2] Add PM8010 regulators for sm8650 boards.
Date: Tue, 23 Jan 2024 14:42:22 +0800
Message-Id: <20240123-sm8650_pm8010_support-v1-0-dec2224d5740@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM5fr2UC/x3MQQqEMAxA0atI1hbSOhnFq4iItNHJQi2NiiDe3
 TLLt/j/BuUkrNAWNyQ+RWVbM2xZgP+N68xGQjY4dB+0rjK6NF/CIS4NWhz0iHFLu6kJPdJIPlC
 A3MbEk1z/b9c/zwuY8LXjZwAAAA==
To: kernel@quicinc.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, quic_collinsd@quicinc.com, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705992197; l=642;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=HbkqSj51Sa9IVM8rrG6Dn3HDORo0yZkDPCYmR5xjh70=;
 b=FAllM/If3g3hJGSiylVVhhgt1gWcFDF1jpAg5NjShOSW0/QP04BOrFTOagJ+zTaTG+0FVqUoQ
 SGV7RWOr5kiATAwgy7btqMSYHKQNWmRwIBBfG4kSu094FjMvKvIgGvL
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PM8010 RPMh regulators for sm8650-mtp and sm8650-qrd boards.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Fenglin Wu (2):
      arm64: dts: qcom: sm8650-mtp: add PM8010 regulators
      arm64: dts: qcom: sm8650-qrd: add PM8010 regulators

 arch/arm64/boot/dts/qcom/sm8650-mtp.dts | 118 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8650-qrd.dts | 118 ++++++++++++++++++++++++++++++++
 2 files changed, 236 insertions(+)
---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240123-sm8650_pm8010_support-750c05a5cd5d

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

