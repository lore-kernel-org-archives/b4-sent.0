From: Akshat Singh <automobilehacks@gmail.com>
Subject: [PATCH v2 0/3] irqchip/econet-en751221: Deliver odd interrupts
 without VEIC
Date: Tue, 24 Nov 2026 08:45:28 +0000
Message-Id: <20261124-en751221-intc-all-lines-v2-0-a33a520aac81@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKhOBWsC/4WNQQ6CMBBFr0Jm7Zh2oBJdeQ/DopQBxtRiWiQaw
 t0FPIDLl7z//gyJo3CCSzZD5EmSDGEFOmTgehs6RmlWBlJ00lob5FAaTaRRwujQeo9eAickmxs
 yVKv67GBdPyO38t7Lt+rH6VXf2Y1bbjN6SeMQP/v1pDfv/8ukUWHjVG4L1RZlq67dw4o/uuEB1
 bIsX0jK/8bQAAAA
X-Change-ID: 20261115-en751221-intc-all-lines-2a35252b0b9c
To: Caleb James DeLisle <cjd@cjdns.fr>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Akshat Singh <automobilehacks@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795509928; l=2345;
 i=automobilehacks@gmail.com; s=20261115; h=from:subject:message-id;
 bh=M+rHP49TLFPFRmFeMJB9FFV/lr2vwMjOoBXs6QR6Uus=;
 b=+WW5vldNx762MxjMTGWlRLjmrHU2N10z4usZuwm2ONylsPE67VyzJfLVvAeTTY9lHyP5Z9UNA
 6O5AdIky2QRBV+KY4EoV/+A5/DsdEsx7dV83Q0gXYmCBBxuWnpOjquV
X-Developer-Key: i=automobilehacks@gmail.com; a=ed25519;
 pk=wYmYXn6wy/XN0edTCg6D7UtE9nYLei8mbfqydGGCdf4=
X-Endpoint-Received: by B4 Relay for automobilehacks@gmail.com/20261115 with auth_id=1535
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

the en751221 intc puts the number of the pending irq plus one, in binary,
on IP2-IP7. with VEIC the cpu takes that as the vector, but without it the
driver only chains IP2, so odd irqs (qdma 21, xhci 17, first pcie port 23)
only get handled when an even one runs the handler, usually the next timer
tick.

a kernel without CONFIG_CPU_MIPSR2_IRQ_EI always takes the non-VEIC path.
openwrt's 6.18 kernel for this soc is built that way. on a nokia g-140w-c
running it, ping to the box kept cycling through 1-11ms. chaining the
handler to IP2-IP6 brings it under 1ms. VEIC mode is untouched.

tested on the g-140w-c with openwrt's 6.18 kernel, where the non-VEIC path
is the same as in mainline. on 7.4-rc2 it's build tested (W=1 and W=2, no
new warnings), and dt_binding_check, CHECK_DTBS and checkpatch --strict
are clean. Caleb tested v1, his Tested-by is on 2/3.

the binding patch has to go in first, the dts change fails CHECK_DTBS
without it.

Signed-off-by: Akshat Singh <automobilehacks@gmail.com>
---
Changes in v2:
- 2/3: rename the new local int parent to virq, it shadowed the parent
  argument (W=2 -Wshadow, from sashiko)
- 2/3, 3/3: add Fixes tags (sashiko)
- 2/3: add Caleb's Tested-by
- 2/3 and cover: drop my claim that the g-140w-c's 34kc doesn't report
  VEIC. it came from a kernel without CONFIG_CPU_MIPSR2_IRQ_EI, where
  cpu_has_veic is 0 at build time, so /proc/cpuinfo could never show
  veic. an SMP build shows it on a g-140w-c. please ignore my v1
  question about turning VEIC on
- Link to v1: https://patch.msgid.link/20261115-en751221-intc-all-lines-v1-0-dc03a40f47f0@gmail.com

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

