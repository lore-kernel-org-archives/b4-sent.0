From: Juerg Haefliger <juerg.haefliger@canonical.com>
Subject: [PATCH 0/2] arm64: dts: qcom: HP OmniBook X14 / EliteBook Ultra
 G1q cleanups
Date: Thu, 08 Oct 2026 20:34:44 +0200
Message-Id: <20261008-dts-qcom-hp-omnibook-x14-cleanup-v1-0-9702f7c6f9a0@canonical.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAETix2oC/x3NQQqDMBBA0avIrDuQSaVKr1K6MMlUBzWTJrYI4
 t0bunyb/w8onIUL3JsDMn+liMYKujTgpyGOjBKqwRp7I2N6DFvBt9cVp4S6RnGqM+7Uol94iJ+
 ExrVX6p3tAgWomZT5Jft/8Xie5w9fTCMxcgAAAA==
X-Change-ID: 20261008-dts-qcom-hp-omnibook-x14-cleanup-0b4318b27d1d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1273;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=z1keIMkDW9sgT1aZElw1oXdTbG2r8uKYS4gdSonjtuU=;
 b=kA0DAAoBD9OLCQumQrcByyZiAGrH4r2hJnwRKyn2OC076o+NyGhZ7x1vo11mzp7Cm4Yblob0j
 4kCMwQAAQoAHRYhBIWX1PeiLqa74i3Xiw/TiwkLpkK3BQJqx+K9AAoJEA/TiwkLpkK3FrgP/iYD
 6L/i9RHcLuFBZwKJhLomd3da/+diaM4kKRmFIcy+V2PqMdy2eyHgiQcYTRYCvvXwZOhD9Yib3qD
 E6tsKsN0nfYEuF+d1lbxi9guGFm/3L61E1ut9HgKwr2JoKjrJ6aN1SsAS8DgKYTe3hhd/fcuYlM
 5ASPhaER92taeb9sC3NOoXDBGInpwluM68/ShYXxvgcnRWkiwXrbw+f6UpacqPwUDpAFBtfEPxp
 Az6sRmWhUzRmw58yRRAfrWESJuimGRuF/bxy+yVP8X0iWsyNeg9ml7f0CuFpo3IsBDhwb3zi8LC
 I+ttyM2v5a1NHs4jl7amHAgjk94NPa1AvstI0+NeZGS8AaMW/JQbZT+ol5JQD6L8HJgRtmd0m7W
 Zj3Jh706bFoqz3JbugepPSZFihYc/N670QGc/0fiXUl+wV08s0Raku4SAyIUrEV0jogDrfXpORQ
 y4/LtB4TQovPmlPwDWZX6gY3dim5eet4bHI0Bax8f9oWffGtDiCPF7eFt/UON1Cor0mYEIhE+iw
 BYmBe8PqG2E1SjmuWiktyllbhfVxuWxaalJ86IaruJydffi0tJDwxhCIF3SXZQ7rRz4dMRBH5mc
 6OBxrzv0pENvG0Lt+2EbtAJOPLh74eldLe6m3crVgcjylvo4jLW5VODQLo4u+EwA+C2DxU7m2xB
 WtUCK
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a small two patch series that cleans up the device trees for the
HP OmniBook X14 family and untangles the HP EliteBook Ultra G1q from them.

Patch 1 consolidates the duplicated hamoa-pmics.dtsi include and
chassis-type property into the included x1-hp-omnibook-x14.dtsi.

Patch 2 makes the HP EliteBook Ultra G1q a sibling of the OmniBook X14
boards instead of a child, so all three (2 x omnibook, 1 x elitebook) are
at the same level.

Both patches are pure devicetree restructuring, no functional changes
intended.

...Juerg

---
Juerg Haefliger (2):
      arm64: dts: qcom: x1-hp-omnibook-x14: Consolidate pmics and chassis
      arm64: dts: qcom: hp-elitebook-ultra-g1q: Drop omnibook-x14.dts include

 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi             | 4 ++++
 arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts | 7 ++++++-
 arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts        | 2 --
 arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts        | 3 +--
 4 files changed, 11 insertions(+), 5 deletions(-)
---
base-commit: 705529dab1fa872d8b53b09c95e1b03a95573376
change-id: 20261008-dts-qcom-hp-omnibook-x14-cleanup-0b4318b27d1d

Best regards,
--  
Juerg Haefliger <juerg.haefliger@canonical.com>

