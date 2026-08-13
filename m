From: Robin Snyders <robin@snyders.xyz>
Subject: [PATCH v3 0/2] power: supply: qcom_smbx: add SMB5 support
Date: Thu, 13 Aug 2026 12:45:40 +0200
Message-Id: <20260813-submit-qcom-smbx-send-v1-v3-0-27be0091d7c7@snyders.xyz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42QS24bMRBEr2LMOmOQ7OYvq9wjyKLZH2sWkuyhL
 EgxfPdwZMCIsjACcFME6nVVvU1d10X79P3hbVr1vPTleBgCvj1MvKPDk86LDD0FF5Ir3s/9te2
 X0/zCx/3c9+0ydz3IfPZzqsRqlHzNeRr251VtudzQP38NvVv66bheb5fOfvv9D+h4bjZVTmzkA
 9CPfriKrv3xcv09bdhz+BsVvkCFDRUdtmK1Gck96v0j8qovr2OE00fu6ZlOvBsTjEWkUGVDaFG
 jEiek5Ggki1q5ulJcY8s13Kp/ukRBoWFFqwkx1q0GMhlDCkyuYQmlMMZ/XFFDIGeaWWKEjJacZ
 A7cPKqA2GiA6tq9qyoNuEcXtGZJBBoh1aaMSQy1SgMJZOneFROUVp1n8S5nMKpYYnLRCrYQyYu
 UkKjg5mrUdR7DjoHHudqgsBAYMpZRrDE6Ay4q6rODOCJW8zCmff8Dk5i6fWcCAAA=
X-Change-ID: 20260811-submit-qcom-smbx-send-v1-69acefa61977
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786617973; l=5892;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=bZJrmEZb6liar96FiaNWKIqjcCpMMnt2beImueyvzt8=;
 b=XJ8GrM1rlpOQL/IS6GUvw13On72SUeLdqRBylwQ8dKEVO85KtAAWC59iSZP7ZspgpQ8tlAI2w
 PH6JE6v+ugACxyYQL79mgFy5TXFkgWsWc3QW8mX8FFHdyXhMFUizGLs
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the SMB5 charger generation found in PM7250B and
PM8150B to the existing qcom_smbx driver.

The series extends the binding and selects register layouts, charger
status encodings and electrical limits from per-PMIC match data. Encode
PM7250B as PM8150B-compatible in the binding and let the compatible
fallback select the shared charge-parameter block, including the +0x08
effective input-current status register. Convert the SMB5 0.2 V/A USB
current-sense voltage measurement to microamps while leaving the SMB2
current reading unchanged.

SMB5 setup suspends USB input and disables charging before configuration.
The power-supply registration init callback programs battery limits and
completes final input and charging setup before device_add publishes the
properties, so public callbacks cannot observe partially initialized
hardware. Managed rollback restores the charging state before the USB input
state; if charging cannot be restored, USB input remains suspended. Managed
teardown cancels status work before unregistering the power supply.

Enable periodic hardware AICL with the downstream twelve-second rerun
interval while leaving ADC-based AICL disabled by default. Clear the
unsupported HVDCP modes so firmware state cannot raise VBUS, and do not
override the firmware recharge policy without a binding input. The
dedicated TCPM and VBUS regulator drivers retain ownership of Type-C
power-role and VBUS control.

Apply the five-patch qcom_smbx Fixes series before this one. This series is
based on power-supply for-next (99b38cda3f4c). The b4 dependency metadata
records all five prerequisite patch IDs. This ordering preserves the SMB2
watchdog, health, overvoltage and float-voltage fixes across the SMB5
driver refactoring. The prerequisite series is public at:
https://lore.kernel.org/r/20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz/

The v3 implementation was tested on a OnePlus 7T Pro (HD1913) with
PM8150B. Register reads confirmed 4.40 V, 1.50 A and 500 mA limits. A
180-second guarded charging trace and a subsequent 600-second runtime
trace completed with health Good and the input current below its 500 mA
limit. After a physical USB-C disconnect and reconnect, USB networking and
the charger recovered automatically; a further 60-second trace remained
Good and below the input-current limit. The final kernel log had no SMB5
warning, error, oops or lockdep report.

The driver builds with LLVM W=1 and passes Sparse. The binding passes
dt_binding_check, and both patches pass checkpatch --strict. A full LLVM
Image, modules and DTBs integration build completed and booted on the test
device.

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
Changes in v3:
- Complete SMB5 input and charging setup in the pre-device_add power-supply
  registration init callback instead of gating setters on a driver-specific
  probe flag.
- Register the power supply and initialize managed status work before
  requesting IRQs so handlers cannot observe an unassigned power supply.
- Let PM7250B match the required PM8150B compatible fallback and remove its
  duplicate match-data entry.
- Collect the binding Reviewed-by tag.
- Link to v2: https://lore.kernel.org/r/20260812-submit-qcom-smbx-send-v1-v2-0-f504b8f9bfad@snyders.xyz

Changes in v2:
- Rebase onto power-supply for-next 99b38cda3f4c.
- Encode PM7250B with the required PM8150B compatible fallback.
- Leave SMB5 Type-C power-role and VBUS control to the TCPM and regulator
  drivers.
- Preserve the SMB2 3-second AICL interval and use the SMB5 downstream
  12-second interval; leave ADC-based AICL disabled by default.
- Disable unsupported HVDCP negotiation deterministically.
- Do not override the firmware recharge policy without a binding input.
- Model PM7250B with PM8150B electrical limits and the +0x08 AICL ICL
  status register.
- Convert the SMB5 0.2 V/A USB current-sense reading to microamps while
  leaving the SMB2 current reading unscaled.
- Program battery limits in the pre-device_add registration init callback
  and gate setters until probe completes.
- Order managed teardown so status work is cancelled before the power
  supply is unregistered.
- Restore charging before USB input on probe failure, and leave input
  suspended if charging restoration fails.
- Correct the SMB5 overvoltage register and charger-state decoding.
- Avoid repeated error logs when polling a persistent overvoltage state.
- Use battery-info property presence when selecting charge targets.
- Remove duplicate scaling from the already-prescaled USB voltage reading
  and clarify the binding IIO channel descriptions.
- Update the binding title, Kconfig prompt and module description for both
  charger generations.
- Move the five pre-existing SMB2 fixes to a prerequisite Fixes series.
- Link to v1: https://lore.kernel.org/r/20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz

---
Casey Connolly (2):
      dt-bindings: power: supply: qcom,pmi8998-charger: add SMB5 PMICs
      power: supply: qcom_smbx: add SMB5 support

 .../power/supply/qcom,pmi8998-charger.yaml         |  17 +-
 drivers/power/supply/Kconfig                       |   8 +-
 drivers/power/supply/qcom_smbx.c                   | 744 ++++++++++++++++-----
 3 files changed, 601 insertions(+), 168 deletions(-)
---
base-commit: 99b38cda3f4c486cfbc40f3c8ede1703594e9f13
change-id: 20260811-submit-qcom-smbx-send-v1-69acefa61977
prerequisite-patch-id: 3d8a9cf43b5e5eac64a60aeec5e9c90880bcf792
prerequisite-patch-id: de3e3b494f9644596cfa4cafc362ca0b48288c45
prerequisite-patch-id: d5e22a0fe7cd55374f60d7c2cb14ed3df8f94e0b
prerequisite-patch-id: 9eafa41402e97d6a3e5369bec46df4e9db3d2af6
prerequisite-patch-id: 5638b901cd10773fa9485605f84b25a1dd826a84

Best regards,
-- 
Robin Snyders <robin@snyders.xyz>

