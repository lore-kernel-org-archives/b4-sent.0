From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH v2 0/2] arm64: dts: qcom: sm8350: Add CPU capacities and
 power coefficients
Date: Mon, 12 Oct 2026 03:56:03 +0000
Message-Id: <20261012-sm8350-cpu-capacity-v2-0-67ce449becf0@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OQQ6DIBREr2JYl4YPYmpXvUfjAgH1N7EQvpoa4
 92Ldt/lS2bezMbIJ/TE7sXGkl+QMLwzyEvB7GDevefoMjMpZAUCJKfxprTgNs7cmmgsTitXUGp
 TedB1q1huxuQ7/JzWZ/NjmtuXt9OhOhID0hTSes4ucOT+LyzABVcOSvBC1LXTjy6F0SHFQDjlz
 9eQetbs+/4FqbB8WNIAAAA=
X-Change-ID: 20261012-sm8350-cpu-capacity-3145a6e159b3
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791777425; l=1799;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=w9kTsY78JmCrb87bSa72DL2IVDLvj0lnMC2vJKSw2c0=;
 b=k2+Ld8UrsCCizogtNl53u3PuYAFm8A6fTJLOduMyZPK/L7WU6675kNPPU7JUG0pbXcxzL0EjT
 QWWMWfgYxdGB9OD8O/46A1LRivjtyJIovScyxbidn7M8BoK5LutjClx
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Give the SM8350 CPUs their capacities and dynamic power coefficients, so
that the scheduler sees the three clusters as they are and energy aware
scheduling gets an energy model. Both come from Qualcomm's downstream
device trees.

Downstream, the capacities are the same for v1 and v2 silicon, but the
power coefficients are not: patch 2 takes the v2 ones, which the device
tested here (v2.1) carries too. I have no v1 part to check them on; if
v1 boards matter, patch 2 can wait without holding up patch 1.

Tested on a Razer Edge 5G (SM8350 v2.1), whose board support is not
upstream yet: cpu_capacity reads 308, 785 and 1024 once the kernel has
scaled the values by each cluster's maximum frequency (1804, 2419 and
2995 MHz), sched_energy_aware is 1, and the energy model covers all
three clusters. Compared with the same kernel without these patches, an
unpinned CPU-bound task now runs mostly on the X1 and a light periodic
task on the A55s. dtbs_check shows no new warning for the SM8350 boards.
The values come from Razer's kernel release for this device
(Nicole-msm-5.4.254-20240515).

---
Changes in v2:
- From and Signed-off-by now carry my real name instead of the handle
  "fromdisposition" used for v1 (same author). No code changes.
- Link to v1: https://patch.msgid.link/20261012-sm8350-cpu-capacity-v1-0-3d141e0099d5@fromdisposition.org

---
Demeter Barna (2):
      arm64: dts: qcom: sm8350: Add CPU capacities
      arm64: dts: qcom: sm8350: Add CPU dynamic power coefficients

 arch/arm64/boot/dts/qcom/sm8350.dtsi | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)
---
base-commit: d053e38e614fb2e383b298ce8fc308a780d7f209
change-id: 20261012-sm8350-cpu-capacity-3145a6e159b3

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

