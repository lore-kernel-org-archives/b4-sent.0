From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v2 0/3] Reorganize DTS and add fuel-gauge to
 samsung-expressatt
Date: Wed, 01 Apr 2026 01:28:47 -0700
Message-Id: <20260401-expressatt_fuel_guage-v2-0-947922834df1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WS6WocMRCEX2WY35GRWq1rCcHvkZhFR/fO4B2vP
 Rc2Zt/d2llM4gOCfpWo+tRU67WdaOxpanfNazvS2k/96aEK+NG0uYsPBxJ9qboFCVZqrQQ9P44
 0TXGe97zQcX9YYjWhNYWTZu9iamu2erh/3ri/7656pKel4ufrZfsY59xV+O7PArLCuRRJHA2Va
 BQkREjeV6iXzmFR0UntCrsN/h5tFBQIlr3OOalUJ/BF2uiA0NnERkUyjGTzx1QMTsbMIL1UqBm
 rTQZtSoFsXEpOsUmstf+Quo7JBQwTG2+kzoZMZodALiQFGNBnxzYFX8I3UetrgdF6maoVlDMBK
 yuDD2QVZ0R94eVyiQ6Xhrfud83PWn1tRJp/qhfzacndPb2IVYl6EDEFcDmwvj0MsT/e5NPw6zv
 SlyXmONAY93yMUydWFFKwohAYHRr1mZbiRKKKoZ93zWpvVGgv2+36aT6NL9snWtW23v/8l21s0
 EUVb8AmG/4+1N6dz+c3SoA/0ZgCAAA=
X-Change-ID: 20260331-expressatt_fuel_guage-465dfb3f87ab
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775032128; l=2193;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ijyWGc7cgC5C8+2EsFh8eAzQCX0rxyLF1iEbqDPqQQo=;
 b=MmgwvXuLziahm10UT8nqenr/+BUb7r8SSOxtPl16o+nfZOWv8d7ZJ2FHHUV5zKZeAnhDtnlwG
 UsQEACoEga3C90WXtCwQoAqnRhloxGewGyMajyXy0ijRXz5bBPNFOM4
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorganized the samsung-expressatt DTS to be more in line with mainline
standards.

Tested battery by doing `cat /sys/class/power_supply/battery/capacity`
in upstream Linux and comparing the value with downstream Linux. Booted
on upstream Linux first, as the upstream Linux seems to use a lot
more battery than downstream, and then put the battery into another
expressatt running downstream Android to compare values. There are
some slight differences, but overall seems to line up pretty well with
downstream.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v2:
- Previous changes were based on some outdated dependencies. Update them
- Reorganized expressatt DTS
- Switch to GSBI5
- Link to v1: https://lore.kernel.org/r/20260331-expressatt_fuel_guage-v1-1-23d1d8526b69@gmail.com

---
Rudraksha Gupta (3):
      ARM: dts: qcom: msm8960: expressatt: Sort node references and includes
      ARM: dts: qcom: msm8960: Add GSBI5 I2C controller
      ARM: dts: qcom: msm8960: expressatt: Add MAX17048 fuel gauge

 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 420 +++++++++++----------
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           |  35 ++
 2 files changed, 257 insertions(+), 198 deletions(-)
---
base-commit: e9ec05addd1a067fc7cb218f20ecdc1b1b0898c0
change-id: 20260331-expressatt_fuel_guage-465dfb3f87ab
prerequisite-patch-id: 6fdd0efa5eda512b442b885df80774d1a7037df7
prerequisite-patch-id: 12d296f83ccb1bdfb8d06a72e476bf51ae5f4e6c
prerequisite-patch-id: a970acf2080143f41ae0935dd2c57bb71f5bf338
prerequisite-patch-id: fd25fef58503c5e5cf742e79b124948c7f6b98d9
prerequisite-patch-id: 68603a680b24921759425fc289e61fc4435e5ccd
prerequisite-message-id: <20251205-expressatt-touchkey-v1-1-1444b927c9f3@gmail.com>
prerequisite-patch-id: 8de4de7909722ccaf385c4224f25a623eaa72c28
prerequisite-message-id: <20260331-expressatt_camera_flash-v4-0-f1e99f474513@gmail.com>
prerequisite-patch-id: ab8b8d87fd2d518c4c5b5dace3f22238d1abbe49
prerequisite-patch-id: 47e32e653e520a27770bb05d99135694b0128ba0
prerequisite-patch-id: 7ef7df61e7ef6476a35811d765f522f793d9ecc7

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

