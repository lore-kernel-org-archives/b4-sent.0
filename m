From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH 0/2] arm64: dts: qcom: sdm630: Fix the CPU idle states
Date: Sun, 11 Oct 2026 23:18:06 -0300
Message-Id: <20261011-sdm630-idle-states-v1-0-3181d488dc0f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywrCMBCF4VcpszaQG0H6KuIiTSY6YtOSSUUIe
 XejLr8D52/AWAgZ5qlBwRcxbXlAnSYId59vKCgOg5baKamU4Lg6I8f6RMHVV2Rxtsn4YJxddIB
 x3Asmev+il+vffCwPDPVbgt4/p6mbAnYAAAA=
X-Change-ID: 20261011-sdm630-idle-states-84f3ac364b2c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Martin Botka <martin.botka@somainline.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791771486; l=1578;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=7MGFQOvs/uHXmXb1V4YxkRGBMRJ2mPeougEEkwVrI9E=;
 b=K54XIqDzise9CWqfWlth2suD/uFf9KjU3X0TOiVVZkVXubVu+GxcxuDA+tqX/J2uozOrKJXeQ
 9pEKNsZoEiJB1zry3Q3gd0W+mqWh98Kc39rdPQgOYsruGY/IaCtrp8D
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Of the five idle states sdm630.dtsi gives each CPU, four are never
entered. The three cluster states use PSCI parameters that are not in
the encoding the vendor kernel uses, and cpuidle records no successful
entry into them. Because they are the deepest states, an idle CPU
keeps choosing one, each attempt returns at once, and the CPU spends
its idle time retrying instead of sleeping. CPU retention sets the bit
that marks a state as losing context. The first patch drops the cluster
states, the second fixes the retention parameter.

Tested on a Motorola Moto X4 (SDM630), whose board file is not in
mainline yet, on sdm660-mainline's 7.2 kernel, whose idle states are
these: with the screen off and the charger input suspended, the
battery current drops from 277 mA to 117 mA.

This firmware denies platform-coordinated mode at boot ("psci:
[Firmware Bug]: failed to set PC mode: -3"), and the vendor kernel
requests a cluster state only from the last CPU of a cluster.
Restoring cluster idle that way, with the CPUs described as PSCI
power domains, is left for a later series.

---
Fabricio Akio (2):
      arm64: dts: qcom: sdm630: Drop the cluster idle states
      arm64: dts: qcom: sdm630: Fix the CPU retention idle state parameter

 arch/arm64/boot/dts/qcom/sdm630.dtsi | 112 ++++-------------------------------
 1 file changed, 10 insertions(+), 102 deletions(-)
---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261011-sdm630-idle-states-84f3ac364b2c

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

