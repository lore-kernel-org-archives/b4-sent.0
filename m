From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH 0/3] Add cpufreq to MSM8960
Date: Thu, 14 May 2026 00:03:59 -0700
Message-Id: <20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XN0W6DIBTG8VcxXO80oILVLMveY2kMwkHJpHaAp
 EvTdx/Wm2Y3vfyT7/y4kYDeYiBdcSMekw12OedgbwVRkzyPCFbnJiUtBeWsArxePIYgY+zVZTU
 ef0AIUR0HedSMC5IP88DY6wP9Ou2dZ2u24/5I3CY87K5432n6TENcVjV94y8kBgxMozXXg6iR6
 s/RSTsf1OI+tr9eSb2SDr3szSzDBIkDhZbzsuZUyKZtX2o1Zc+aWXHux3XbpGqzRFMro+jAZfn
 PGmRAyOFs7IrUHCg53e9/5tTtTHABAAA=
X-Change-ID: 20260513-expressatt_cpufreq-66638ba8d156
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778742241; l=3190;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=elyyTlHLLfNzd6l3H0FL9Cz6LRQxDUIlfmi0kRxxO9E=;
 b=adAQ86t2E9Pn6umm47Qn+rUyfPMy/OFEixbhV9nt3P7UFwHbRLRI7fNOuINyw84yMC7CwDYRk
 g2c6AIttcVaCAJIZP/EIUG6prgzQQ06VhHUwO/PmytSB5CscdM7y1qt
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similar to APQ8064, cpufreq is enabled with this small patch series.

Tests:

// Show available frequencies
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
384000 486000 594000 702000 810000 918000 1026000 1080000 1134000 1242000 1350000 1512000
$ cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_available_frequencies
384000 486000 594000 702000 810000 918000 1026000 1080000 1134000 1242000 1350000 1512000
 
// Show current governor
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
schedutil
$ cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
schedutil
 
// set low freq
$ echo 384000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
384000
 
// set mid freq
$ echo 1026000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
1026000
 
// set max freq
$ echo 1512000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
1512000
 
// set low freq
$ echo 384000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
384000
 
// set mid freq
$ echo 1026000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
1026000
 
// set max freq
$ echo 1512000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
1512000
 
// SAW2 regulators
$ cat /sys/class/regulator/regulator.*/microvolts 2>/dev/null | head -2
1200000
1150000

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Rudraksha Gupta (3):
      dt-bindings: soc: qcom: saw2: Rename MSM8960 SAW2 compatible to v1.1
      soc: qcom: spm: Add MSM8960 SAW2 CPU support
      ARM: dts: qcom: msm8960: Add CPU frequency scaling support

 .../devicetree/bindings/soc/qcom/qcom,saw2.yaml    |   2 +-
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           | 133 ++++++++++++++++++++-
 drivers/soc/qcom/spm.c                             |  20 +++-
 3 files changed, 151 insertions(+), 4 deletions(-)
---
base-commit: 3131ff5a117498bb4b9db3a238bb311cbf8383ce
change-id: 20260513-expressatt_cpufreq-66638ba8d156
prerequisite-message-id: <20260503-expressatt-touchkey-v1-1-f7dd5db64e0d@gmail.com>
prerequisite-patch-id: 8de4de7909722ccaf385c4224f25a623eaa72c28
prerequisite-message-id: <20260503-expressatt_camera_flash-v5-0-95524506a799@gmail.com>
prerequisite-patch-id: ab8b8d87fd2d518c4c5b5dace3f22238d1abbe49
prerequisite-patch-id: a6ab585bad167db61d13b10c3912018ec94cdfd9
prerequisite-patch-id: 7ef7df61e7ef6476a35811d765f522f793d9ecc7
prerequisite-message-id: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
prerequisite-patch-id: 27c37aa51fe76043b4998137d106689ed5ae6c91
prerequisite-patch-id: e477ee37abf167c55659f5e591b070b176187ca7
prerequisite-patch-id: 9680b63831f2be63607bff2175639c1987af5e85
prerequisite-patch-id: ee275dc3aec6159072d0a9efb66d18468a72ad57

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

