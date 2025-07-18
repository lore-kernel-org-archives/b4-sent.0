From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v14 0/2] Add support for IPQ5018 tsens
Date: Fri, 18 Jul 2025 11:38:02 +0400
Message-Id: <20250718-ipq5018-tsens-v14-0-28d8a2472418@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANr5eWgC/53Ty2rbQBQG4FcJWnfEOWfuWVk37wqlXZZSJpaUD
 LEulmS3JfjdOxK0sVFocUCbM+j/NDP8eonGavDVGN3fvURDdfKj79owoPhwF+2eXPtYMV+GhYi
 AJAgQzPcHCWjYNFbtyJR4qK2sS85RRyHTD1Xtfy7g129hfvLj1A2/Fv+E82qEyvJgcdDMWASG7
 NFPLGglqxrn9+xw9Lvv4+DD9we3mSff7uJd10SzeKJFCfvhYFEiYdhXbEApTcH6T5hfhIkw5FH
 FpIUx4WjI/gZ/+Jb1ezfV3dCwYz9OQ+UawPhwdPuANa+iWMT8i/70Ge3H1BjD04KbjFIJkAMn5
 FroxOaZps3Va3Hrmn4o0cb90JVxd5z2Xff8Ksu1TNu8yJXJeZGmUBS6sHb7Dlmt5fDwDBKebjO
 e6W0mDM4y3CjrtYyKxHa+aWWFzBQXALNMN8pmLReGLKlCiAIAUIPWy23kN8p2LSd5IiTXhkMCW
 ljJrZ7l7EYZ4U/dJKhQ9et/57SUnzsEJx0pQbvNWsBLAVcCMmCklFTqoS5RuTcE+rdAQXBqLqm
 TEnX5hsAvBVoJfBYIoeYqNFTAtXA+n38DDavYkWYEAAA=
X-Change-ID: 20250404-ipq5018-tsens-64bf95fd3317
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 George Moussalem <george.moussalem@outlook.com>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752824290; l=6162;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=P5txPSNDOE/YGhW5KPbJFZ9L6FeNs8dC9z7RC4rk83M=;
 b=AEDiYPOxvelkAPXiX9vxxV0NZ0KIo3w1JJylt3Sz5aTcuGhEYQpSUrUlYerRnoekT5/qAbqSX
 7325jb4j3WuBz0uRaYoOWdH2C8xhAWXATxRDLL1nfYhvmQtzCPXpWIa
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018 has tsens V1.0 IP with 5 sensors, of which 4 are in use,
and 1 interrupt. There is no RPM present in the soc to do tsens early
enable. Adding support for the same here.

Last patch series sent by Qualcomm dates back to Sep 22, 2023.
Since I'm working on OpenWrt support for IPQ5018 based boards (routers)
and Sricharan Ramabadhran <quic_srichara@quicinc.com> in below email
confirmed this SoC is still active, I'm continuing the efforts to send
patches upstream for Linux kernel support.
https://lore.kernel.org/all/63dc4054-b1e2-4e7a-94e7-643beb26a6f3@quicinc.com/

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v14:
- Rebased on tip of master since v9 was merged even though it was
  superseded by v13. No changes, this is merely the delta between the
  two versions addressing the feedback and fixes in between.
- Link to v13: https://lore.kernel.org/r/20250612-ipq5018-tsens-v13-0-a210f3683240@outlook.com

Changes in v13:
- Dropped polling-delay-passive property as its value of 0 is the
  default value
- Updated hysterssis value to 1000 milicelsius in line with other boards
- Link to v12: https://lore.kernel.org/r/20250611-ipq5018-tsens-v12-0-a61374a5517d@outlook.com

Changes in v12:
- Updated description in dt bindings for IP v1 without RPM
- Added Fixes tag as this this version of tsens needs to be explicitly
  reset and enabled in the driver, introduced as part of:
  commit: 19f9b02ebc8f ("thermal/drivers/qcom/tsens: Add support for tsens v1 without RPM")
- Link to v11: https://lore.kernel.org/r/20250611-ipq5018-tsens-v11-0-266566bfd16a@outlook.com

Changes in v11:
- Dropped polling-delay property as its value of 0 is the default value
- Removed comments for TM and SROT in tsens node
- Replaced underscore by hyphen in node name of top-glue-critical trip
- Added cooling device using CPU freq scaling making use of the passive
  trip defined under the CPU trips
- Make qcom,ipq5018-tsens a standalone compatible in the bindings as it
  should not use qcom,tsens-v1 as a fallback. This also fixes the issue
  reported by Rob's bot

Changes in v10:
- Rebased onto updated pull of master to resolve merge conflicts in the
  DTS patch
- Link to v9: https://lore.kernel.org/all/DS7PR19MB88836DC6965515E12D70BB2C9DCC2@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v9:
- Updated checks in tsens to more strictly evaluate for v2+ upon enabling
  v2 features as suggsted by Dmitry.
- Split patch 3 into two, one to update conditional statements as
  mentioned above and the other to implement tsens IP v1 without RPM.
- Added back Dmitry's RB tag on patch 6 which wasn't carried over
  from v7 to v8
- Link to v8: https://lore.kernel.org/all/DS7PR19MB88833F7A9C8F4FC484977BA69DCD2@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v8:
- Tsens V1 uses v1 interrupts and watchdog is not present (only on v2.3+).
  As such, replaced VER_1_X with VER_1_X_NO_RPM in conditons to ensure
  v1 interrupts are set and watchdog isn't enabled.
- Tested on Linksys MX2000 and SPNMX56
- Link to v7: https://lore.kernel.org/all/DS7PR19MB88831624F11516945C63400F9DC22@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v7:
- Updated cover letter
- Replaced patch 3 with a new one to add support for tsens v1.0 with
  no RPM and removed Dmitry's 'Reviewed-by tag
- Refactored patch 4 and split support for IPQ5018 from support for
  tsens v1.0 without RPM. As such, also removed Dmitry's RB tag.
- Depends on patch 1 and 2 from patch series to add support for
  IQP5332 and IPQ5424 applied on Feb 11 2025:
  https://patchwork.kernel.org/project/linux-arm-msm/cover/20250210120436.821684-1-quic_mmanikan@quicinc.com/
- Link to v6: https://lore.kernel.org/all/DS7PR19MB88838833C0A3BFC3C7FC481F9DC02@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v6:
- Include (this) cover letter
- Picked up Dmitry's Reviewed-by tag on patch 5
- Link to v5: https://lore.kernel.org/all/DS7PR19MB88832FDED68D3EBB0EE7E99F9DC72@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v5:
- Adjusted commit messages to indicate IPQ5018 has 5 sensors of
  which 4 are described and in use as per downstream driver and dts.
- Padded addresses of tsens and qfprom nodes with leading zeros.
- Link to v4: https://lore.kernel.org/all/DS7PR19MB8883BE38C2B500D03213747A9DC72@DS7PR19MB8883.namprd19.prod.outlook.com/

Changes in v4:
- Documented ipq5018 in qcom,qfprom bindings
- Constrained ipq5018-tsens to one interrupt with description
- Added Rob's Acked-by tag
- Added Dmitry's Reviewed-by tag
- Fixed modpost warning: added __init to init_common
- Sorted tsens nodes by address
- Sorted thermal-zones nodes by name
- Link to v3: https://lore.kernel.org/all/20230922115116.2748804-1-srichara@win-platform-upstream01.qualcomm.com/

Changes in v3:
- Added the tsens-ipq5018 as  new binding without rpm
- Added Dmitry's Reviewed tag
- Fixed Dmitry's comments for error checks in init_ipq5018
- Ordered the qfprom device node properties
- Link to v2: https://lore.kernel.org/all/20230915121504.806672-1-quic_srichara@quicinc.com/

Changes in v2:
- Sorted the compatible and removed example
- Fixed the name for new tsens_feature
- Used tsend_calibrate_common instead of legacy
  and addressed comments from Dmitry.
- Squashed patch 3 & 4
- Fixed node names, order and added qfprom cells
  for points seprately
- Squashed patch 6 & 7
- Link to v1: https://lore.kernel.org/all/1693250307-8910-1-git-send-email-quic_srichara@quicinc.com/

---
George Moussalem (1):
      dt-bindings: thermal: qcom-tsens: make ipq5018 tsens standalone compatible

Sricharan Ramabadhran (1):
      arm64: dts: qcom: ipq5018: Update tsens node and thermal zones

 .../devicetree/bindings/thermal/qcom-tsens.yaml    |  7 +++-
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              | 41 +++++++++++++---------
 2 files changed, 31 insertions(+), 17 deletions(-)
---
base-commit: 680a7813b2bf707824e74b48e5c1f2674a516838
change-id: 20250404-ipq5018-tsens-64bf95fd3317

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

