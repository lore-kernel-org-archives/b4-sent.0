From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] usb: typec: Find a Type-C partner after a warm
 reboot on the Orange Pi 5
Date: Thu, 12 Nov 2026 08:23:32 +0000
Message-Id: <20261112-tcpm-attach-reboot-v2-0-b4bc6ca83490@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7Zi2CERX3sOwKNMBxoglbSUaw
 t0F3Lt8yfvvzxA5CEe4ZDMEniSKf65gDhlQb58do7iVwShTaq0VJhoHtClZ6jFw431Cd85d0eb
 lSeUNrMMxcCvvPXqrfxxfzZ0pbaXN6CUmHz7766Q37+/BpFFhVRYVkWbjyF67wcrjSH6AelmWL
 1L3KSXGAAAA
X-Change-ID: 20261110-tcpm-attach-reboot-d93d5f36403b
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794471812; l=4299;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NXoRow5VcVQww5nLiutGQN5/V1+lopLZ2pLFYOB0EcE=;
 b=gweINCXVaFsfWvdDUDRv+bl2hLeAzzJxHEMtI/yKW9mw+LbfV9dTa53yskxM9+gkOdrCKfFO6
 fb+isu7BQsQCPxpusNeLy+ePVu5zFPONAm3bvqz2nQeVlPlxYFxMWny
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a warm reboot, an Orange Pi 5 (RK3588S, FUSB302) often did not
see a Genesys Logic based USB-C to DisplayPort cable that stayed
plugged in: tcpm toggled in SRC_UNATTACHED, the FUSB302 raised no
interrupt at all, and only a replug at the board brought DisplayPort
back. Two changes in this series and one device tree change fix it:

  1. tcpm: tcpm_init() sets two states back to back with the port lock
     held, so the state machine work is queued twice, and the second
     run applies the PORT_RESET -> PORT_RESET_WAIT_OFF transition at
     once: tErrorRecovery (100 ms) took 6 us. A pending delay is now
     re-armed for the time left. This is generic, with Fixes: and
     Cc: stable.
  2. fusb302: toggle with the default Rp current. The FUSB302 found
     the cable within seconds when it toggled with the default current
     (after another device was detached), never while it toggled with
     Rp 3.0A. Once toggling stops on a sink, the driver switches to the
     configured Rp current before it reports the attach, so the sink
     sees that level from the start, as before.

The device tree change, "arm64: dts: rockchip: Mark the Orange Pi 5/5B
Type-C port self-powered" (patch 3 of v1), now goes separately to the
Rockchip tree: the port's VBUS comes from vcc5v0_sys and the board
runs from a separate power input, so tcpm opens CC during error
recovery and the partner sees a real detach at boot. It does not
depend on this series to build, but without patch 1 the open-CC period
at boot is cut short.

Testing, on an Orange Pi 5 with 7.3-based kernels: before, after a
warm reboot the cable was not detected (0 FUSB302 interrupts since
boot) until it was replugged at the board. With the three v1 patches it
was detected on 4/4 boots, the first one starting from that stuck
state, with DP connected 1-2 s after boot; the three were tested
together, not one at a time. The patches have been in every kernel I
have run since; in a later run of 30 reboots with a USB-C DisplayPort
monitor, the partner was attached on 30/30 boots, and the tcpm log of
every boot shows CC opened in PORT_RESET and 100-112 ms spent there
before PORT_RESET_WAIT_OFF. Not tested: other TCPCs (patch 1 is
generic, patch 2 only changes fusb302), and the Orange Pi 5B (same
dtsi).

v2 was tested on the same board with a kernel carrying exactly the v2
changes: on 16/16 warm reboots the partner was attached and DP alt mode
configured, CC was open in PORT_RESET for 100 ms each time, there were
no kernel warnings, and the FUSB302 HOST_CUR field matched the Rp level
of tcpm's last set_cc() on every boot. Three role changes (dual -> sink
-> dual) with the monitor attached each re-attached the partner and DP.
This is a PD port, so the non-PD path that the v2 change to patch 2 is
about was not exercised.

W=1 arm64 builds of drivers/usb/typec at every patch,
and checkpatch --strict are clean.

This series was developed with Claude (Anthropic) as a coding
assistant: it wrote the code and the commit messages, and I reviewed
and tested every change as described above.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- Patch 2: switch to the requested Rp current when toggling stops on a
  sink, before the attach is reported; tcpm does not set it again on
  every path (ports without PD) (Sashiko). Fixes: tag added (Sashiko)
- Patch 1 unchanged. Sashiko's pre-existing tcpm_unregister_port()
  race is fixed separately:
  https://lore.kernel.org/all/20261112-tcpm-unregister-timers-v1-1-7230fda5612b@gmail.com/
- Patch 3 (Orange Pi 5/5B DTS) split out; it goes to the Rockchip
  tree on its own
- Link to v1: https://patch.msgid.link/20261110-tcpm-attach-reboot-v1-0-7657cc1e2dca@gmail.com

---
Arun Iyengar (2):
      usb: typec: tcpm: Don't cut a pending state delay short on a re-queue
      usb: typec: fusb302: Toggle with the default Rp current

 drivers/usb/typec/tcpm/fusb302.c | 21 +++++++++++++++++++--
 drivers/usb/typec/tcpm/tcpm.c    | 12 ++++++++++++
 2 files changed, 31 insertions(+), 2 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-tcpm-attach-reboot-d93d5f36403b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

