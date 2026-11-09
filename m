From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH 0/2] serial: 8250_dw: Fix RX trigger levels for 64-byte
 FIFOs
Date: Mon, 09 Nov 2026 15:40:58 +0100
Message-Id: <20261109-8250-select-u6-64bit-v1-0-04bc8332fa34@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHrb8WoC/yXMTQqDQAxA4atI1g1kRp2pvYp04U/USNEy0SKId
 3esy2/x3g7KQVjhlewQ+Ccq8xRhHgk0QzX1jNJGgyXrDKWET5sTKn+4WXB16LJaFvTeeDZVUZB
 NIabfwJ1s/235vq1rPcbmesFxnGmESPp4AAAA
X-Change-ID: 20261030-8250-select-u6-64bit-7717e1a99023
To: Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>, 
 Miroslav Ondra <ondra@faster.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794235482; l=4142;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=j7wsNWKLOu8PU6y8Iijjhk75JExmK+N8BPwkouuO6/4=;
 b=j33Bj/JLEw5tU/jtXgoDEE6XPG5xL5NLdO5eBUw/pzIKsWldf4BLZxfpNUT2XARmmBnE29HHP
 iwu6BkgbdpjAHPQHQs8PwHl9YcEADD/JNz4ILRDb4PAW+fpU5fqG1d4
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DesignWare UARTs that report their FIFO through the CPR register are
always registered as PORT_16550A. For a 64-byte FIFO, as found on the
Rockchip RK3328, the rx_trig_bytes sysfs attribute therefore uses the
16-byte table: it reports 8 bytes while the hardware triggers at 32,
and writing it programs a different level than requested.

Generic autoconfig already classifies a 16550A with a 64-byte FIFO as
PORT_U6_16550A. DesignWare ports without a usable CPR are probed this
way, so the same 64-byte core is registered as U6_16550A or as 16550A
depending on whether its CPR can be read. This series makes the CPR
path pick U6_16550A as well, after first giving PORT_U6_16550A an
rxtrig_bytes table that matches the DesignWare FCR RT encoding.

Patch 1 adds the table to the core. It has to come first: without it,
patch 2 would make the rx_trig_bytes attribute disappear on the
affected ports.

Patch 2 switches 8250_dw to the new type for 64-byte FIFOs.

Things worth reviewing:

- The register programming does not change. FIFO size, TX load size and
  capabilities still come from CPR, and both types use the same default
  FCR value.

- The port type visible to userspace changes from 16550A (4) to
  U6_16550A (19) for these ports, in TIOCGSERIAL, /proc/tty/driver/serial
  and the boot log.

- dw8250_setup_port() is also used by 8250_lpss, so Intel LPSS UARTs with
  a 64-byte FIFO are affected the same way. I could not test on LPSS
  hardware.

- Ports detected as U6_16550A by autoconfig gain the rx_trig_bytes
  attribute. Its highest level, FIFO size - 2, follows the DesignWare
  encoding and may not match non-DesignWare hardware detected this way.

- Only 64-byte FIFOs are handled. DesignWare FIFOs of other depths keep
  using the 16-byte table. Deriving the levels from the FIFO size would
  cover them as well, but needs a new hook in the core. I am happy to go
  that way instead if it is preferred.

Testing:

Tested on a Unipi G110 controller with a Rockchip RK3328, on ttyS1 and
ttyS2, with next-20261029 and with 6.12.114-cip34, each without and
with this series. Both ports have a 64-byte FIFO, and both kernels and
both ports gave identical results.

With the UART in internal loopback at 9600 baud, each value was written
to rx_trig_bytes and 640 bytes were sent. The largest chunk delivered
to userspace shows the trigger level the hardware actually used:

                 without series         with series
  written        reads   hw level       reads   hw level
  1              1       1              1       1
  4              4       16             1       1
  8              8       32             1       1
  16             14      62             16      16
  32             14      62             32      32
  62             14      62             62      62

Without the series the ports register as 16550A and rx_trig_bytes
reports 8 by default, while the default FCR value is the one written
for 8 above, i.e. 32 bytes. With the series they register as
U6_16550A and report 32. Values in between round down to the nearest
level, for example 31 reads back as 16, 40 as 32 and 255 as 62. At
level 62 the TX-empty interrupt also drains the RX FIFO, so 2-byte
chunks appear between the 62-byte ones.

The series was also build-tested with W=1 for arm64 defconfig and for
an x86_64 config with 8250_lpss, at each patch. It was not tested on
Intel LPSS hardware.

The commit messages and this cover letter were drafted with help
from an AI assistant. The changes are used in downstream Unipi kernel.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
Kryštof Černý (2):
      serial: 8250: Add RX trigger levels for U6_16550A
      serial: 8250_dw: Select U6_16550A for 64-byte FIFO

 drivers/tty/serial/8250/8250_dwlib.c | 2 +-
 drivers/tty/serial/8250/8250_port.c  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
---
base-commit: a39c950806213f6861d00f90729acaaa21f2d95a
change-id: 20261030-8250-select-u6-64bit-7717e1a99023

Best regards,
--  
Kryštof Černý <cleverline1mc@gmail.com>

