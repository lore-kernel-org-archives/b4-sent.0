From: Christoph Winklhofer <cj.winklhofer@gmail.com>
Subject: [PATCH v7 0/3] w1: add UART w1 bus driver
Date: Wed, 14 Feb 2024 07:36:12 +0100
Message-Id: <20240214-w1-uart-v7-0-6e21fa24e066@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF1fzGUC/13OTW6DMBCG4atEXtdo/G+66j2qLIwZB7cBV4aQV
 hF3r4mUQrPwYiQ/n94bGTFHHMnr4UYyznGMaSiHeTkQ37nhhDS25SYcuAQGkl4Zvbg8UUSrrXJ
 MOQWk/P7KGOL3fen9WO6QU0+nLqN7eMF4eQASbCUlKE0Z9R/VNQ6f5y4FzG+n3sVz5VO/DnZxn
 FL+uZfNYp19RKi/iFlQoKXDQC0ajkbvJtaIWe6d3pwszgRkwlhnG4HPTu0c3zlVHGstb0LrucP
 62enNcag3p4sTaJTwTNas/te5LMsvFCMkVIcBAAA=
To: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Rob Herring <robh+dt@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Christoph Winklhofer <cj.winklhofer@gmail.com>, 
 Rob Herring <robh@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-doc@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707892581; l=5348;
 i=cj.winklhofer@gmail.com; s=20240104; h=from:subject:message-id;
 bh=WpkvpKeOfNBGl3s6SIPd42Jru7SBxmJQ0eeopGKSBh0=;
 b=/uU0jMlHsz8KXluEL7g+eEFniKD6PeJMvlDOYz0JZZVc1Om2voISol0iky4T3FOmNFvn6HalV
 VQFyi3MZIGDANmui+wyhL1sWAAH685itWvlVFU3U2fMWRLS6hN9Unh8
X-Developer-Key: i=cj.winklhofer@gmail.com; a=ed25519;
 pk=lgjGjOt7hFKJT9UXhgUyrdthxvZ7DJ5F1U/7d9qdAsk=
X-Endpoint-Received: by B4 Relay for cj.winklhofer@gmail.com/20240104 with auth_id=111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello!

This patch contains a driver for a 1-Wire bus over UART. The driver
utilizes the UART interface via the Serial Device Bus to create the
1-Wire timing patterns.

Changes in v7:
- rename mutex to rx_mutex and comment its usage
- fix comments and use kerneldoc for internal structs
- Link to v6: https://lore.kernel.org/r/20240209-w1-uart-v6-0-3e753c149196@gmail.com
Thanks Krzysztof for the review.

Changes in v6:
- change order of patches for dt-binding
- remove unnecessary lock in remove
- delay for 1-Wire cycle without mutex lock 
- fix comment style and add some more comments
- Link to v5: https://lore.kernel.org/r/20240126-w1-uart-v5-0-1d82bfdc2ae9@gmail.com
Thanks Krzysztof and Rob for the review.

Changes in v5:
- dt-binding: allow child object for onewire and use prefix -bps for
  baud rate configuration.
- use type u8 for a byte, instead of unsigned char
- use constants (NSEC_PER_SEC, BITS_PER_BYTE)
- make delay computation from packet time more coherent
- Link to v4: https://lore.kernel.org/r/20240106-w1-uart-v4-0-7fe1378a8b3e@gmail.com
Thanks Jiri, Krzysztof and Rob for the review.

Changes in v4:
- rework baud-rate configuration: also check max bit-time, support higher
  baud-rates by adding a delay to complete 1-Wire cycle.
- dt-binding w1-uart: specify baud-rates for 1-Wire operations
- Link to v3: https://lore.kernel.org/r/20240105-w1-uart-v3-0-8687093b2e76@gmail.com

Changes in v3:
- improve baud-rate configuration: use specific limits for 1-Wire
  reset, touch-0 and touch-1 operation, compute in nanoseconds.
- remove unused header atomic.h
- use function instead of macro to compute bit-time from baud-rate
- switch to b4 util to publish patch: missing recipients
- Link to v2: https://lore.kernel.org/lkml/20231223100408.44056-1-cj.winklhofer@gmail.com

Changes in v2:
- add documentation for dt-binding
- allow onewire as serial child node
- support different baud-rates: The driver requests a baud-rate (9600
  for reset and 115200 for write/read) and tries to adapt the
  transmitted byte according to the actual baud-rate returned from
  serdev.
- fix locking problem for serdev-receive and w1-master reset/touch: The
  received byte is now protected with a mutex - instead of the atomic,
  which was used before due to the concurrent store and load.
- explicit error in serdev-receive: Receiving more than one byte results
  in an error, since the w1-uart driver is the only writer, it writes a
  single-byte and should receive a single byte.
- fix variable names, errno-returns, wrong define CONFIG_OF
- fix log flooding
- fix driver remove (error-path for rxtx-function)
- Link to v1: https://lore.kernel.org/all/20231217122004.42795-1-cj.winklhofer@gmail.com
Krzysztof, thank your very much for your feedback!

It was tested on a "Raspberry Pi 3 Model B+" with a DS18B20 and on a
"Variscite DART-6UL" with a DS18S20 temperature sensor.

Content:
- Patch 1: device tree binding 1-Wire
- Patch 2: allow onewire as serial child node
- Patch 3: driver and documentation

The patch was created against the w1 subsytem tree (branch w1-next):
  Link: https://git.kernel.org/pub/scm/linux/kernel/git/krzk/linux-w1.git/

The checkpatch.pl script reported the following error - which I am not
sure how to fix:
  WARNING: added, moved or deleted file(s), does MAINTAINERS need
  updating?

The technical details for 1-Wire over UART are in the document:
  Link: https://www.analog.com/en/technical-articles/using-a-uart-to-implement-a-1wire-bus-master.html

  In short, the UART peripheral must support full-duplex and operate in
open-drain mode. The timing patterns are generated by a specific
combination of baud-rate and transmitted byte, which corresponds to a
1-Wire read bit, write bit or reset pulse.

For instance the timing pattern for a 1-Wire reset and presence detect
uses the baud-rate 9600, i.e. 104.2 us per bit. The transmitted byte
0xf0 over UART (least significant bit first, start-bit low) sets the
reset low time for 1-Wire to 521 us. A present 1-Wire device changes the
received byte by pulling the line low, which is used by the driver to
evaluate the result of the 1-Wire operation.

Similar for a 1-Wire read bit or write bit, which uses the baud-rate
115200, i.e. 8.7 us per bit. The transmitted byte 0x00 is used for a
Write-0 operation and the byte 0xff for Read-0, Read-1 and Write-1.

Hope the driver is helpful.

Thanks,
Christoph

---
Christoph Winklhofer (3):
      dt-bindings: serial: allow onewire as child node
      dt-bindings: w1: UART 1-Wire bus
      w1: add UART w1 bus driver

 .../devicetree/bindings/serial/serial.yaml         |   2 +-
 Documentation/devicetree/bindings/w1/w1-uart.yaml  |  60 +++
 Documentation/w1/masters/index.rst                 |   1 +
 Documentation/w1/masters/w1-uart.rst               |  54 +++
 drivers/w1/masters/Kconfig                         |  10 +
 drivers/w1/masters/Makefile                        |   1 +
 drivers/w1/masters/w1-uart.c                       | 415 +++++++++++++++++++++
 7 files changed, 542 insertions(+), 1 deletion(-)
---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240104-w1-uart-ee8685a15a50

Best regards,
-- 
Christoph Winklhofer <cj.winklhofer@gmail.com>

