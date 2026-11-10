From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/3] usb: typec: Find a Type-C partner after a warm reboot
 on the Orange Pi 5
Date: Tue, 10 Nov 2026 10:39:03 +0000
Message-Id: <20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDuQmCroVaSL/Iw6Qo0kowji3
 Zu2y2/x3gWZElOGvrog0cGZ41qgHxX42a4TIYdiqFXdaq0Vit/eaEWsnzGRi1EwdCY0o2mfyjg
 o4ZZo5PM3HV5/590t5OV7gvv+AGKCFY12AAAA
X-Change-ID: 20261110-tcpm-attach-reboot-d93d5f36403b
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794307143; l=3436;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=iGPQ954ODCaz+2pIX0GxmrENRgHVatfGiGCahDtE+GM=;
 b=nGR6DIkFNsf6kRM8uWdYzOdsBCNyoOpAc44KAMwDdS41o8nk4dhn65CoIsEK9OkpUeJHJW0my
 tqQhYt+fWPjB1vnMrS5oq7kcyeSyQOvqVT5cjhkpuc4tdukMhi/hDo6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a warm reboot, an Orange Pi 5 (RK3588S, FUSB302) often did not
see a Genesys Logic based USB-C to DisplayPort cable that stayed
plugged in: tcpm toggled in SRC_UNATTACHED, the FUSB302 raised no
interrupt at all, and only a replug at the board brought DisplayPort
back. Three changes fix it:

  1. tcpm: tcpm_init() sets two states back to back with the port lock
     held, so the state machine work is queued twice, and the second
     run applies the PORT_RESET -> PORT_RESET_WAIT_OFF transition at
     once: tErrorRecovery (100 ms) took 6 us. A pending delay is now
     re-armed for the time left. This is generic, with Fixes: and
     Cc: stable.
  2. fusb302: toggle with the default Rp current. The FUSB302 found
     the cable within seconds when it toggled with the default current
     (after another device was detached), never while it toggled with
     Rp 3.0A. tcpm still sets the configured Rp level through set_cc()
     once the port is attached.
  3. arm64: dts: rockchip: the Orange Pi 5/5B Type-C port is
     self-powered (its VBUS comes from vcc5v0_sys, the board runs from
     a separate power input), so tcpm opens CC during error recovery
     and the partner sees a real detach at boot. This one is for the
     Rockchip tree; it does not depend on 1 and 2 to build, but without
     patch 1 the open-CC period at boot is cut short. It is based on
     usb-next; on top of my pending "arm64: dts: rockchip: Add USB-C DP
     AltMode for Orange Pi 5/5B", which adds a node next to the same
     line, it needs git am -3 (no conflict). I can resend it rebased.

Testing, on an Orange Pi 5 with 7.3-based kernels: before, after a
warm reboot the cable was not detected (0 FUSB302 interrupts since
boot) until it was replugged at the board. With the three patches it
was detected on 4/4 boots, the first one starting from that stuck
state, with DP connected 1-2 s after boot; the three were tested
together, not one at a time. The patches have been in every kernel I
have run since; in a later run of 30 reboots with a USB-C DisplayPort
monitor, the partner was attached on 30/30 boots, and the tcpm log of
every boot shows CC opened in PORT_RESET and 100-112 ms spent there
before PORT_RESET_WAIT_OFF. Not tested: other TCPCs (patch 1 is
generic, patch 2 only changes fusb302), and the Orange Pi 5B (same
dtsi). W=1 arm64 builds of drivers/usb/typec at every patch,
CHECK_DTBS for the Orange Pi 5 and 5B and checkpatch --strict are
clean.

This series was developed with Claude (Anthropic) as a coding
assistant: it wrote the code and the commit messages, and I reviewed
and tested every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Arun Iyengar (3):
      usb: typec: tcpm: Don't cut a pending state delay short on a re-queue
      usb: typec: fusb302: Toggle with the default Rp current
      arm64: dts: rockchip: Mark the Orange Pi 5/5B Type-C port self-powered

 arch/arm64/boot/dts/rockchip/rk3588s-orangepi-5-5b.dtsi |  1 +
 drivers/usb/typec/tcpm/fusb302.c                        | 13 +++++++++++--
 drivers/usb/typec/tcpm/tcpm.c                           | 12 ++++++++++++
 3 files changed, 24 insertions(+), 2 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-tcpm-attach-reboot-d93d5f36403b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

