From: Robin Snyders <robin@snyders.xyz>
Subject: [PATCH v4 0/2] power: supply: qcom_smbx: add SMB5 support
Date: Thu, 20 Aug 2026 12:03:48 +0200
Message-Id: <20260820-submit-qcom-smbx-send-v1-v4-0-818dabb2771e@snyders.xyz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42Qy24bMQxFf8WYdSeQROrBrPofRRcURdazsJ2MH
 MNukH+P7ABF3AJBAW0o4B7yntep67ponx43r9Oqp6Uvh/0Y8Ntmki3vf+m8tDFPwYXkivdzf6m
 75Tg/y2E39109z133bT75ORGLGidPOU8j/rSqLecb+sfPMW+Xfjysl9umk7/+/gd0PDebqiQx9
 gH4e99fmq794Xz5PV2xp/AZFb5AhSsqOqzFqBq3f1HwGQVfoGCgQq7qHPmWJd+j3j7ar/r8Mnw
 ePxRMT3yU7bD5uIFWmMQQatSoLAk5OR4lo5KQK8VVsUzhZvFPqikoVCQ0SoiRrkZQ2ARSEHYVS
 yhFMP6VihoCO9MsLUbIaMmNi4NUj9qg2ZCB6up9ipQH3KMLSrklBo2QqKpgaoZKrUILbOk+FRO
 USs5L8y5nMCYsMbloBWuI7FsrIXHBa6py13mIHYLHOqpQpDEYCpZRrAo6Ayna1GcHcZxI5mGof
 XsHsf3GWbICAAA=
X-Change-ID: 20260811-submit-qcom-smbx-send-v1-69acefa61977
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787220228; l=7898;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=GgT+UWaean8wq72FuURXdZSwG6OugUjz5R7U1uI6mcw=;
 b=EuCPMaBaqO8YZOCdiFEBZvJNwG4OHwo9My6s7C8qKcCio6BPCtGVnJzpzOFoPCU9PDk9LvqJA
 cOJkOmK8zRZB6lgfnDOJGs43I956008c0oly7BvwQR4HK9vhZODeO/q
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

On PM8150B, the SMB5 charger and VBUS regulator use the same DCDC
peripheral but do not write the same registers. qcom_smbx only reads
0x1108 and 0x110b there; qcom_usb_vbus-regulator writes 0x1140, 0x1152
and 0x1153. The qcom_smbx write to 0x1153 belongs only to the SMB2
initialization sequence and is not executed for SMB5. The TCPM port and PD
PHY use the separate 0x15xx and 0x17xx peripherals. Patch 2 names the
USBIN BC1.2 integration register and SMB2-only OTG definitions explicitly
to document this boundary.

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

The v4 driver was rebuilt and retested on the same device. A 180-second
trace and a 600-second, 121-sample guarded trace completed with the charger
online, health Good and no guard failure. With a powered USB-C dock, the
phone remained the data host and PD power sink; with the dock unpowered, it
remained the data host and enabled the VBUS regulator as the power source.
The USB 2 and USB 3 hubs, storage and RTL8153 interface enumerated in both
connector orientations, and 64 MiB read-only storage reads produced the
same hash in all four dock configurations. Reconnecting the phone directly
to the PC restored the power-sink/device roles, charging, NCM and SSH
without a reboot. Ethernet traffic and visual DisplayPort output were not
tested in this run because no Ethernet carrier or display was available.
The final kernel log had no SMB5, Type-C or VBUS warning, error, oops or
lockdep report.

The driver builds with LLVM W=1 and passes Sparse. The binding passes
dt_binding_check, and both patches pass checkpatch --strict. A full LLVM
Image, modules and DTBs integration build completed and booted on the test
device.

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
Changes in v4:
- Make the PM8150B charger, VBUS regulator and TCPM register ownership
  explicit, including the shared DCDC peripheral's disjoint accesses.
- Rename the USBIN BC1.2 integration register and SMB2-only OTG definitions
  to prevent them from being mistaken for SMB5 TCPM/VBUS controls.
- Test powered sink/host and unpowered source/host USB-C dock operation in
  both connector orientations, including storage I/O and gadget recovery.
- Link to v3: https://lore.kernel.org/r/20260813-submit-qcom-smbx-send-v1-v3-0-27be0091d7c7@snyders.xyz

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
 drivers/power/supply/qcom_smbx.c                   | 757 ++++++++++++++++-----
 3 files changed, 609 insertions(+), 173 deletions(-)
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

