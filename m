From: Christian DREHER <christian.dreher@nanoxplore.com>
Subject: [PATCH 0/4] net: macb: support for instances with less features
Date: Tue, 28 Apr 2026 20:04:04 +0200
Message-Id: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJX28GkC/yXNQQoCMQyF4asMWRuoRWbEq4iLtpNqRNshSUUY5
 u5WXX6L9/4VlIRJ4TSsIPRi5Vo69rsB0i2UKyHP3eCdH93BH7GQ4TOkiNqWpYphroKZgjUhfLD
 1QVELJZFijm5yU4xh9iP0x0Uo8/tXO1/+1hbvlOybgG37AL3UBwmPAAAA
X-Change-ID: 20260428-net-macb-support-for-feature-lite-instances-fb0707bbad26
To: u-boot@lists.denx.de
Cc: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Christian DREHER <christian.dreher@nanoxplore.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399485; l=1844;
 i=christian.dreher@nanoxplore.com; s=20260428; h=from:subject:message-id;
 bh=kM8wEbUbzNCx6ta+YFar0b1xB7KC0IbGPQ6eZ7DKkpc=;
 b=OzfefxG4/r3rjF54HopPKQrV/2b1GgLUuoiJE56xPkknBqmY5Yn8jdUxmazRwTSdEP+X2xfon
 H7MYbKgPLzoAr0OuFwb0thujVXZmu4DmYii6P0GrOrwSFg3HpSUSnqJ
X-Developer-Key: i=christian.dreher@nanoxplore.com; a=ed25519;
 pk=id7EcKmXLV2xNgNiCIcsPjkoMQHM/qxTYqEqMhidSAU=
X-Endpoint-Received: by B4 Relay for christian.dreher@nanoxplore.com/20260428 with auth_id=760
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

I am updating the macb driver to use it on a new SoC with a Cadence
GEM (IP7014). The GEM is instantiated with a different setup than the
ones in the Atmel family, and this patchset allows the driver to run
on this other configuration, with no significant change of behavior
on already supported platforms. (The support of the SoC itself will
not reach the mailing-list before months).

This patchset was tested on emulator, with a RGMII fixed-link, by
pinging a remote host (an actual computer, connected to the emulator
and running Linux). The test produced an ARP request/answer followed
by a successful ICMP request/answer, using the legacy IP stack in
u-boot.

The patchset was developed and tested on top of U-boot v2026.1

It was not tested for non-regression on previous hardware, since I do
not own any.

This patchset
* Remove a build issue when the mach does not have its own clk.h
* Uses MAC filter 1 instead of 3, for GEMs without 3 filters
* Does not set the user_io register on GEMs that do not have one
* Add fixed-link for Gigabit (added for test purpose, may be dropped)

Thanks,
Christian

Signed-off-by: Christian DREHER <christian.dreher@nanoxplore.com>
---
Christian DREHER (4):
      net: macb: include arch/clk.h only when necessary
      net: macb: use SA1 for MAC filtering on GEM
      net: macb: do not set user_io when it does not exist
      net: macb: add gigabit implementation for fixed-link

 drivers/net/macb.c | 94 ++++++++++++++++++++++++++++++++++++++++--------------
 drivers/net/macb.h |  2 ++
 2 files changed, 72 insertions(+), 24 deletions(-)
---
base-commit: 4433253ecf2041f9362a763bb6cb79960921ac7e
change-id: 20260428-net-macb-support-for-feature-lite-instances-fb0707bbad26

Best regards,
--  
Christian DREHER <christian.dreher@nanoxplore.com>

