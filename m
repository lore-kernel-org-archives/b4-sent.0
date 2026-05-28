From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v2 0/3] Add cpufreq to MSM8960
Date: Wed, 27 May 2026 20:39:27 -0700
Message-Id: <20260527-expressatt_cpufreq-v2-0-b9b7726ccb6d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XQ0WrDIBQG4FcJXs+ixpg0jLH3GCUYPSaypOnUS
 EvJu88kg5Ux6OUv53wH/zvy4Cx4VGd35CBab6dzCuwlQ6qX5w6w1SkjRpggBc0xXC8OvJchNOo
 yGwdfWAiRV62sNC0ESotpwNjrhn6c9pzG5mSH/RGNq7DZdfa606x8oHGYZtV/wg1Hhikm/KiV5
 NSoXL53o7TDQU3j23rrmdQoOYKTjRmk73EUmGANxNCCEMaBP9U4oY+amWFounmdiXmyjqLkyij
 SFpL9sVrpAacw2lBnsTwQtHbRWx8md9v6jnQr46da/l+1MX0e86o0mumyqorj7xF0WpblG1I0Y
 MHAAQAA
X-Change-ID: 20260513-expressatt_cpufreq-66638ba8d156
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>, 
 Ilia Lin <ilia.lin@kernel.org>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779939569; l=3382;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ke7HvLdLefDj+v9czBNoRTxNhOufQCAgn7Qfxki38Bk=;
 b=ZHDH7p6//jV4zZAz7g1u6LCwqUGnaKuS7ve3ru1Woi3B+iOxk2F+qYK5VzX+L5omsj/hoedJE
 b23/V/l0MIqBfh7IQpjvbrGDgwzAxqkKdWDEm+p1tWHmdSZJdGWdNPT
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
Changes in v2:
- undo saw2 compatible rename
- update dts schema
- formatting
- Link to v1: https://lore.kernel.org/r/20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com

---
Rudraksha Gupta (3):
      dt-bindings: opp: Allow optional -vN suffix in opp-microvolt property name
      soc: qcom: spm: Add MSM8960 SAW2 CPU support
      ARM: dts: qcom: msm8960: Add CPU frequency scaling support

 .../devicetree/bindings/opp/opp-v2-kryo-cpu.yaml   |   2 +-
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           | 129 +++++++++++++++++++++
 drivers/soc/qcom/spm.c                             |  20 +++-
 3 files changed, 149 insertions(+), 2 deletions(-)
---
base-commit: 3131ff5a117498bb4b9db3a238bb311cbf8383ce
change-id: 20260513-expressatt_cpufreq-66638ba8d156
prerequisite-message-id: <20260527-expressatt-touchkey-v2-1-049dca41fc3a@gmail.com>
prerequisite-patch-id: 2b24e9ba47500ef05d38e37b40d8ca2dceb4716a
prerequisite-message-id: <20260527-expressatt_camera_flash-v6-0-de0f150024e4@gmail.com>
prerequisite-patch-id: ab8b8d87fd2d518c4c5b5dace3f22238d1abbe49
prerequisite-patch-id: 466e1f74760f1a5ba7c222d01953aed6ea787390
prerequisite-patch-id: 7ef7df61e7ef6476a35811d765f522f793d9ecc7
prerequisite-message-id: <20260401-expressatt_fuel_guage-v3-0-9674cfc0b5a2@gmail.com>
prerequisite-patch-id: 27c37aa51fe76043b4998137d106689ed5ae6c91
prerequisite-patch-id: e477ee37abf167c55659f5e591b070b176187ca7
prerequisite-patch-id: 9680b63831f2be63607bff2175639c1987af5e85
prerequisite-patch-id: ee275dc3aec6159072d0a9efb66d18468a72ad57

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

