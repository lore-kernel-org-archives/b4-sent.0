From: Igor Velkov <iav@iav.lv>
Subject: [PATCH RFC 0/3] alarmtimer: Choose the wakeup RTC per sleep state
 from the device tree
Date: Wed, 04 Nov 2026 05:54:36 +0000
Message-Id: <20261104-b4-alarmtimer-rtc-priority-v1-0-e996681b8086@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ3I6moC/x3MSwrCQAwA0KuUrA00cWyxW6EHcCsuxmnaBvojM
 4hSencHl2/zdohiKhGaYgeTt0Zdlww6FRBGvwyC2mUDl1wRlQ5fDv3kbU46i6GlgJvpapq+yMI
 XOpPnK9WQg82k188/f8C9vcHzOH4P0Y9gcQAAAA==
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4284; i=iav@iav.lv;
 h=from:subject:message-id; bh=0IYwb1SInrt3b80xHHEOcsUK/4uBWyP8cJUA4xS+Tyw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmvTswTXs/q8/O4/BzBn62T5ojfu5TIqLR8j/mNjgvVB
 3iaZ5Sxd5SyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJ5FoxMlzdxL/urq5/yVIF
 OQEZ9kwdBc9Ufb4Tx/9Y+k/JunPsTSQjQ5tPQuWGiZ7ze80Tuu7nVl/167vQfeIwa0bkj0A3ZeF
 wVgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

alarmtimer binds to the first registered RTC that has an alarm and a
wakeup-capable parent and programs it on every suspend. On ODROID-HC4
that RTC is amlogic,meson-vrtc: a register the SoC firmware reads when
the application processors suspend. It wakes the board from deep sleep
only, and only when the firmware handles the alarm; it raises no
interrupt in Linux, so it never wakes the board from s2idle. The board's
pcf8563, whose interrupt line goes to a GPIO, registers later and is
never used.

Which RTC wakes the system depends on the sleep state and on the board's
firmware, so the series lets the board device tree say it per RTC:

- linux,wakeup-states: the sleep states an alarm of this RTC wakes the
  system from ("s2idle", "shallow", "deep" as in /sys/power/mem_sleep,
  plus "hibernate" and "off"), or "none".
- linux,alarmtimer-priority: a weight to pick among several RTCs that
  wake the system from the same state.

alarmtimer keeps each RTC that has an alarm and a wakeup-capable parent,
unless an RTC registered before it, with at least the same priority,
already wakes from every state it lists; each kept RTC gets its own
"alarmtimer" platform device under the RTC. alarmtimer_suspend() picks,
by pm_suspend_target_state, the RTC with the highest priority among
those listing that state, the first registered among equals, and
programs the alarm from that RTC's platform device only. The driver core
suspends a device before its ancestors (dpm_suspend() takes
dpm_prepared_list from the tail, in reverse registration order), so the
chosen RTC and its parent, which drives the hardware, are still awake
when the alarm is programmed.
Without the properties only the first RTC gets a platform device and
alarmtimer programs it on every suspend.

An RTC without linux,wakeup-states is taken to wake the system from
every state, so that adding the property to one RTC, e.g. from an
overlay, does not change how the others are used; a priority on the new
one settles which wins.

Hibernation wakeups (.freeze/.poweroff callbacks) are not part of this
series.

Patch 3 sets linux,wakeup-states on ODROID-HC4: "s2idle" for the
pcf8563 and "deep" for meson-vrtc, so that alarmtimer programs the
pcf8563 for s2idle and meson-vrtc for deep sleep. The patch applies to
the current tree, but the s2idle wakeup also needs the pcf8563
interrupt (GPIOX_5), which a patch under review adds [1].

Tested on ODROID-HC4 with v7.3.1, [1] and a BL301 that handles the vrtc
alarm, waking by a CLOCK_BOOTTIME_ALARM timer, once per state: s2idle
woke on the pcf8563 interrupt, deep sleep on meson-vrtc with the pcf8563
alarm left unset. Without the series the alarm went to meson-vrtc and
the board did not wake from s2idle.

Questions:

- Are "linux,wakeup-states" and "linux,alarmtimer-priority" acceptable
  names, or should they be generic (no linux, prefix), given that the
  states describe the hardware and the firmware rather than Linux?
- Is the device tree the right place for a capability that depends on
  the firmware the board runs? On HC4, meson-vrtc wakes from deep sleep
  only with a BL301 that handles its alarm.

The alarm limit of meson-vrtc also depends on the firmware, and the
kernel cannot learn it. Some API is needed to pass this information to
the kernel.

[1] https://lore.kernel.org/r/20261020-hc4-rtc-alarm-irq-v1-1-b2b8c68d54f5@iav.lv

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (3):
      dt-bindings: rtc: Add linux,wakeup-states and linux,alarmtimer-priority
      alarmtimer: Choose the wakeup RTC by sleep state and priority
      arm64: dts: amlogic: meson-sm1-odroid-hc4: Describe which RTC wakes the board

 .../bindings/rtc/amlogic,meson-vrtc.yaml           |   3 +
 .../devicetree/bindings/rtc/nxp,pcf8563.yaml       |   3 +
 Documentation/devicetree/bindings/rtc/rtc.yaml     |  29 ++++
 .../boot/dts/amlogic/meson-sm1-odroid-hc4.dts      |   5 +
 kernel/time/alarmtimer.c                           | 157 ++++++++++++++++++---
 5 files changed, 180 insertions(+), 17 deletions(-)
---
base-commit: 348f54c435bf3177baa78201952810b255d44b30
change-id: 20261104-b4-alarmtimer-rtc-priority-2e25131a2917

Best regards,
-- 
Igor Velkov <iav@iav.lv>

