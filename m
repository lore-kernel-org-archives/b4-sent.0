From: Akshat Singh <automobilehacks@gmail.com>
Subject: [PATCH 0/3] irqchip/econet-en751221: Deliver odd interrupts
 without VEIC
Date: Sun, 15 Nov 2026 19:26:00 +0000
Message-Id: <20261115-en751221-intc-all-lines-v1-0-dc03a40f47f0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEgH+moC/yXMwQrCMAyA4VcZORtYIp3MVxEPbY0zo0Rppghj7
 27V43f4/xVcqorDsVuhyktd79ZAuw7yLdokqJdm4J4HIgoodgjETKi2ZIylYFETR477wIFTn8Y
 MrX5Uuer7dz6d//ZnmiUv3x1s2weaewXKewAAAA==
X-Change-ID: 20261115-en751221-intc-all-lines-2a35252b0b9c
To: Caleb James DeLisle <cjd@cjdns.fr>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Akshat Singh <automobilehacks@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794770761; l=1983;
 i=automobilehacks@gmail.com; s=20261115; h=from:subject:message-id;
 bh=37nXMvHe9COOysw+x+zYU6STNDAgT/YyB1vW+x/B7yk=;
 b=uT2JglyePJzMDk4/2T4qCA1bMjsDQ3m0H/e5/goeML6gCtolC6/TMhF00OFbOihB05ndcW7Zl
 yQcHmxFvCz/BUDUrVfPml9kFgXquydbW37lc63I8vHzQyO8bn3ojjrm
X-Developer-Key: i=automobilehacks@gmail.com; a=ed25519;
 pk=wYmYXn6wy/XN0edTCg6D7UtE9nYLei8mbfqydGGCdf4=
X-Endpoint-Received: by B4 Relay for automobilehacks@gmail.com/20261115 with auth_id=1535
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

the en751221 intc puts the number of the pending irq plus one, in binary,
on IP2-IP7. with VEIC the cpu takes that as the vector, but without it the
driver only chains IP2, so odd irqs (qdma 21, xhci 17, first pcie port 23)
only get handled when an even one runs the handler, usually the next timer
tick.

on a nokia g-140w-c the 34kc doesn't report VEIC (no veic in
/proc/cpuinfo), and ping to the box kept cycling through 1-11ms. chaining
the handler to IP2-IP6 brings it under 1ms. VEIC mode is untouched.

tested on the g-140w-c with openwrt's 6.18 kernel, where the non-VEIC path
is the same as in mainline. on 7.4-rc2 it's build tested (W=1, no new
warnings), and dt_binding_check, CHECK_DTBS and checkpatch --strict are
clean. Caleb offered to test it on his boards:
https://github.com/openwrt/openwrt/pull/26744

Caleb: arch/mips/econet/init.c says the en751221 is a 34kc with VEIC, but
this one doesn't report it. is that something the bootloader or a soc
register turns on? if VEIC can be enabled here that's probably the better
fix for this board, but the non-VEIC path should still deliver everything.

the binding patch has to go in first, the dts change fails CHECK_DTBS
without it.

Signed-off-by: Akshat Singh <automobilehacks@gmail.com>
---
Akshat Singh (3):
      dt-bindings: interrupt-controller: econet,en751221-intc: Allow up to 6 parent interrupts
      irqchip/econet-en751221: Chain the handler to all parent interrupts
      mips: dts: Connect the EcoNet EN751221 intc to IP2-IP6

 .../interrupt-controller/econet,en751221-intc.yaml |  9 ++++--
 arch/mips/boot/dts/econet/en751221.dtsi            |  7 ++++-
 drivers/irqchip/irq-econet-en751221.c              | 33 ++++++++++++++++++++--
 3 files changed, 43 insertions(+), 6 deletions(-)
---
base-commit: fa2933aac170dd19c6a7f0d7b81a8f537e40915c
change-id: 20261115-en751221-intc-all-lines-2a35252b0b9c

Best regards,
--  
Akshat Singh <automobilehacks@gmail.com>

