From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/2] arm64: dts: qcom: sm8350: Add CPU and LLCC BWMON
Date: Fri, 16 Oct 2026 06:13:50 +0000
Message-Id: <20261016-sm8350-bwmon-v1-0-562fe403bf6b@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Mz3eJcC2NTA92k8tz8PN1EYzNTM4vkJCMD42QloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAWQ86wHAAAAA=
X-Change-ID: 20261016-sm8350-bwmon-a36568cb203c
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792131248; l=984;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=pJkuQ5sxueCNJq/4feYK9sFltk8n39f8M+LNL3IDvJA=;
 b=ft9eFqoU8zxNmRBZdxKjT3TpAebnRH67UODWaQz7J/Jw+cpMq+ZSduhCGjCDer/JjDD1lFQRI
 AeyGRuEuk55Coyd36hqgiZ/DYI4T655yYKw3E+4SCQJyGfJpfEcMCw5
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CPU (CPU to LLCC) and LLCC (LLCC to DDR) bandwidth monitors of
SM8350, as SM8250 and SM8550 have them.

Tested on a Razer Edge 5G, whose board support is not upstream yet:
both monitors probe and their votes follow the memory traffic, also
after a system suspend. On top of the CPU OPP votes of [1], they add
14-15 % copy bandwidth on the A55 and A78 cores.

[1] https://patch.msgid.link/20261016-sm8350-cpu-bw-v1-0-044ac6dc9565@fromdisposition.org

---
Demeter Barna (2):
      dt-bindings: interconnect: qcom,msm8998-bwmon: Add SM8350 CPU and LLCC BWMON
      arm64: dts: qcom: sm8350: Add CPU and LLCC BWMON

 .../bindings/interconnect/qcom,msm8998-bwmon.yaml  |   2 +
 arch/arm64/boot/dts/qcom/sm8350.dtsi               | 100 +++++++++++++++++++++
 2 files changed, 102 insertions(+)
---
base-commit: 4eb2586bd40db27d77cc5b724ca9386ed0c71d53
change-id: 20261016-sm8350-bwmon-a36568cb203c

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

