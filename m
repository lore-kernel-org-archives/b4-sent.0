From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/2] arm64: dts: qcom: sm8350: Scale L3 and memory
 bandwidth with the CPUs
Date: Fri, 16 Oct 2026 06:01:14 +0000
Message-Id: <20261016-sm8350-cpu-bw-v1-0-044ac6dc9565@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Mz3eJcC2NTA93kglLdpHJd8+RU41QD87SkVONEJaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaAO8LuwRxAAAA
X-Change-ID: 20261016-sm8350-cpu-bw-7ce3e07fbe3a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792130480; l=867;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=zaVfJ1YgBwAelENSTsicW+btJeqfXxKfuym1Z88hnF8=;
 b=ex1GhzDFwT4n0sAH6MOl8aOPrns3QazXQXvFVVWYVECkocbZgsNugkcij0KbQwSlsiA5Sz2sz
 amHmSijzS4xDKUYUCSGqJou8qLOZM7AtYYK9oAO/VTUxxZGtXII8kEA
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the EPSS L3 provider and CPU OPP tables that vote for LLCC, DDR and
L3 bandwidth with the CPU frequency, as on SM8550 and SM8650.

Tested on a Razer Edge 5G, whose board support is not upstream yet:
copy bandwidth on the A78 and X1 cores goes from 8 to 22-33 GB/s and
DDR latency from 200 to 125 ns. Idle power with the screen off does not
change; with the X1 busy on compute alone it rises by about 0.3 W.

---
Demeter Barna (2):
      arm64: dts: qcom: sm8350: Add the EPSS L3 provider
      arm64: dts: qcom: sm8350: Add CPU OPP tables with memory bandwidth

 arch/arm64/boot/dts/qcom/sm8350.dtsi | 347 +++++++++++++++++++++++++++++++++++
 1 file changed, 347 insertions(+)
---
base-commit: 4eb2586bd40db27d77cc5b724ca9386ed0c71d53
change-id: 20261016-sm8350-cpu-bw-7ce3e07fbe3a

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

