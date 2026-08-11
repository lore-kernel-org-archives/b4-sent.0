From: Robin Snyders <robin@snyders.xyz>
Subject: [PATCH 0/5] power: supply: qcom_smbx: fix watchdog and battery
 properties
Date: Wed, 12 Aug 2026 01:29:57 +0200
Message-Id: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LMQqAMAxA0atIZgO2iqhXEQeNUTO01QZEKN7d4
 vj4/ATKUVhhKBJEvkUl+AxTFkDH7HdGWbPBVratOmPxouBQ3fLgJg8rNmTnxbQ1UU+QrzPyH/I
 0Tu/7AamrjhxhAAAA
X-Change-ID: 20260812-qcom-smbx-fixes-4c2ab163cc9c
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786491008; l=2069;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=qv1nbnQj5yoUuqvBAtie8PCjm4uOhcMDB/ozlhiCEnI=;
 b=GxwMvT7WZEjD0iuci8XI4SkTBX064+9afDqfQqrUj0PKAY84eYnyrbGM/7ekyZ8uDD+h8h2mQ
 LL/Klww2FVoApy8bGPGhz17PqYWs3Ef0qQlsbISz+i0AVuZBLhhjNET
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix five bugs in the existing Qualcomm SMB2 charger driver.

The watchdog bark handler omits the charger peripheral base and can write
an unrelated SPMI register. Battery health handling compares the complete
status register instead of testing its independent fault bits. The
float-voltage calculation is one selector step too high, and its battery
target is neither selected nor validated safely. Finally, the
battery-overvoltage IRQ ignores read errors and only publishes assertion,
leaving health and status stale after the falling-edge recovery interrupt.

The float-voltage validation patch prefers the constant-charge target,
falls back to the design voltage, and preserves the firmware setting when
both optional properties are absent. It also restores the pre-probe
charging-enable state if hardware initialization or any later probe step
fails, preventing probe failure from changing that state.

All five issues were introduced with the driver. The patches carry the
same Fixes tag and are marked for stable.

This series is also the declared prerequisite for the SMB5 v2 series,
whose driver refactoring overlaps the health, overvoltage and
float-voltage code.

The driver builds with LLVM W=1 and passes sparse without driver
warnings. All five patches pass checkpatch --strict.

Based on linux-next 20260811 (5e6de6a2b522).

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
Robin Snyders (5):
      power: supply: qcom_smbx: include base when petting watchdog
      power: supply: qcom_smbx: test battery health status bits
      power: supply: qcom_smbx: fix float voltage selector
      power: supply: qcom_smbx: validate battery float voltage
      power: supply: qcom_smbx: notify battery overvoltage recovery

 drivers/power/supply/qcom_smbx.c | 98 ++++++++++++++++++++++++++++++++--------
 1 file changed, 78 insertions(+), 20 deletions(-)
---
base-commit: 5e6de6a2b522f659defacb1551d0465ba6ce13cf
change-id: 20260812-qcom-smbx-fixes-4c2ab163cc9c

Best regards,
-- 
Robin Snyders <robin@snyders.xyz>

