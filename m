From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH v2 0/2] Add PM8010 regulators for sm8650 boards.
Date: Tue, 23 Jan 2024 16:49:23 +0800
Message-Id: <20240123-sm8650_pm8010_support-v2-0-52f517b20a1d@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJR9r2UC/4WNQQ6CMBBFr0Jmbc10pEJceQ9DCJlWmQW0tEA0h
 LtbuYDL95L//gbJRXEJbsUG0a2SxI8Z6FQA9934ckpsZiCkEjVdVBrqq8E2DDVqbNMSgo+zqgw
 yms6wNRbyNkT3lPfRfTSZe0mzj5/jZtU/+6+4aoXKOiai0pqqxPu0CMvIZ/YDNPu+fwEuZ8tnv
 AAAAA==
To: kernel@quicinc.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, quic_collinsd@quicinc.com, 
 Fenglin Wu <quic_fenglinw@quicinc.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705999765; l=807;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=SZpBe1ZMkjIIG1/Zbs/Nh5sfWuGE8hUuaJV6ZfEzdkU=;
 b=SJyv3SvVn4z9V6mFzNEYCCVYUdqUtlSzHFX9oiZvFyN66JZb88UZQd/Gnv4BaRKPeh7zSnwJw
 FFDyaq7jYa5A+JKPaeTYe1G5jqxiwlKrXy6295ITeDDgfl1/DWNmcNb
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PM8010 RPMh regulators for sm8650-mtp and sm8650-qrd boards.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Changes in v2:
- Added Reviewed-by/Tested-by trailers
- Link to v1: https://lore.kernel.org/r/20240123-sm8650_pm8010_support-v1-0-dec2224d5740@quicinc.com

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

